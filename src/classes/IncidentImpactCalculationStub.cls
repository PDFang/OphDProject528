public with sharing class IncidentImpactCalculationStub implements IncidentImpactCalculationInterface
{
    public Double IncidentIdentityScore { get; set;}
    public Double IncidentPriorityScore {get; set;}
    public Double SecurityIssueScore { get; set;}
    public Double RelatedKnownIssueScore { get; set;}
    public Double RepeatIssueScore { get; set;}


    public Double CalculateIncidentSeverityScore(String severity, Double multiplier)
    {
        return this.IncidentIdentityScore;
    }

    public Double CalculateIncidentPriorityScore(String priority, Double multiplier)
    {
        return this.IncidentPriorityScore;
    }

    public Double CalculateSecurityIssueScore(String securityIssue, Double multiplier)
    {
        return this.SecurityIssueScore;
    }

    public Double CalculateRelatedKnownIssueScore(String knownIssue, Double multiplier)
    {
        return this.RelatedKnownIssueScore;
    }

    public Double CalculateRepeatIssueScore(String repeatIssue, Double multiplier)
    {
        return this.RepeatIssueScore;
    }
}