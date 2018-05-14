public without sharing class NewBusinessUnitRequestExtension {

    public Account newAccount {get; set;}
    public Contact newContact {get; set;}
    public Opportunity newOpportunity {get;set;}
    public Contract existingContract {get;set;}
    public boolean renderForm {public get; private set;}
    private Id prospectAccountRecordTypeId;
    private Id prospectContactRecordTypeId;
    private Id newOpportunityRecordTypeId;

    public NewBusinessUnitRequestExtension(ApexPages.StandardController controller) {
        Contract controllerContract = (Contract)controller.getRecord();
        //do this to avoid edit issues with the contract record
        existingContract = [SELECT Id, AccountId, Contract_Name__c, ContractType__c FROM Contract WHERE Id = :controllerContract.Id];
        if(existingContract.ContractType__c == 'Service Contract') {
            renderForm = true;
            newOpportunity = new Opportunity();
            newOpportunity.Contract_Type__c = 'Expansion New Division';
            SetAccountDefaults();
            newContact = new Contact();
            SetRecordTypeIds();
        } else {
            renderForm = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,'New Business Units can only be requested for contracts with a contract type of Service Contract'));
        }
    }

    private void SetAccountDefaults(){
        Account existingAccount = [SELECT Id, Name, BillingStreet, BillingState, BillingCity, BillingCountry, BillingPostalCode, Country_Code__c, Geo_Code__c, (SELECT Id FROM Contacts WHERE Contact_Role__c INCLUDES('Main') LIMIT 1) FROM Account WHERE Id = :existingContract.AccountId];
        newAccount = existingAccount.clone();
        if(existingAccount.Contacts.size() == 1){
            newOpportunity.PrimaryContact__c = existingAccount.Contacts[0].Id;
        }
    }

    private void SetRecordTypeIds(){
        Schema.DescribeSObjectResult a = Schema.SObjectType.Account;
        Map<String,Schema.RecordTypeInfo> rtMapByName = a.getRecordTypeInfosByName();

        prospectAccountRecordTypeId = rtMapByName.get('Prospects').getRecordTypeId();


        Schema.DescribeSObjectResult c = Schema.SObjectType.Contact;
        Map<String,Schema.RecordTypeInfo> contactRtMapByName = c.getRecordTypeInfosByName();

        prospectContactRecordTypeId = contactRtMapByName.get('Prospect Contact').getRecordTypeId();


        Schema.DescribeSObjectResult o = Schema.SObjectType.Opportunity;
        Map<String,Schema.RecordTypeInfo> opportunityRtMapByName = o.getRecordTypeInfosByName();

       newOpportunityRecordTypeId = opportunityRtMapByName.get('New Opportunity').getRecordTypeId();
    }

    public PageReference SaveNewBusinessUnit(){
        try {
            newAccount.RecordTypeId = prospectAccountRecordTypeId;
            insert newAccount;

            system.debug(newOpportunity.PrimaryContact__c);
            Contact existingContact = [SELECT FirstName, LastName, Email, Phone, Contact_Role__c FROM Contact WHERE Id = :newOpportunity.PrimaryContact__c];

            newContact = existingContact.clone();
            newContact.AccountId = newAccount.Id;
            newContact.RecordTypeId = prospectContactRecordTypeId;
            insert newContact;

            newOpportunity.PrimaryContact__c = newContact.Id;
            newOpportunity.AccountId = newAccount.Id;
            newOpportunity.StageName = OpportunityTriggerHelper.OPPORTUNITY_STAGE_TWO;
            newOpportunity.RecordTypeId = newOpportunityRecordTypeId;
            newOpportunity.CloseDate = system.today()+30;
            newOpportunity.Sales_Rep__c = UserInfo.getUserId();
            insert newOpportunity;
        }catch (Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, ex.getMessage()));
            return null;
        }

        PageReference oppPage = new PageReference('/' + newOpportunity.Id);
        oppPage.setRedirect(true);

        return oppPage;
    }

}