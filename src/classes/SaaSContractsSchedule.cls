global class SaaSContractsSchedule Implements Schedulable {
    public static String CRON_EXP = '0 0 0 1 * ?';
    
    global void execute(SchedulableContext sc) {
        doWork();     
    }
    public void doWork() {
        
        // We now call the batch class to be scheduled
        SaaSContractBatchApex scba = new SaaSContractBatchApex ();
        
        //Parameters of ExecuteBatch(context,BatchSize)
        database.executebatch(scba,1);
        
    }
}