global class PSTimesheetScheduler implements Schedulable
{
 
    global void execute(SchedulableContext ctx)
    {
        id batchinstanceid = database.executeBatch(new PSTimesheetBatch(), 20);
    }
}