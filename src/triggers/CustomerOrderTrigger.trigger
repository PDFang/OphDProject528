trigger CustomerOrderTrigger on CustomerOrder__c (before insert) {
	new CustomerOrderTriggerHandler().run();
}