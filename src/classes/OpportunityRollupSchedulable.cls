/**
 * Created by mohandaas.rangaswamy on 11/30/2017.
 */

global class OpportunityRollupSchedulable implements Schedulable, Database.Batchable<sObject>{

    final Set<String> opportunityRecordTypes = new Set<String>{
            'PM-Standard',
            'Qualified Opportunity'
    };

    public Integer batchSize;
    public String query;

    public OpportunityRollupSchedulable(Integer recordsPerBatch){

        batchSize = recordsPerBatch;
        query = 'Select Id from Opportunity';

    }

    public OpportunityRollupSchedulable(String optionalQuery, Integer recordsPerBatch){

        query = optionalQuery;
        batchSize = recordsPerBatch;

    }

    global void execute(SchedulableContext sc){

        Id batchJobId = Database.executeBatch(this, this.batchSize);
        system.debug('**** execute(): OpportunityRollupSchedulable - ' + batchJobId);

    }

    global Database.QueryLocator start(Database.BatchableContext bc){

        Schema.DescribeSObjectResult oppObjectResult = Schema.SObjectType.Opportunity;
        Map<String, Schema.RecordTypeInfo> oppRecordTypeInfosByName = oppObjectResult.getRecordTypeInfosByName();

        Set<Id> recordTypeIds = new Set<Id>();
        for(String recordType :opportunityRecordTypes){
            recordTypeIds.add(oppRecordTypeInfosByName.get(recordType).getRecordTypeId());
        }

        if(query.indexOfIgnoreCase('where') > 0){
            query += ' and';
        } else{
            query += ' where';
        }
        query += ' RecordTypeId IN :recordTypeIds';


        return Database.getQueryLocator(query);

    }

    global void execute(Database.BatchableContext param1, List<Opportunity> scope){

        Set<Id> opportunityIdSet = new Set<Id>();

        for(Opportunity opp : scope){
            opportunityIdSet.add(opp.Id);
        }

        if(opportunityIdSet.size() > 0){
            Id opportunityRollupQueueableJobID = System.enqueueJob(new OpportunityRollupQueueable(opportunityIdSet));
            system.debug('**** execute(): opportunityRollupQueueableJobID - ' + opportunityRollupQueueableJobID);

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
        message.setSubject('OpportunityRollupSchedulable batch job has completed');

        string messageBody = ' The batch Apex job processed ' + a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures. \n\n';

        message.setPlainTextBody(messageBody);

        try{
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { message });
        }catch(system.EmailException ex){
            system.debug(ex);
        }

    }

}        