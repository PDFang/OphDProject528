/**
 * Created by mohandaas.rangaswamy on 11/22/2016.
 */
trigger SharedOpportunity on Shared_Opportunity__c (after insert, after update) {
    new SharedOpportunityTriggerHandler().run();
}