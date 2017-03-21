/**
 * Created by mohandaas.rangaswamy on 3/20/2017.
 */

global class AccountImpactCalculationBatchScheduler implements Schedulable{

    global void execute(SchedulableContext sc) {
        AccountImpactCalculationBatch batchable = new AccountImpactCalculationBatch();
        database.executebatch(new AccountImpactCalculationBatch());
    }

}