/**
 * Created by arnab.karsarkar on 9/14/2017.
 */

global class LMAEDAOrderBatchScheduler implements Schedulable{

	global void execute(SchedulableContext ctx){
		id batchinstanceid = database.executeBatch(new LMAEDAOrderBatch(), 1);
	}

}