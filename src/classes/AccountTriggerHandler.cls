public class AccountTriggerHandler extends TriggerHandler  {
    private static boolean staticValuesSet = false;
    private static Id saasCustomerRecordType;
    private static Id resellCustomerRecordType;
    private static Id resellPartnerRecordType;

    public AccountTriggerHandler(){
        if(!staticValuesSet){
            SetRecordTypeIds(); // Update Record Types so we can make decisions on them later
        }
    }

    // Trigger Handler Overrides
    protected override void afterInsert(){
        CalculateAccountNetScore((List<Account>) trigger.new, (Map<Id, Account>) trigger.oldMap);
    }

    protected override void afterUpdate(){
        dissociateContactXmPerson((List<Account>) trigger.new, (Map<Id, Account>) trigger.oldMap);
        CalculateAccountNetScore((List<Account>) trigger.new, (Map<Id, Account>) trigger.oldMap);
    }

    private void SetRecordTypeIds() {
        Schema.DescribeSObjectResult d = Schema.SObjectType.Account;
        Map<String,Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();

        saasCustomerRecordType = rtMapByName.get('Customers').getRecordTypeId();
        resellCustomerRecordType = rtMapByName.get('Resell Customers').getRecordTypeId();
        resellPartnerRecordType = rtMapByName.get('Resell Partner').getRecordTypeId();
    }


    private void CalculateAccountNetScore(List<Account> newList, Map<Id, Account> oldMap){
        Set<Id> accountIdSet = new Set<Id>();
        for(Account accountRecord : newList){
            Account oldAccount = (oldMap != null) ? oldMap.get(accountRecord.Id) : null;
            // is new or dependent fields updated
            if(oldAccount == null || recalculateScore(accountRecord, oldAccount)
                    && (accountRecord.RecordTypeId == saasCustomerRecordType
                    || accountRecord.RecordTypeId == resellCustomerRecordType
                    || accountRecord.RecordTypeId == resellPartnerRecordType) ){

                accountIdSet.add(accountRecord.Id);
            }
        }

        system.debug('CalculateAccountNetScore(): accountIdSet - ' + accountIdSet);

        if(accountIdSet.size() > 0 && !system.isFuture() && !system.isBatch()){
            CalculateAccountNetScoreFuture(accountIdSet);
            system.debug('CalculateAccountNetScore(): calling CalculateAccountNetScoreFuture');
        }
    } // end of CalculateAccountNetScore()

    @Future
    private static void CalculateAccountNetScoreFuture(Set<Id> accountIdSet){

        List<Account> accountList = new List<Account>();
        for(Account accountRecord :[
                Select Id, RecordType.Name, Social_Media_Presence__c, CustomerSegment__c, Brand_Visibility__c, Industry_Leadership_Vocality__c,
                        Risk_of_Leaving__c,  Age_of_Customer_in_Months__c, IsPartner__c, Referenceable__c,
                        Account_Net_Score__c
                from Account
                where Id IN :accountIdSet
        ]){
            accountList.add(accountRecord);
        }
        system.debug('CalculateAccountNetScore(): accountList - ' + accountList);

        if(accountList.size() > 0) {
            ImpactCalculationService calculationService = new ImpactCalculationService(new AccountImpactCalculationImpl());
            calculationService.CalculateAccountNetScore(accountList);
        }
    }

    private boolean recalculateScore(Account newRecord, Account oldRecord){
        return newRecord.RecordTypeId != oldRecord.RecordTypeId
                || newRecord.CustomerSegment__c != oldRecord.CustomerSegment__c
                || newRecord.Brand_Visibility__c != oldRecord.Brand_Visibility__c
                || newRecord.Industry_Leadership_Vocality__c != oldRecord.Industry_Leadership_Vocality__c
                || newRecord.Social_Media_Presence__c != oldRecord.Social_Media_Presence__c
                || newRecord.Risk_of_Leaving__c != oldRecord.Risk_of_Leaving__c
                || newRecord.Referenceable__c != oldRecord.Referenceable__c;
    }

    private void clearXMAccountAssociation(List<Account> newList, Map<Id, Account> oldMap) {
        list<xmGroupChangeRequestHeader__c> xmHeaderData = new list<xmGroupChangeRequestHeader__c>();
        for (Account accountRecord : newList) {
            Account oldAccount = (oldMap != null) ? oldMap.get(accountRecord.Id) : null;
            // is account deactivated
            if (oldAccount != null && oldAccount.CG_Disconnect_Date__c == null && accountRecord.CG_Disconnect_Date__c != null) {
                system.debug('*** xmHeader Processing ==>Account =' + accountRecord);
                xmGroupChangeRequestHeader__c header = new xmGroupChangeRequestHeader__c();
                header.Account__c = accountRecord.Id;
                header.sObjectId__c = accountRecord.Id;
                header.sObjectType__c = 'account';
                xmHeaderData.add(header);
            }
            if (!xmHeaderData.isEmpty()) {
                insert xmHeaderData;
            }
        }
    }
    private void dissociateContactXmPerson(List<Account> newList, Map<Id, Account> oldMap){
        Set<Id> accountIdSet = new Set<Id>();
        list<xmChangeRequestHeaderData> xmHeaderData = new list<xmChangeRequestHeaderData>();
        for(Account accountRecord : newList){
            Account oldAccount = (oldMap != null) ? oldMap.get(accountRecord.Id) : null;
            // is account deactivated
            if(oldAccount != null && oldAccount.CG_Disconnect_Date__c == null
                    && accountRecord.CG_Disconnect_Date__c != null){
                accountIdSet.add(accountRecord.Id);
                //adds data to xmBatch header for xMatters
                xmChangeRequestHeaderData header = new xmChangeRequestHeaderData();
                header.accountId = accountRecord.Id;
                header.sObjectId = accountRecord.Id;
                header.sObjectType = 'account';
                xmHeaderData.add(header);
            }
        }

        if (!xmHeaderData.isEmpty()) {
            xMGroupRequestHelper.CreateGroupChangeRequestHeader(xmHeaderData);
        }

        system.debug('dissociateContactXmPerson(): accountIdSet - ' + accountIdSet);

        if(accountIdSet.isEmpty()){
            return;
        }

        Contact[] updateList = new Contact[]{};

        for(Contact cont : [
                Select Id, xmPerson__c, xmPerson__r.xmPersonUID__c
                from Contact
                where AccountId IN :accountIdSet and xmPerson__c!= null
        ]){
            cont.xmPerson__c = null;
            cont.XmattersUid__c = cont.xmPerson__r.xmPersonUID__c;
            updateList.add(cont);
        }

        system.debug('dissociateContactXmPerson(): updateList - ' + updateList);

        if(updateList.size() > 0) {
            Database.update(updateList, false);
        }


    }

}