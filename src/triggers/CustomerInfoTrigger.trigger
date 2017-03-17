/**
 * Created by mohandaas.rangaswamy on 3/17/2017.
 */

trigger CustomerInfoTrigger on JBCXM__CustomerInfo__c (before insert, before update, after insert, after update) {

    new CustomerInfoTriggerHandler().run();

}