/**
 * Created by mohandaas.rangaswamy on 2/24/2017.
 */

global class DevelopmentReviewTestResults implements Schedulable {

    Id asyncJobId;

    global DevelopmentReviewTestResults(Id asyncJobId) {
        this.asyncJobId = asyncJobId;
    }

    global void execute(SchedulableContext sc) {

        ApexTestResult[] result = [
                Select ApexTestRunResultId, AsyncApexJobId, Outcome, Message, MethodName, ApexClass.Name
                from ApexTestResult
                where AsyncApexJobId = :asyncJobId
        ];

        ApexTestRunResult summary = [
                Select AsyncApexJobId, ClassesCompleted, MethodsCompleted, MethodsFailed,
                        StartTime, Status, UserId, TestTime
                from ApexTestRunResult
                where AsyncApexJobId = :asyncJobId
        ];


    }

}