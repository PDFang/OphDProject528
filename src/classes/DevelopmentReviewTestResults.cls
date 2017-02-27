/**
 * Created by mohandaas.rangaswamy on 2/24/2017.
 */

global class DevelopmentReviewTestResults implements Schedulable {

    Id asyncJobId;

    static final Integer INTERVAL = 15;

    global DevelopmentReviewTestResults(Id asyncJobId) {
        this.asyncJobId = asyncJobId;
    }

    global void execute(SchedulableContext sc) {

//        ApexTestResult[] result = [
//                Select ApexTestRunResultId, AsyncApexJobId, Outcome, Message, MethodName, ApexClass.Name
//                from ApexTestResult
//                where AsyncApexJobId = :asyncJobId
//        ];

        ApexTestRunResult testRun = [
                Select AsyncApexJobId, ClassesCompleted, MethodsCompleted, MethodsFailed,
                        StartTime, Status, UserId, TestTime
                from ApexTestRunResult
                where AsyncApexJobId = :asyncJobId
        ];
        system.debug('execute(): testRun - ' + testRun);

        if(testRun.Status == 'Queued' || testRun.status == 'Processing'){
            Datetime nextRun = system.now().addMinutes(INTERVAL);
            String dateTimeFormat = '0 {0} {1} {2} {3} ? {4}';
            String scheduledTime = string.format(
                    dateTimeFormat,
                    new String[]{
                            nextRun.minute().format(),
                            nextRun.hour().format(),
                            nextRun.day().format(),
                            nextRun.month().format(),
                            nextRun.year().format()
                    }
            );
            String scheduledJobId = system.schedule('Apex Test Results Emailer', scheduledTime, new DevelopmentReviewTestResults(asyncJobId));
            system.debug('execute(): scheduledJobId - ' + scheduledJobId);
        }

    }

}