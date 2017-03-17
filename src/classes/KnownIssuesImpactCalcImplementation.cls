/**
 * Created by arnab.karsarkar on 3/15/2017.
 */

public with sharing class KnownIssuesImpactCalcImplementation implements KnownIssuesImpactCalculationInterface{

    // Number of incidents tied to Known Issue
    public Decimal CalculateNumberIncidentsTiedToIssue(integer issueCount,  decimal multiplier) {
        //>10=10, 7-9=7, 4-6=4, 1-3=1, 0=0
        if (issueCount ==  0 )
            return 0 ;
        else if (issueCount <  4 )
            return 1 * multiplier;
        else if (issueCount <  7 )
            return 4 * multiplier;
        else if (issueCount <  10 )
            return 7 * multiplier;
        else
                return 10 * multiplier;

    }

    //
    public Decimal CalculateDaysIssuePresent(integer numOfDays, decimal multiplier){
        //>10=10, 7-9=7, 4-6=4, 1-3=0.25, 1=0
        if (numOfDays <=  1)
            return 0 ;
        else if (numOfDays <  4 )
            return 0.25 * multiplier;
        else if (numOfDays <  7 )
            return 4 * multiplier;
        else if (numOfDays <  10 )
            return 7 * multiplier;
        else
                return 10 * multiplier;
    }

    //not done
    public Decimal CalculateDollarAmountTiedToIssue(decimal accountSum,  decimal multiplier) {
        //>=$5M=10, $3M-$5M=7, $2M-$3M=4, $1M-$2M=1, <=$0=0.00
        if (accountSum < 1 )
            return 0 ;
        else if (accountSum <= 2  )
            return 1 * multiplier;
        else if (accountSum <=  3 )
            return 4 * multiplier;
        else if (accountSum <= 5 )
            return 7 * multiplier;
        else
                return 10 * multiplier;
    }

    public Decimal CalculateRecentReleaseBreak(boolean isRecentRelease, decimal multiplier){
        //Yes=10, No=0
        if(isRecentRelease)
            return 10 * multiplier;
        else
                return 0;
    }
}