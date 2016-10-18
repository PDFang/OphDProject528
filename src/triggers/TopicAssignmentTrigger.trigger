trigger TopicAssignmentTrigger on TopicAssignment (after insert, after delete) {
new TopicAssignmentTriggerHandler().run();
}