public with sharing class ImpactCalculationImplementation implements ImpactCalculationInterface
{
    public Double CalculateIncidentSeverityScore(String severity, Double multiplier)
    {
        Double score;

        if (severity == 's1')
        {
            score = 1;
        } else if (severity == 's2')
        {
            score = 0.5;
        } else
        {
            score = 0;
        }

        return score * multiplier;
    }

    public Double CalculatePercentBusinessImpactedScore(String input, Double multiplier)
    {
        Double score;
        if(input == '>75%')
        {
            score = 1;
        }
        else if(input == '50-75%')
        {
            score = 0.75;
        }
        else if(input == '25-50%')
        {
            score = .5;
        }
        else
        {
            score = 0;
        }

        return score * multiplier;
    }

    public Double CalculateWorkaroundAvailablePointsScore(String workAround, Double multiplier)
    {
        Double score;

        if(workAround == 'yes')
        {
            score = 0;
        }
        else
        {
            score = 1;
        }

        return score * multiplier;
    }

    public Double CalculateWorkaroundQualityPointsScore(String quality, Double multiplier)
    {
        Double score;

        if(quality == 'low')
        {
            score = 1;
        }
        else if(quality == 'medium')
        {
            score = 0.5;
        }
        else
        {
            score = 0;
        }

        return score * multiplier;
    }

    public Double CalculateSecurityIssueScore(String securityIssue, Double multiplier)
    {
        Double score;

        if(securityIssue == 'yes')
        {
            score = 1;
        }
        else
        {
            score = 0;
        }

        return score * multiplier;
    }

    public Double CalculateRelatedKnownIssueScore(String knownIssue, Double multiplier)
    {
        Double score;
        if(knownIssue == 'yes')
        {
            score = 1;
        }
        else
        {
            score = 0;
        }

        return score * multiplier;
    }

    //using decimal return type for now
    public Decimal CalculateDaysIssuePresent(DateTime oldestDate, integer multiplier){

        //>10=10, 7-9=7, 4-6=4, 1-3=0.25, 1=0
        DateTime startDate = DateTime.now();
        integer intDays =  startDate.Date().daysBetween(oldestDate.Date());
        if (intDays ==  1 )
            return 0 ;
        else if (intDays <  4 )
            return .25 * multiplier;
        else if (intDays <  7 )
            return 4 * multiplier;
        else if (intDays <  10 )
            return 7 * multiplier;
        else
                return 10 * multiplier;
    }

    // Number of incidents tied to Known Issue
    public Decimal CalculateNumberIncidentsTiedToIssue(integer issueCount,  integer multiplier) {
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
    public Decimal CalculateDaysIssuePresent(integer numOfDays, integer multiplier){
        //>10=10, 7-9=7, 4-6=4, 1-3=0.25, 1=0
        if (numOfDays ==  1)
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
    public Decimal CalculateDollarAmountTiedToIssue(decimal accountSum,  integer multiplier) {
        //>=$5M=10, $3M-$5M=7, $2M-$3M=4, $1M-$2M=1, <=$0=0.00
        if (accountSum ==  0 )
             return 0 ;
        else if (accountSum <  4 )
             return 1 * multiplier;
         else if (accountSum <  7 )
             return 4 * multiplier;
         else if (accountSum <  10 )
             return 7 * multiplier;
         else
             return 10 * multiplier;
    }

    public Decimal CalculateRecentReleaseBreak(boolean isRecentRelease, integer multiplier){
        //Yes=10, No=0
        if(isRecentRelease)
            return 10 * multiplier;
        else
            return 0;
    }
}