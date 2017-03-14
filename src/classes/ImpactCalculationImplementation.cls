public with sharing class ImpactCalculationImplementation implements ImpactCalculationInterface
{
    public Double CalculateIncidentSeverityScore(String severity, Double multiplier)
    {
        Double score;
        severity = severity.toLowerCase();
        if(severity == 'p1')
        {
            score = 1;
        }
        else if(severity == 'p2')
        {
            score = 0.5;
        }
        else
        {
            score = 0;
        }

        return score * multiplier;
    }

    public Double CalculatePercentBusinessImpactedScore(Decimal input, Double multiplier)
    {
        Double score;
        if(input >= 0.75)
        {
            score = 1;
        }
        else if(input >= 0.5)
        {
            score = 0.75;
        }
        else if(input >= 0.25)
        {
            score = .5;
        }
        else
        {
            score = 0;
        }

        return score * multiplier;
    }

    public Double CalculateWorkaroundAvailablePointsScore(Boolean hasWorkaround, Double multiplier)
    {
        Double score;
        if(hasWorkaround)
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
        quality = quality.toLowerCase();
        if(quality == 'low')
        {
            score = 1;
        }
        else if(quality = 'medium')
        {
            score = 0.5;
        }
        else
        {
            score = 0;
        }
        return score * multiplier;
    }

    public Double CalculateSecurityIssueScore(Boolean isSecurityIssue, Double multiplier)
    {
        Double score;
        if(isSecurityIssue)
        {
            score = 1;
        }
        else
        {
            score = 0;
        }
        return score * multiplier;
    }

    public Double CalculateRelatedKnownIssueScore(Boolean isKnownIssue, Double multiplier)
    {
        Double score;
        if(isKnownIssue)
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