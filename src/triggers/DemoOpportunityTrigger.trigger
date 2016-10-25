trigger DemoOpportunityTrigger on Opportunity (before insert, before update) {
    new DemoOpportunityTriggerHandler().run();
}