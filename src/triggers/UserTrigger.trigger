trigger UserTrigger on User (after insert, after update) {
    new UserTriggerHandler().run();
}