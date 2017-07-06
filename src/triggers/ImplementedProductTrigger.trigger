/**
 * Created by ravish.chawla on 7/6/2017.
 */

trigger ImplementedProductTrigger on ImplementedProduct__c (after update) {
    new ImplementedProductTriggerHandler().run();
}