public with sharing class ImpactCalculationStub implements ImpactCalculationInterface
{
    public Double IncidentIdentityScore { get; set;}
    public Double PercentBusinessImpactScore { get; set;}
    public Double WorkaroundAvailablePoints { get; set;}
    public Double WorkaroundQualityPointsScore { get; set;}
    public Double SecurityIssueScore { get; set;}
    public Double RelatedKnownIssueScore { get; set;}


    public Double CalculateIncidentSeverityScore(String severity, Double multiplier)
    {
        return this.IncidentIdentityScore;
    }

    public Double CalculatePercentBusinessImpactedScore(String input, Double multiplier)
    {
        return this.PercentBusinessImpactScore;
    }

    public Double CalculateWorkaroundAvailablePointsScore(String workAround, Double multiplier)
    {
        return this.WorkaroundAvailablePoints;
    }

    public Double CalculateWorkaroundQualityPointsScore(String quality, Double multiplier)
    {
        return this.WorkaroundQualityPointsScore;
    }

    public Double CalculateSecurityIssueScore(String securityIssue, Double multiplier)
    {
        return this.SecurityIssueScore;
    }

    public Double CalculateRelatedKnownIssueScore(String knownIssue, Double multiplier)
    {
        return this.RelatedKnownIssueScore;
    }
}