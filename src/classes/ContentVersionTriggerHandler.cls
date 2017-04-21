public class ContentVersionTriggerHandler extends TriggerHandler
{
    private Map<String, Id> supportSiteKeyMap;
    private Map<Decimal, Id> supportSiteOrderMap;
    private ID supportSiteRecordTypeId;
    private static Map<String,Schema.RecordTypeInfo> rtMapByName = null;
    private static final String supportSiteTermsRecordType = 'Support Site Link';

    public ContentVersionTriggerHandler(){
        if(rtMapByName == null){
            rtMapByName = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName();
        }
    }

    public override void beforeInsert()
    {
        //verify that SupportSiteKey__c, SupportSiteRedirectKeys__c, and SupportSiteLinkOrder__c are unique
        validateUniqueSupportSiteFields();
    }
    
    public override void beforeUpdate()
    {
        //verify that SupportSiteKey__c, SupportSiteRedirectKeys__c, and SupportSiteLinkOrder__c are unique
        validateUniqueSupportSiteFields();
    }

    protected override void afterUpdate()
    {
        system.debug('**** after update ****');
        upsertPartnerDocManager((List<ContentVersion>)Trigger.new);
    }

    // creates a partner document manager record if there isn't one already for a document and just updates latest version ID if there is one
    private void upsertPartnerDocManager(List<ContentVersion> newList){
        List<Partner_Document_Manager__c> managerList = new List<Partner_Document_Manager__c>();
        for(ContentVersion version : newList){
            system.debug('upsertPartnerDocManager(): version - '+ version);
            if(version.RecordTypeId == rtMapByName.get('Partner Document').getRecordTypeId() && version.IsLatest){
                Partner_Document_Manager__c manager = new Partner_Document_Manager__c(
                        ContentDocumentId__c = version.ContentDocumentId,
                        LatestVersionId__c = version.Id,
                        Title__c = version.Title
                );
                managerList.add(manager);
            }

        }
        system.debug('upsertPartnerDocManager(): managerList - '+ managerList);

        if(managerList.size() > 0){
            upsert managerList ContentDocumentId__c;
        }

    }

    private List<ContentVersion> getListWithSupportSiteFieldChanges()
    {
        List<ContentVersion> changedList = new List<ContentVersion>();
        
        RecordType supportSiteRecordType = [SELECT Id FROM RecordType WHERE Name = :supportSiteTermsRecordType];
        supportSiteRecordTypeId = supportSiteRecordType.Id;
        
        for(ContentVersion modified : (List<ContentVersion>)Trigger.new)
        {
            if(modified.RecordTypeId == supportSiteRecordTypeId)
            {
                //only add the record to the list of changed records if the fields that should be verified were changed
                if(Trigger.isUpdate || Trigger.isInsert)
                {
                    ContentVersion oldContent = Trigger.oldMap == NULL ? NULL : (ContentVersion)Trigger.oldMap.get(modified.Id);
                    if(oldContent == NULL 
                       || oldContent.SupportSiteKey__c != modified.SupportSiteKey__c 
                       || oldContent.SupportSiteLinkOrder__c != modified.SupportSiteLinkOrder__c
                       || oldContent.SupportSiteRedirectKeys__c != modified.SupportSiteRedirectKeys__c
                       || modified.SupportSiteKey__c == NULL
                       || modified.SupportSiteLinkOrder__c == NULL)
                    {
                        changedList.add(modified);
                    }
                }
            }
        }

        return changedList;
    }
    
    private void validateUniqueSupportSiteFieldsInChangedList(List<ContentVersion> changedList)
    {
        //if 0 or 1 record then no need to perform this check
        if(changedList.size() < 2)
        {
            return;
        }
        
        Map<String, List<Integer>> keyToContentMap = new Map<String, List<Integer>>();
        Map<Decimal, List<Integer>> orderToContentMap = new Map<Decimal, List<Integer>>();
        
        Integer index = 0;
        for(ContentVersion record1 : changedList)
        {
            //track the used link order values
            if(orderToContentMap.containsKey(record1.SupportSiteLinkOrder__c))
            {
                orderToContentMap.get(record1.SupportSiteLinkOrder__c).add(index);
            }
            else
            {
                List<Integer> indexList = new List<Integer>();
                indexList.add(index);
                orderToContentMap.put(record1.SupportSiteLinkOrder__c, indexList);
            }
            
            //track the used support site key and redirect key values
            if(keyToContentMap.containsKey(record1.SupportSiteKey__c))
            {
                keyToContentMap.get(record1.SupportSiteKey__c).add(index);
            }
            else
            {
                List<Integer> contentList = new List<Integer>();
                contentList.add(index);
                keyToContentMap.put(record1.SupportSiteKey__c, contentList);
            }
            
            if(record1.SupportSiteRedirectKeys__c != NULL)
            {
                for(String key : record1.SupportSiteRedirectKeys__c.split(';'))
                {
                    if(keyToContentMap.containsKey(key))
                    {
                        keyToContentMap.get(key).add(index);
                    }
                    else
                    {
                        List<Integer> redirectContentList = new List<Integer>();
                        redirectContentList.add(index);
                        keyToContentMap.put(key, redirectContentList);
                    }
                }
            }
            
            index++;
        }
        
        Set<Integer> badIndexes = new Set<Integer>();

        //add errors to all of the records that have duplicate keys
        for(String key : keyToContentMap.keySet())
        {
            if(keyToContentMap.get(key).size() > 1)
            {
                badIndexes.addAll(keyToContentMap.get(key));
            }
        }  
        
        for(Decimal linkOrder : orderToContentMap.keySet())
        {
            if(orderToContentMap.get(linkOrder).size() > 1)
            {
                badIndexes.addAll(orderToContentMap.get(linkOrder));
            }
        }
        
        //the index will be 1 lower for each item removed from changedList
        Integer indexOffset = 0;
        for(Integer badIndex : badIndexes)
        {
            Integer actualIndex = badIndex - indexOffset;
            ContentVersion badContent = changedList[actualIndex];
            badContent.addError('Support Site Key must be unique.  (Capitalization does NOT make the Support Site Key unique.)');
            changedList.remove(actualIndex);
            
            indexOffset++;
        }
    }
    
    private void validateUniqueSupportSiteFields()
    {
        List<ContentVersion> changedList = getListWithSupportSiteFieldChanges();
        if(changedList.size() > 0)
        {
            //remove values from changedList that are not valid
            validateUniqueSupportSiteFieldsInChangedList(changedList);
            
            prepareSupportSiteMaps();
            
            //SupportSiteKey__c and SupportSiteRedirectKeys__c should be unique unless the ContentDocumentId matches the record that this matches
            // this is an insert, so always check the support site key against existing keys
            for(ContentVersion newContent : changedList)
            {
                Boolean hasError = false;
                String lowerCaseKey = newContent.SupportSiteKey__c.toLowerCase();
                if(newContent.SupportSiteLinkOrder__c == NULL || newContent.SupportSiteKey__c == NULL 
                   || (supportSiteKeyMap.containsKey(lowerCaseKey) 
                   && newContent.ContentDocumentId != supportSiteKeyMap.get(lowerCaseKey)))
                {
                    newContent.addError('Support Site Key must be unique.  (Capitalization does NOT make the Support Site Key unique.)');
                    hasError = true;
                }
                else
                {
                    if(newContent.SupportSiteRedirectKeys__c != NULL)
                    {
                        //SupportSiteKey__c is unique, so verify the SupportSiteRedirectKeys__c
                        for(String newKey : newContent.SupportSiteRedirectKeys__c.split(';'))
                        {
                            String newLowerCaseKey = newKey.toLowerCase();
                            if(supportSiteKeyMap.containsKey(newLowerCaseKey) 
                               && newContent.ContentDocumentId != supportSiteKeyMap.get(newLowerCaseKey))
                            {
                                newContent.addError('Support Site Redirect Keys must be unique. (Capitalization does NOT make the Support Site Redirect Keys unique.)');
                                hasError = true;
                                break;
                            }
                        }
                    }
                }
                
                if(!hasError)
                {
                    //verify that the order is unique
                    if(newContent.SupportSiteLinkOrder__c == NULL 
                       || (supportSiteOrderMap.containsKey(newContent.SupportSiteLinkOrder__c) 
                      && newContent.ContentDocumentId != supportSiteOrderMap.get(newContent.SupportSiteLinkOrder__c)))
                    {
                        newContent.addError('Support Site Link Order must be unique');
                    }
                }
            }
        }
    }
    
    private void prepareSupportSiteMaps()
    {
        if(supportSiteKeyMap == NULL || supportSiteOrderMap == null)
        {
            supportSiteKeyMap = new Map<String, Id>();
            supportSiteOrderMap = new Map<Decimal, Id>();
            
            for(ContentVersion existingContent : [SELECT Id, ContentDocumentId, SupportSiteKey__c, SupportSiteRedirectKeys__c, SupportSiteLinkOrder__c 
                                                 FROM ContentVersion
                                                 WHERE RecordTypeId = :supportSiteRecordTypeId
                                                 AND Islatest = true])
            {
                supportSiteKeyMap.put(existingContent.SupportSiteKey__c.toLowerCase(), existingContent.ContentDocumentId);
                
                if(existingContent.SupportSiteRedirectKeys__c != NULL)
                {
                    for(String redirectKey : existingContent.SupportSiteRedirectKeys__c.split(';'))
                    {
                        supportSiteKeyMap.put(redirectKey.toLowerCase(), existingContent.ContentDocumentId);
                    }
                }
                supportSiteOrderMap.put(existingContent.SupportSiteLinkOrder__c, existingContent.ContentDocumentId);
            }
        }
    }
}