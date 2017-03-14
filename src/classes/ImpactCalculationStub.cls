public with sharing class ImpactCalculationStub implements ImpactCalculationInterface
{
    public Double CalculateIncidentSeverityScore(String severity, Double multiplier)
    {
        return 1;
    }

    public Double CalculatePercentBusinessImpactedScore(Decimal input, Double multiplier)
    {
        return 1;
    }

    public Double CalculateWorkaroundAvailablePointsScore(Boolean hasWorkaround, Double multiplier)
    {
        return 1;
    }

    public Double CalculateWorkaroundQualityPointsScore(String quality, Double multiplier)
    {
        return 1;
    }

    public Double CalculateSecurityIssueScore(Boolean isSecurityIssue, Double multiplier)
    {
        return 1;
    }

    public Double CalculateRelatedKnownIssueScore(Boolean isKnownIssue, Double multiplier)
    {
        return 1;
    }
}