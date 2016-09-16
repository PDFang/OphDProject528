global class CaseWorkflowScheduler implements Schedulable
{
 
	global void execute(SchedulableContext ctx)
    {
        string incidentQuery = 'select ID, Status, Disposition__c, WaitingOnCustomerProcessFlag__c, ResolvedProcessFlag__c, SystemClosed__c FROM Case WHERE (Status = \'Waiting On Customer\' OR Status = \'Resolved\') AND StopAutoNotificationClose__c = false AND (RecordType.Name = \'Incident\')';
  		id batchinstanceid = database.executeBatch(new CaseWorkflowBatch(incidentQuery), 1);
        
        //string uptivityIncidentQuery = 'select ID, Status, Disposition__c, WaitingOnCustomerProcessFlag__c, ResolvedProcessFlag__c, SystemClosed__c FROM Case WHERE (Status = \'Waiting On Customer\' OR Status = \'Resolved\') AND StopAutoNotificationClose__c = false AND RecordType.Name = \'Incident - Uptivity\'';
  		//id uptivityBatchinstanceid = database.executeBatch(new CaseWorkflowBatch(uptivityIncidentQuery), 1);
        
        string csServiceRequestQuery = 'select ID, Status, Disposition__c, WaitingOnCustomerProcessFlag__c, ResolvedProcessFlag__c, SystemClosed__c FROM Case WHERE (Status = \'Waiting On Customer\' OR Status = \'Resolved\') AND StopAutoNotificationClose__c = false AND (RecordType.Name = \'Service Request\' OR RecordType.Name = \'Work Orders\')';
		id csBatchinstanceid = database.executeBatch(new CaseWorkflowBatch(csServiceRequestQuery), 1);
    }
}