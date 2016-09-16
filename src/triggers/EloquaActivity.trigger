trigger EloquaActivity on MarketingActivity__c(before insert) {
        EDP1.Processor.handleTrigger();
}