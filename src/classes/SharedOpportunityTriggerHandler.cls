/**
 * Created by mohandaas.rangaswamy on 11/22/2016.
 */
public class  SharedOpportunityTriggerHandler extends TriggerHandler{

    public override void afterUpdate(){
        createAccountPartner((List<Shared_Opportunity__c>) trigger.new, (Map<Id, Shared_Opportunity__c>) trigger.oldMap);
    }

    public static void createAccountPartner(List<Shared_Opportunity__c> oppList, Map<Id, Shared_Opportunity__c> oldMap){
        system.debug('**** createAccountPartner(): oppList - ' + oppList);
        Set<Id> partnerIdSet = new Set<Id>();
        //Set<Id> customerIdSet = new Set<Id>();
        List<Shared_Opportunity__c> processList = new List<Shared_Opportunity__c>();

        for(Shared_Opportunity__c opp : oppList){
            if(opp.Status__c == 'Accept' && oldMap.get(opp.Id).Status__c != 'Accept' && opp.Partner_User__C != null){
                partnerIdSet.add(opp.Partner_User__C);
                //customerIdSet.add(opp.Account_ID__c);
                processList.add(opp);
            }
        }

        if(processList.isEmpty()){
            return;
        }
        system.debug('**** createAccountPartner(): processList - ' + processList);

        Map<Id, User> partnerMap = new Map<Id, User>([
           Select Id, AccountId from User where Id IN :partnerIdSet
        ]);

        Map<String, Schema.RecordTypeInfo> recordTypeMap = Schema.SObjectType.Account_Partner__c.getRecordTypeInfosByName();
        List<Account_Partner__c> partnerList = new List<Account_Partner__c>();
        for(Shared_Opportunity__c opp : processList){
            User partner = partnerMap.get(opp.Partner_User__c);
            Account_Partner__c newPartner = new Account_Partner__c(
                    Customer__c =  opp.Account_ID__c,
                    Partner__c = partner.AccountId,
                    Partner_Type__c = 'iCE',
                    RecordTypeId = recordTypeMap.get('Partner Account').getRecordTypeId()
            );
            partnerList.add(newPartner);
        }

        insert partnerList;
    }
}