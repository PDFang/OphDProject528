public without sharing class PartnerDocumentLandingPageController {
    public class DocumentDetail {
        public String Title { get; private set; }
        public String DocumentId { get; private set; }
        public String DocumentExtension { get; private set; }
        public String DocumentCategory {get;set;}
    }

    public List<DocumentDetail> DocumentDetailList { get; private set; }
    public String SelectedDocumentId { get; private set; }
    public String SelectedDocumentExtension { get; private set; }
    public String SelectedDocumentTitle{get;set;}
    public String SelectedDocumentCategory{get;set;}
    public Boolean ShowCanvasApp { get; private set; }
    public Map<String, List<DocumentDetail>> CategoryToDocumentMap {get;set;}

    private Set<String> partnerTypeNames = new Set<String>();

    public PartnerDocumentLandingPageController() {
        //set up the partnerTypeNames
        system.debug('loading partner types for user');
        setAllowedPartnerTypesForUser();

        //retrieve the list of documents
        DocumentDetailList = new List<DocumentDetail>();
        CategoryToDocumentMap = new Map<String, List<DocumentDetail>>();

        //documents visible to all accounts
        system.debug('loading documents visible to all accounts');
        loadDocumentsVisibleToAllAccounts();

        //documents visible to the user
        system.debug('loading documents visible to account associated to user');
        loadDocumentsVisibleToUserAccount();

        ShowCanvasApp = false;
    }

    public void setSelectedDocumentId() {
        SelectedDocumentId = ApexPages.currentPage().getParameters().get('documentId');
        SelectedDocumentExtension = ApexPages.currentPage().getParameters().get('documentExtension');
        SelectedDocumentTitle = ApexPages.currentPage().getParameters().get('documentTitle');
        ShowCanvasApp = true;
    }

    public void setSelectedCategory(){
        String selectedCategory = ApexPages.currentPage().getParameters().get('selectedCategory');
        SelectedDocumentCategory = selectedCategory;
        system.debug('Setting selected document category : ' + selectedCategory);
    }

    private void setAllowedPartnerTypesForUser() {
        Set<String> userPermissionSetNames = new Set<String>();
        //load the permission set names for the user
        for(PermissionSetAssignment assignment : [SELECT PermissionSet.Name FROM PermissionSetAssignment WHERE AssigneeId = :userinfo.getUserId()]) {
            userPermissionSetNames.add(assignment.PermissionSet.Name);
        }
        system.debug('loaded ' + userPermissionSetNames.size() + ' permission sets for user ' + userinfo.getUserId());

        for(Partner_Permission_Sets__c pps : [SELECT Partner_Type__c FROM Partner_Permission_Sets__c WHERE Permission_Set__c in :userPermissionSetNames]) {
            partnerTypeNames.add(pps.Partner_Type__c);
        }
        system.debug('loaded ' + partnerTypeNames.size() + ' partnerTypeNames for user ' + userinfo.getUserId());
    }

    private void loadDocumentsVisibleToAllAccounts() {
        //load all documents that are visible to all accounts and if the partner type is set it matches the user's partner type
        for(Partner_Document_Manager__c pdm : [
                SELECT Title__c, LatestVersionId__c, FileType__c,Category__c
                FROM Partner_Document_Manager__c
                WHERE All_Accounts__c = true
                AND Active__c = true
                AND LatestVersionId__c != null
                AND (Partner_Type__c = null OR Partner_Type__c in :partnerTypeNames)
                AND FileType__c  != null
                AND Category__c  != null
        ]) {

            DocumentDetail detail = new DocumentDetail();
            detail.Title = pdm.Title__c;
            detail.DocumentId = pdm.LatestVersionId__c;
            detail.DocumentExtension = pdm.FileType__c;
            detail.DocumentCategory = pdm.Category__c;
            DocumentDetailList.add(detail);


            if(CategoryToDocumentMap.containsKey(pdm.Category__c)){
                List<DocumentDetail> documentList = CategoryToDocumentMap.get(pdm.Category__c);
                documentList.add(detail);
                CategoryToDocumentMap.put(pdm.Category__c, documentList);
            } else{
                List<DocumentDetail> documentList = new List<DocumentDetail>();
                documentList.add(detail);
                CategoryToDocumentMap.put(pdm.Category__c, documentList);
            }
        }
        system.debug('after loading documents visible to all accounts ' + DocumentDetailList.size());
    }

    private void loadDocumentsVisibleToUserAccount() {
        //get the account id of the user
        List<User> currentUserList = [SELECT AccountId FROM User WHERE Id = :userinfo.getUserId()];
        if(currentUserList.size() == 0) {
            return;
        }

        Id accountId = currentUserList[0].AccountId;

        for(Partner_Document_Access__c pda : [
                SELECT Partner_Document_Manager__r.Title__c, Partner_Document_Manager__r.LatestVersionId__c,
                Partner_Document_Manager__r.FileType__c, Partner_Document_Manager__r.Category__c
                FROM Partner_Document_Access__c
                WHERE Partner_Document_Manager__r.All_Accounts__c = false
                AND Partner_Document_Manager__r.Active__c = true
                AND Partner_Document_Manager__r.LatestVersionId__c != null
                AND (Partner_Document_Manager__r.Partner_Type__c = null OR Partner_Document_Manager__r.Partner_Type__c in :partnerTypeNames)
                AND Account__r.Id = :accountId
                AND Partner_Document_Manager__r.FileType__c  != null
                AND Partner_Document_Manager__r.Category__c  != null
        ]) {
            DocumentDetail detail = new DocumentDetail();
            detail.Title = pda.Partner_Document_Manager__r.Title__c;
            detail.DocumentId = pda.Partner_Document_Manager__r.LatestVersionId__c;
            detail.DocumentExtension = pda.Partner_Document_Manager__r.FileType__c;
            detail.DocumentCategory = pda.Partner_Document_Manager__r.Category__c;
            DocumentDetailList.add(detail);

            if(CategoryToDocumentMap.containsKey(pda.Partner_Document_Manager__r.Category__c)){
               List<DocumentDetail> documentList =  CategoryToDocumentMap.get(pda.Partner_Document_Manager__r.Category__c);
                documentList.add(detail);
                CategoryToDocumentMap.put(pda.Partner_Document_Manager__r.Category__c, documentList);
            } else{
                List<DocumentDetail> documentList = new List<DocumentDetail>();
                documentList.add(detail);
                CategoryToDocumentMap.put(pda.Partner_Document_Manager__r.Category__c, documentList);
            }
        }

        system.debug('after loading documents visible to the account the user associated to ' + DocumentDetailList.size());
    }
}