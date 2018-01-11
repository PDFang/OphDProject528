global class CaseKBAttachedScheduler implements Schedulable {
    
	global void execute(SchedulableContext ctx)
    {
        // Last_Batch_Run_Date__c batchRunDt = Last_Batch_Run_Date__c.getall().values();
        //dateTime lastBatchRunTime = batchRunDt.LastRunTime__c;
        //determine if the day is Sunday
        Date currentDate = system.today();

        dateTime lastBatchRunTime = currentDate.addDays(-7);

        string formattedDate = lastBatchRunTime.format('yyyy-MM-dd') + 'T00:00:00Z';
        Set<String> stRecordTypes = new Set<String>();

        //string casesQuery = 'SELECT Id, KB_Attached__c, New_vs_Known__c, CaseNumber, Status, ClosedDate FROM Case WHERE (KB_ATTACHED__C = false OR (KB_ATTACHED__C = true AND New_vs_Known__c = NULL)) AND isClosed = true AND ClosedDate >= ' + formattedDate + ' AND recordTypeId in :stRecordTypes';
        string casesQuery = 'SELECT Id, KB_Attached__c, New_vs_Known__c, CaseNumber, Status, ClosedDate FROM Case '
                + 'WHERE (KB_ATTACHED__C = false OR (KB_ATTACHED__C = true AND New_vs_Known__c NOT IN (\':CaseUpdateBatch.NEW_ARTICLE\', \':CaseUpdateBatch.KNOWN_ARTICLE\')) ) '
                + 'AND ((isClosed = true AND ClosedDate >= ' + formattedDate + ' AND RecordType.Name <> \'Known Issue\') OR (isClosed = false AND RecordType.Name = \'Known Issue\')) '
                + 'AND recordTypeId in :stRecordTypes';
        id batchinstanceid = database.executeBatch(new CaseUpdateBatch(casesQuery), 100);
    }
}