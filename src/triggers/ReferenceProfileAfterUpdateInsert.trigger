/**
 * Created by ravish.chawla on 6/9/2017.
 */

trigger ReferenceProfileAfterUpdateInsert on refedge__Reference_Basic_Information__c (after insert, after update)
{
    new ReferenceProfileTriggerHandler().run();

}