/**
 * Created by mohandaas.rangaswamy on 11/29/2017.
 */
global class ProjectRollupSchedulable implements Schedulable, Database.Batchable<sObject>{

    final Set<String> projectRecordTypes = new Set<String>{
            'PS Parent Project - SaaS',
            'PS Parent Project - Premise'
    };

    public Integer batchSize;
    public String query;

    public ProjectRollupSchedulable(Integer recordsPerBatch){

        batchSize = recordsPerBatch;
        query = 'Select Id from Project__c';

    }

    public ProjectRollupSchedulable(String optionalQuery, Integer recordsPerBatch){

        query = optionalQuery;
        batchSize = recordsPerBatch;

    }

    global void execute(SchedulableContext param1){

        Id batchJobId = Database.executeBatch(this, this.batchSize);
        system.debug('**** execute(): ProjectRollupSchedulable - ' + batchJobId);

    }

    global Database.QueryLocator start(Database.BatchableContext bc){

        Schema.DescribeSObjectResult projObjectResult = Schema.SObjectType.Project__c;
        Map<String, Schema.RecordTypeInfo> projRecordTypeInfosByName = projObjectResult.getRecordTypeInfosByName();

        Set<Id> recordTypeIds = new Set<Id>();
        for(String recordType :projectRecordTypes){
            recordTypeIds.add(projRecordTypeInfosByName.get(recordType).getRecordTypeId());
        }

        if(query.indexOfIgnoreCase('where') > 0){
            query += ' and';
        } else{
            query += ' where';
        }
        query += ' RecordTypeId IN :recordTypeIds';

        return Database.getQueryLocator(query);

    }

    global void execute(Database.BatchableContext param1, List<Project__c> scope){

        Set<Id> projectIdSet = new Set<Id>();

        for(Project__c proj : scope){
            projectIdSet.add(proj.Id);
        }

        if(projectIdSet.size() > 0){
            Id projectRollupQueueableJobID = System.enqueueJob(new ProjectRollupQueueable(projectIdSet));
            system.debug('**** execute(): projectRollupQueueableJobID - ' + projectRollupQueueableJobID);

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
        message.setSubject('ProjectRollupSchedulable batch job has completed');

        string messageBody = ' The batch Apex job processed ' + a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures. \n\n';

        message.setPlainTextBody(messageBody);

        try{
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { message });
        }catch(system.EmailException ex){
            system.debug(ex);
        }

    }

}