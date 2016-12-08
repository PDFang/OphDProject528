/**
 * Created by mohandaas.rangaswamy on 11/22/2016.
 */
public class  SharedOpportunityTriggerHandler extends TriggerHandler{

    private static Map<String, Schema.RecordTypeInfo> partnerRecordTypeMap = null;
    private static Map<Id, User> userMap = null;

    public override void afterInsert(){

    }

    public override void afterUpdate(){
        updateOpportunity((Map<Id, Shared_Opportunity__c>) trigger.newMap, (Map<Id, Shared_Opportunity__c>) trigger.oldMap);
        deleteShare((List<Shared_Opportunity__c>) trigger.new, (Map<Id, Shared_Opportunity__c>) trigger.oldMap);
        createAccountPartner((List<Shared_Opportunity__c>) trigger.new, (Map<Id, Shared_Opportunity__c>) trigger.oldMap);
    }

    // delete apex sharing when the status is changed from 'New' to 'Accepted' or 'Rejected'
    public static void deleteShare(Map<Id, Shared_Opportunity__c> newMap, Map<Id, Shared_Opportunity__c> oldMap){

        system.debug('**** deleteShare(): oppList - ' + oppList);
        Set<Id> sharedOppIdSet = new Set<Id>();

        for(Shared_Opportunity__c opp : newMap.values()){
            if((opp.Status__c == 'Accepted' || opp.Status__c == 'Rejected') && oldMap.get(opp.Id).Status__c != opp.Status__c ){
                sharedOppIdSet.add(opp.Id);
            }
        }

        if(sharedOppIdSet.isEmpty()){
            return;
        }
        system.debug('**** deleteShare(): sharedOppIdSet - ' + sharedOppIdSet);

        List<Shared_Opportunity__Share> shareList = new List<Shared_Opportunity__Share>();
        for(Shared_Opportunity__Share share : [
                Select Id, UserOrGroupId from Shared_Opportunity__Share
                where ParentId IN :sharedOppIdSet
                and Rowcause = :Schema.Shared_Opportunity__Share.RowCause.iCE_Partner__c
        ]){
            Shared_Opportunity__c sharedOpp = newMap.get(share.ParentId);
            if(sharedOpp.Status__c == 'Rejected' && sharedOpp.Partner_User__C == share.UserOrGroupId){
                shareList.add(share);
            } else if(sharedOpp.Status__c == 'Accepted'){
                shareList.add(share);
            }
        }

        system.debug('**** createAccountPartner(): shareList - ' + shareList);
        if(shareList.size() > 0)
            delete shareList;

    } // end of deleteShare()

