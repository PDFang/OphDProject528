/**
 * Created by mohandaas.rangaswamy on 12/23/2016.
 */

global class DeleteScheduledApex implements Database.Batchable<sObject> {

    global Database.QueryLocator start(Database.BatchableContext context)
    {
        return Database.getQueryLocator('SELECT Id FROM CronTrigger WHERE CronJobDetail.JobType = \'7\'');
    }

    global void execute(Database.BatchableContext context, List<Contact> scope)
    {
        Database.delete(scope, false);
    }

    global void finish(Database.BatchableContext context)
    {
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] { System.LABEL.DEVErrorEmailRecipient };
        message.setToAddresses(toAddresses);
        message.setSubject('DeleteScheduledApex has completed');

        string messageBody = 'The DeleteScheduledApex process has completed';
        message.setPlainTextBody(messageBody);

        try{
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { message });
        }catch(system.EmailException ex){
            system.debug(ex);
        }
    }

}