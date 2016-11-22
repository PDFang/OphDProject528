/**
 * Created by mohandaas.rangaswamy on 11/21/2016.
 */

public without sharing class OpportunityPartnerSharingController {

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
        for(User u : [Select Id, Name, isActive from User where accountID != null limit 10]){
            PartnerWrapper wrapper = new PartnerWrapper(u);
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
            system.debug('**** shareOpportunity():  wrapper - '+wrapper);
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
            insert sharedList;
        }catch(Exception ex){
            return false;
        }

        return true;
    }
}