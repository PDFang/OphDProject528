trigger ContactAfterUpdateInsert on Contact (after insert, after update)
{
	new TriggerHandler().run();
}