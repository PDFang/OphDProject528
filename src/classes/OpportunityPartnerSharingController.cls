/**
 * Created by mohandaas.rangaswamy on 11/21/2016.
 */

public without sharing class OpportunityPartnerSharingController {

    private static final String PARTNEY_TYPE_ICE = 'iCE';

    public class PartnerWrapper{
        @AuraEnabled
        public boolean selected{get;set;}
        @AuraEnabled
        public User partner{get; private set;}

        public PartnerWrapper(User u){
            this.partner = u;
            this.selected = false;
        }
    }

    @AuraEnabled
    public static List<PartnerWrapper> getiCEPartners(){

        List<PartnerWrapper> wrapperList = new List<PartnerWrapper>();

        List<Partner_Permission_Set__mdt> mdt = [
                Select Permission_Set__c, Partner_Type__c
                from Partner_Permission_Set__mdt
                where Partner_Type__c = :PARTNEY_TYPE_ICE
        ];
        if(mdt.isEmpty()){
            return wrapperList;
        }

        for(PermissionSetAssignment psa :[
                Select AssigneeId, Assignee.Name, Assignee.isActive
                from PermissionSetAssignment
                where PermissionSet.Name = :mdt[0].Permission_Set__c
                and Assignee.isActive = true
        ]){
            PartnerWrapper wrapper = new PartnerWrapper(psa.Assignee);
            wrapperList.add(wrapper);
        }
        return wrapperList;
    }

    @AuraEnabled
    public static boolean shareOpportunity(String opportunityId, String jsonString){

        List<PartnerWrapper> partnerList = (List<PartnerWrapper>)System.JSON.deserializeStrict(jsonString, List<PartnerWrapper>.Class);

        system.debug('**** shareOpportunity():  opportunityId - '+opportunityId);
        system.debug('**** shareOpportunity():  partnerList - '+partnerList);

        List<Shared_Opportunity__c> sharedList = new List<Shared_Opportunity__c>();
        for(PartnerWrapper wrapper : partnerList){
            if(!wrapper.selected){
                continue;
            }
            Shared_Opportunity__c sharedOpp = new Shared_Opportunity__c();
            sharedOpp.Opportunity__c = opportunityId;
            sharedOpp.Partner_User__c = wrapper.partner.Id;
            sharedList.add(sharedOpp);
        }
        system.debug('**** shareOpportunity():  partnerList - '+partnerList);
        try{
            if(sharedList.size() > 0)
                insert sharedList;
        }catch(Exception ex){
            return false;
        }

        return true;
    }
}