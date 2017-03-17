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
    protected override void beforeInsert(){
        CalculateAccountNetScore((List<Account>) trigger.new, (Map<Id, Account>) trigger.oldMap);
    }

    protected override void beforeUpdate(){
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
        List<Account> accountList = new List<Account>();

        for(Account accountRecord : newList){
            Account oldAccount = oldMap.get(accountRecord.Id);
            // is new or dependent fields updated
            if(oldAccount == null || recalculateScore(accountRecord, oldAccount)
                    && (accountRecord.RecordTypeId == saasCustomerRecordType
                    || accountRecord.RecordTypeId == resellCustomerRecordType
                    || accountRecord.RecordTypeId == resellPartnerRecordType) ){

                accountList.add(accountRecord);
            }
        }

        system.debug('CalculateAccountNetScore(): accountList - ' + accountList);

        if(accountList.size() > 0){

            ImpactCalculationService calculationService = new ImpactCalculationService(new IncidentImpactCalculationImplementation());
            calculationService.CalculateAccountNetScore(accountList);
        }
    }

    private boolean recalculateScore(Account newRecord, Account oldRecord){
        return newRecord.IsPartner__c != oldRecord.IsPartner__c
                || (newRecord.CustomerSegment__c != oldRecord.CustomerSegment__c && (newRecord.CustomerSegment__c == 'Strategic' || oldRecord.CustomerSegment__c == 'Strategic') )
                || newRecord.Brand_Visibility__c != oldRecord.Brand_Visibility__c
                || newRecord.Industry_Leadership_Vocality__c != oldRecord.Industry_Leadership_Vocality__c
                || newRecord.Social_Media_Presence__c != oldRecord.Social_Media_Presence__c
                || newRecord.Risk_of_Leaving__c != oldRecord.Risk_of_Leaving__c
                || newRecord.Referenceable__c != oldRecord.Referenceable__c
                || newRecord.GYRStatus__c != oldRecord.GYRStatus__c;
    }

}