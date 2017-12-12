/**
 * Created by mohandaas.rangaswamy on 12/11/2017.
 */

trigger WorkItTiming on WorkIt2__Timing__c (before insert, before update, before delete, after insert, after update, after delete) {

    new TimingTriggerHandler().run();

}