    // create an account partner record when Shared Opportunity is accepted
    public static void createAccountPartner(List<Shared_Opportunity__c> oppList, Map<Id, Shared_Opportunity__c> oldMap){
        system.debug('**** createAccountPartner(): oppList - ' + oppList);
        Set<Id> partnerIdSet = new Set<Id>();
        Set<Id> accountIdSet = new Set<Id>();
        List<Shared_Opportunity__c> processList = new List<Shared_Opportunity__c>();

        for(Shared_Opportunity__c opp : oppList){
            if(opp.Status__c == 'Accepted' && oldMap.get(opp.Id).Status__c != 'Accepted' && opp.Opportunity__c != null
                    && opp.Partner_User__c != null){
                partnerIdSet.add(opp.Partner_User__C);
                processList.add(opp);
                accountIdSet.add(opp.Account_ID__c);
            }
        }

        if(processList.isEmpty()){
            return;
        }
        system.debug('**** createAccountPartner(): processList - ' + processList);

        // get current account partners
        Map<Id, Set<Id>> iCEPartnerMap = new Map<Id, Set<Id>>();
        for(Account_Partner__c partner : [
                Select Customer__c, Partner__c
                from Account_Partner__c
                where Customer__c IN :accountIdSet and Partner_Type__c = :AccountPartnerTriggerHandler.ICE_PARTNER
        ]){
            Set<Id> iCEPartnerIds = iCEPartnerMap.get(partner.Customer__c);
            if(iCEPartnerIds == null){
                iCEPartnerIds = new Set<Id>();
                iCEPartnerMap.put(partner.Customer__c, iCEPartnerIds);
            }
            iCEPartnerIds.add(partner.Partner__c);
        }

        Map<Id, User> partnerUserMap = getUserInfo(partnerIdSet);

        Map<String, Schema.RecordTypeInfo> recordTypeMap = getRecordTypeInfosByName();
        List<Account_Partner__c> partnerList = new List<Account_Partner__c>();
        for(Shared_Opportunity__c opp : processList){
            Set<Id> iCEPartners = iCEPartnerMap.get(opp.Account_ID__c);
            User partner = partnerUserMap.get(opp.Partner_User__c);
            // check already an iCE partner
            if(iCEPartners.contains(partner.AccountId)){
                continue;
            }
            Account_Partner__c newPartner = new Account_Partner__c(
                    Customer__c =  opp.Account_ID__c,
                    Partner__c = partner.AccountId,
                    Partner_Type__c = AccountPartnerTriggerHandler.ICE_PARTNER,
                    RecordTypeId = recordTypeMap.containsKey('Partner Account')
                                    ? recordTypeMap.get('Partner Account').getRecordTypeId() : null
            );
            partnerList.add(newPartner);
        }

        system.debug('**** createAccountPartner(): partnerList - ' + partnerList);

        if(partnerList.size() > 0)
            insert partnerList;

    } // end of createAccountPartner()

    // Update opportunity when Shared Opportunity is accepted
    public static void updateOpportunity(List<Shared_Opportunity__c> oppList, Map<Id, Shared_Opportunity__c> oldMap){

        system.debug('**** updateOpportunity(): oppList - ' + oppList);
        Set<Id> partnerIdSet = new Set<Id>();
        List<Shared_Opportunity__c> processList = new List<Shared_Opportunity__c>();

        for(Shared_Opportunity__c opp : oppList){
            if(opp.Status__c == 'Accepted' && oldMap.get(opp.Id).Status__c != 'Accepted' && opp.Opportunity__c != null
                    && opp.Partner_User__c != null){
                partnerIdSet.add(opp.Partner_User__C);
                processList.add(opp);
            }
        }

        if(processList.isEmpty()){
            return;
        }
        system.debug('**** createAccountPartner(): processList - ' + processList);

        Map<Id, User> partnerUserMap = getUserInfo(partnerIdSet);

        List<Opportunity> opportunityList = new List<Opportunity>();
        for(Shared_Opportunity__c opp : processList){
            User partner = partnerUserMap.get(opp.Partner_User__c);
            Opportunity newPartner = new Opportunity(
                    Id =  opp.Opportunity__c,
                    iCE_Partner__c = partner.AccountId,
                    iCE_Partner_Status__c = 'Accepted'
            );
            opportunityList.add(newPartner);
        }

        system.debug('**** createAccountPartner(): opportunityList - ' + opportunityList);

        if(opportunityList.size() > 0)
            update opportunityList;

    } // end of updateOpportunity()

    // cache Record Type info
    private static Map<String, Schema.RecordTypeInfo> getRecordTypeInfosByName(){

        if (partnerRecordTypeMap == null)
            partnerRecordTypeMap = Schema.SObjectType.Account_Partner__c.getRecordTypeInfosByName();

        return partnerRecordTypeMap;
    }

    // Cache User info
    private static Map<Id, User> getUserInfo(Set<ID> userIdSet){

        if (userMap == null || !userMap.keyset().containsAll(userIdSet) )
            userMap = new Map<Id, User>([
                    Select Id, AccountId from User where Id IN :userIdSet
            ]);

        return userMap;
    }

}