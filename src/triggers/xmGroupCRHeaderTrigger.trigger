/**
 * Created by ravish.chawla on 7/12/2017.
 */

trigger xmGroupCRHeaderTrigger on xmGroupChangeRequestHeader__c (after insert, after update) {
    new xMGroupRequestHelper().run();
}