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
        //CalculateAccountNetScore((List<Case>) trigger.new, (Map<Id, Case>) trigger.oldMap);
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
            if(accountRecord.RecordTypeId == saasCustomerRecordType
                    || accountRecord.RecordTypeId == resellCustomerRecordType
                    || accountRecord.RecordTypeId == resellPartnerRecordType) {

                accountList.add(accountRecord);
            }
        }

        system.debug('CalculateAccountNetScore(): accountList - ' + accountList);

        if(accountList.size() > 0){

            ImpactCalculationService calculationService = new ImpactCalculationService(new IncidentImpactCalculationImplementation());
            calculationService.CalculateAccountNetScore(accountList);
        }
    }
}