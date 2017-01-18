/*
    New - Article created from case.
    Known - Article not created from case.
    N/A - No article, or article attached after 7 days from case close date.
    Citation - Knowledge Article created by is not who created Case Article (or who attached article to case). Citation: "use of someone else’s article".
*/
global class CaseUpdateBatch implements Database.Batchable<sObject> {

	global final String gstrQuery;
	Set<String> stRecordTypes = new Set<String>();

    static final Set<String> caseRecordTypes = new Set<String>{
        'Incident',
        'Incident - Premise',
        'Work Orders',
        'Service Request'
    };

    public static final String NO_ARTICLE = 'N/A';
    public static final String NEW_ARTICLE = 'New';
    public static final String KNOWN_ARTICLE = 'Known';


    global CaseUpdateBatch(String query)
    {
        Map<String,Schema.RecordTypeInfo> recordTypeMap = Schema.SobjectType.Case.getRecordTypeInfosByName();
        for(String recordType : caseRecordTypes){
            stRecordTypes.add(recordTypeMap.get(recordType).getRecordTypeId());
        }
        gstrQuery = query;
        system.debug('gstrQuery ==>' + gstrQuery);
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
    	return Database.getQueryLocator(gstrQuery);
    }
 
    global void execute(Database.BatchableContext BC, List<Case> scope)
    {

        Map<Id, Case> caseMap = new Map<Id, Case>(); // CaseId => Case
		// create a Map of Cases
		for (Case c : scope){
            caseMap.put(c.Id, c);
		}
        system.debug('***** Total No. of Cases - ' + caseMap.size());

        Set<Id> articleIdSet = new Set<Id>();
        Map<Id, CaseArticle> caseArticleMap = new Map<Id, CaseArticle>(); // CaseId => CaseArticle
        // Grab all case articles
	    for(CaseArticle ca:[
                Select CaseId, KnowledgeArticleId, CreatedById, ArticleVersionNumber
                from CaseArticle
                WHERE CaseId IN : caseMap.keySet()
                order by CaseId, CreatedDate
        ]){
            caseArticleMap.put(ca.CaseId, ca);
            articleIdSet.add(ca.KnowledgeArticleId);
        }
        system.debug('***** No. of Cases having article - ' + caseArticleMap.size());

        // read KnowledgeArticleVersions
        Map<Id, List<KnowledgeArticleVersion>> articleVersionMap = new Map<Id, List<KnowledgeArticleVersion>>(); // KnowledgeArticleId => List<KnowledgeArticleVersion>
        if(articleIdSet.size() > 0) {
            readKnowledgeArticleVersions(articleIdSet, articleVersionMap);
        }

        // update New_vs_Known__c
        List<Case> caseUpdateList = new List<Case>();
        for(Case caseObj : caseMap.values()){
            // No article
            if(!caseArticleMap.containsKey(caseObj.Id)){
                if(caseObj.New_vs_Known__c != NO_ARTICLE || caseObj.KB_Attached__c){
                    caseObj.New_vs_Known__c = NO_ARTICLE;
                    caseObj.KB_Attached__c = false;
                    caseUpdateList.add(caseObj);
                }
            }
            // has article
            else{
                CaseArticle ca = caseArticleMap.get(caseObj.Id);
                List<KnowledgeArticleVersion> versions = articleVersionMap.get(ca.KnowledgeArticleId);
                if(versions == null){
                    continue;
                }
                for(KnowledgeArticleVersion kav :versions){
                    if(kav.VersionNumber == ca.ArticleVersionNumber){
                        caseObj.New_vs_Known__c = (ca.CaseId == kav.SourceId) ? NEW_ARTICLE : KNOWN_ARTICLE;
                        caseObj.Citation__c = (ca.CreatedById == kav.CreatedById) ? true : false;
                        caseObj.KB_Attached__c = true;
                        caseUpdateList.add(caseObj);
                        break;
                    }
                }
            }
        } // case iteration

        if(caseUpdateList.size() > 0){
            Database.SaveResult[] results = Database.update(caseUpdateList, false);
            Map<Id,String> errorDetails = new Map<Id,String>();
            for (Integer i = 0; i < caseUpdateList.size(); i++){
                Database.SaveResult sr = results[i];
                if (!sr.isSuccess() && sr.getErrors().size() > 0){
                    errorDetails.put(caseUpdateList[i].Id, sr.getErrors()[0].getMessage());
                }
            }
            if(errorDetails.size() > 0){
                try{
                    sendErrorEmail(errorDetails);
                }catch(System.Exception ex){
                    system.debug('***** Error sending email - ' + ex);
                }

            }
        }

    } // end of execute()

    private void readKnowledgeArticleVersions(Set<Id> articleIdSet, Map<Id, List<KnowledgeArticleVersion>> articleVersionMap){

        // salesforce limitation - Must filter KnowledgeArticleVersion by ID or Status
        // Published Articles
        for(KnowledgeArticleVersion kav: [
                SELECT Id, SourceId, CreatedById, KnowledgeArticleId, VersionNumber  FROM KnowledgeArticleVersion
                WHERE PublishStatus='Online' AND Language = 'en_US'
                AND KnowledgeArticleId IN : articleIdSet
        ]){
            List<KnowledgeArticleVersion> versions = articleVersionMap.get(kav.KnowledgeArticleId);
            if(versions == null){
                versions = new List<KnowledgeArticleVersion>();
                articleVersionMap.put(kav.KnowledgeArticleId, versions);
            }
            versions.add(kav);
        }

        // Draft Articles
        for(KnowledgeArticleVersion kav: [
                SELECT Id, SourceId, CreatedById, KnowledgeArticleId, VersionNumber  FROM KnowledgeArticleVersion
                WHERE PublishStatus='Draft' AND Language = 'en_US'
                AND KnowledgeArticleId IN : articleIdSet
        ]){
            List<KnowledgeArticleVersion> versions = articleVersionMap.get(kav.KnowledgeArticleId);
            if(versions == null){
                versions = new List<KnowledgeArticleVersion>();
                articleVersionMap.put(kav.KnowledgeArticleId, versions);
            }
            versions.add(kav);
        }

        // Archived Articles
        for(KnowledgeArticleVersion kav: [
                SELECT Id, SourceId, CreatedById, KnowledgeArticleId, VersionNumber  FROM KnowledgeArticleVersion
                WHERE PublishStatus='Archived' AND IsLatestVersion = false AND Language = 'en_US'
                AND KnowledgeArticleId IN : articleIdSet
        ]){
            List<KnowledgeArticleVersion> versions = articleVersionMap.get(kav.KnowledgeArticleId);
            if(versions == null){
                versions = new List<KnowledgeArticleVersion>();
                articleVersionMap.put(kav.KnowledgeArticleId, versions);
            }
            versions.add(kav);
        }

    } // end of readKnowledgeArticleVersions()

    private void sendErrorEmail(Map<Id,String> errorDetails){
        string subject = 'Case KB Update Batch Errors' ;
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[]{};
        toAddresses = Label.DEVErrorEmailRecipient.split(',');
        email.setSenderDisplayName('Salesforce IT');
        email.setSubject(subject);
        email.setToAddresses(toAddresses);
        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        string body = '<table align="center" border="1" cellpadding="0" cellspacing="0"><thead><th><b>Case ID</b></th><th><b>Error message</b></th></thead><tbody>' ;
        for(Id caseId : errorDetails.keySet())
        {
            String hrefValue = baseUrl + '/' + caseId;
            body += '<tr><td><a href="' + hrefValue + '">' + caseId + '</a></td>';
            body += '<td>' + errorDetails.get(caseId) + '</td></tr>';
        }

        body += '</tbody></table>';
        email.setHtmlBody(body);
        //send message
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }
    
    global void finish(Database.BatchableContext BC)
    {
        Last_Batch_Run_Date__c batchRunDt = Last_Batch_Run_Date__c.getInstance('LastRunTime');
        if (batchRunDt != null) {
            batchRunDt.LastRunTime__c = system.now();
            update batchRunDt;
        }
        AsyncApexJob a = [
                SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
                TotalJobItems, CreatedBy.Email, ExtendedStatus
                FROM AsyncApexJob
                WHERE Id =
                :BC.getJobId()
        ];

        // Send an email to the Apex job's submitter notifying of job completion.
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[]{
                a.CreatedBy.Email
        };
        mail.setToAddresses(toAddresses);
        mail.setSubject('Case KB Attached Batch ' + a.Status);
        mail.setPlainTextBody('The batch Apex job processed '
                + a.TotalJobItems
                + ' batches with '
                + a.NumberOfErrors
                + ' failures.');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{
                mail
        });
        
    }
}