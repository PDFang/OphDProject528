public with sharing class IncidentImpactCalculationImplementation implements IncidentImpactCalculationInterface
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
        } else if (severity == 's3')
        {
            score = 0.25;
        } else
        {
            score = 0;
        }

        return score * multiplier;
    }

    public Double CalculateIncidentPriorityScore(String priority, Double multiplier)
    {
        Double score;

        if (priority == 'p1')
        {
            score = 1;
        } else if (priority == 'p2')
        {
            score = 0.5;
        } else if (priority == 'p3')
        {
            score = 0.25;
        } else
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



    public Double CalculateRepeatIssueScore(String repeatIssue, Double multiplier)
    {
        Double score;
        if(repeatIssue == 'yes')
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