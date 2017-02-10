trigger OrderLineGeneralItems on OrderLineGeneralItems__c (after update) {
  	new OrderLineGeneralItemTiggerHandler().run();
}