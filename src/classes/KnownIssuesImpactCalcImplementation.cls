/**
 * Created by arnab.karsarkar on 3/15/2017.
 */

public with sharing class KnownIssuesImpactCalcImplementation implements KnownIssuesImpactCalculationInterface{

    // Number of incidents tied to Known Issue
    public Decimal CalculateNumberIncidentsTiedToIssue(integer issueCount,  decimal multiplier) {
        //>10=10, 7-9=7, 4-6=4, 1-3=1, 0=0
        if (issueCount <  6 )
            return 1 * multiplier;
        else if (issueCount <  11 )
            return 2 * multiplier;
        else
            return 3 * multiplier;

    }

    //
    public Decimal CalculateDaysIssuePresent(integer numOfDays, decimal multiplier){
        //>10=10, 7-9=7, 4-6=4, 1-3=0.25, 1=0
        if (numOfDays <  14 )
            return 1 * multiplier;
        else if (numOfDays <  30 )
            return 2 * multiplier;
        else
            return 3 * multiplier;
    }

    //not done
    public Decimal CalculatePriorityScore(string priority,  decimal multiplier) {
        //>=$5M=10, $3M-$5M=7, $2M-$3M=4, $1M-$2M=1, <=$0=0.00


        system.debug('Priority: ' + priority + ' Multiplier: ' + multiplier);
        if (priority == 'p1' )
            return 1 * multiplier;
        else if (priority == 'p2')
            return .5 * multiplier;
        else
            return 0;
    }

    public Decimal CalculateRecentReleaseBreak(boolean isRecentRelease, decimal multiplier){
        //Yes=10, No=0
        if(isRecentRelease)
            return 1 * multiplier;
        else
                return 0;
    }

    public Decimal CalculateSecurityIssue(boolean securityIssue,  decimal multiplier) {
        //>=$5M=10, $3M-$5M=7, $2M-$3M=4, $1M-$2M=1, <=$0=0.00

        if (securityIssue)
            return 1 * multiplier;
        else
                return 0;
    }
}