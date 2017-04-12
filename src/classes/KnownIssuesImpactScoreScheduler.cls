/**
 * Created by arnab.karsarkar on 3/21/2017.
 */

global class KnownIssuesImpactScoreScheduler implements Schedulable {

    global void execute(SchedulableContext ctx)
    {
        string knownIssueQuery = 'select Id,Broken_by_Recent_Release__c,Status,,KIImpactScore__c, Subject from Case '
                + 'WHERE RecordType.Name = \'Known Issue\' '
                + ' AND isClosed = false and Status not in (\'Released - Confirm Resolution\',\'No Fix\')';
        id batchinstanceid = database.executeBatch(new KnownIssuesImpactScoreCalcBatch(knownIssueQuery), 100);
    }

}