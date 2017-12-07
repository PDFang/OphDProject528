/**
 * Created by mohandaas.rangaswamy on 12/7/2017.
 */

global class SubscriptionRollupSchedulable implements Schedulable, Database.Batchable<sObject>{

    public Integer batchSize;
    public String query;

    public SubscriptionRollupSchedulable(Integer recordsPerBatch){

        batchSize = recordsPerBatch;
        query = 'Select Id from SBQQ__Subscription__c';

    }

    public SubscriptionRollupSchedulable(String optionalQuery, Integer recordsPerBatch){

        query = optionalQuery;
        batchSize = recordsPerBatch;

    }

    global void execute(SchedulableContext sc){

        Id batchJobId = Database.executeBatch(this, this.batchSize);
        system.debug('**** execute(): batchJobId - ' + batchJobId);

    }

    global Database.QueryLocator start(Database.BatchableContext bc){

        return Database.getQueryLocator(query);

    }

    global void execute(Database.BatchableContext param1, List<SBQQ__Subscription__c> scope){

        Set<Id> subscriptionIdSet = new Set<Id>();

        for(SBQQ__Subscription__c sub : scope){
            subscriptionIdSet.add(sub.Id);
        }

        if(subscriptionIdSet.size() > 0){
            Id subscriptionRollupQueueableJobID = System.enqueueJob(new SubscriptionRollupQueueable(subscriptionIdSet));
            system.debug('**** execute(): subscriptionRollupQueueableJobID - ' + subscriptionRollupQueueableJobID);

        }

    }

    global void finish(Database.BatchableContext bc){

        AsyncApexJob a = [
                SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
                        TotalJobItems, CreatedBy.Email
                FROM AsyncApexJob WHERE Id = :bc.getJobId()
        ];

        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] { a.CreatedBy.Email };
        message.setToAddresses(toAddresses);
        message.setSubject('SubscriptionRollupSchedulable batch job has completed');

        string messageBody = ' The batch Apex job processed ' + a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures. \n\n';

        message.setPlainTextBody(messageBody);

        try{
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { message });
        }catch(system.EmailException ex){
            system.debug(ex);
        }

    }

}