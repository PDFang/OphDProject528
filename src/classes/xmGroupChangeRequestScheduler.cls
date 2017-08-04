/**
 * Created by arnab.karsarkar on 7/25/2017.
 */

global class xmGroupChangeRequestScheduler implements Schedulable{

    global void execute(SchedulableContext ctx)
    {

        id batchinstanceid = database.executeBatch(new CaseUpdateBatch(casesQuery), 100);
    }

}