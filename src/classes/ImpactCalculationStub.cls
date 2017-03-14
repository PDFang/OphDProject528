public with sharing class ImpactCalculationStub implements ImpactCalculationInterface
{
    public Double CalculateIncidentSeverityScore(String severity, Double multiplier)
    {
        return 1;
    }

    public Double CalculatePercentBusinessImpactedScore(String input, Double multiplier)
    {
        return 1;
    }

    public Double CalculateWorkaroundAvailablePointsScore(String workAround, Double multiplier)
    {
        return 1;
    }

    public Double CalculateWorkaroundQualityPointsScore(String quality, Double multiplier)
    {
        return 1;
    }

    public Double CalculateSecurityIssueScore(String securityIssue, Double multiplier)
    {
        return 1;
    }

    public Double CalculateRelatedKnownIssueScore(String knownIssue, Double multiplier)
    {
        return 1;
    }
}