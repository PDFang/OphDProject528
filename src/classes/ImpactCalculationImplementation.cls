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


}