/**
 * Created by mohandaas.rangaswamy on 12/7/2017.
 */

global class AssetRollupSchedulable implements Schedulable, Database.Batchable<sObject>{

    private Integer batchSize = 200;
    private String query;
    Set<Id> assetIds;

    public AssetRollupSchedulable(Integer recordsPerBatch){

        batchSize = recordsPerBatch;
        query = 'Select Id from Asset';

    }

    public AssetRollupSchedulable(Set<Id> assetIdSet){

        assetIds = assetIdSet;
        query = 'Select Id from Asset where Id IN :assetIds';

    }

    public AssetRollupSchedulable(String optionalQuery, Integer recordsPerBatch){

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

    global void execute(Database.BatchableContext param1, List<Asset> scope){

        Set<Id> assetIdSet = new Set<Id>();

        for(Asset ass : scope){
            assetIdSet.add(ass.Id);
        }

        if(assetIdSet.size() > 0){
            Id assetRollupQueueableJobID = System.enqueueJob(new AssetRollupQueueable(assetIdSet));
            system.debug('**** execute(): assetRollupQueueableJobID - ' + assetRollupQueueableJobID);

        }

    }

    global void finish(Database.BatchableContext bc){

        Profile userProfile = [Select Name from Profile where Id = :userinfo.getProfileId()];

        if(userProfile.Name.containsIgnoreCase('System Administrator') == false){
            return;
        }

        AsyncApexJob a = [
                SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
                        TotalJobItems, CreatedBy.Email
                FROM AsyncApexJob WHERE Id = :bc.getJobId()
        ];

        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] { a.CreatedBy.Email };
        message.setToAddresses(toAddresses);
        message.setSubject('AssetRollupSchedulable batch job has completed');

        string messageBody = ' The batch Apex job processed ' + a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures. \n\n';

        message.setPlainTextBody(messageBody);

        try{
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { message });
        }catch(system.EmailException ex){
            system.debug(ex);
        }

    }

}