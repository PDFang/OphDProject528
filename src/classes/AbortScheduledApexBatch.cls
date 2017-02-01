/**
 * Created by mohandaas.rangaswamy on 12/23/2016.
 */
// Abort scheduled apex jobs
global class AbortScheduledApexBatch implements Database.Batchable<sObject> {

    global Database.QueryLocator start(Database.BatchableContext context)
    {
        String soql = 'SELECT Id FROM CronTrigger WHERE CronJobDetail.JobType = \'7\' ';
        if(Test.isRunningTest())
            soql += 'LIMIT 100 ';
        return Database.getQueryLocator(soql);
    }

    global void execute(Database.BatchableContext context, List<CronTrigger> scope)
    {
        for(CronTrigger c : scope){
            System.abortJob(c.Id);
        }
    }

    global void finish(Database.BatchableContext context)
    {
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
                TotalJobItems, CreatedBy.Email
                FROM AsyncApexJob WHERE Id = :context.getJobId()];
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] { a.CreatedBy.Email };
        message.setToAddresses(toAddresses);
        message.setSubject('DeleteScheduledApex has completed');

        string messageBody = 'The DeleteScheduledApex process has completed.';

        messageBody = messageBody + ' The batch Apex job processed ' + a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures.';
        message.setPlainTextBody(messageBody);
        try{
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { message });
        }catch(system.EmailException ex){
            system.debug(ex);
        }
    }

}