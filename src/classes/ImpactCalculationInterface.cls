public interface ImpactCalculationInterface
{
    // Incident Related Methods
    Double CalculateIncidentSeverityScore(String severity, Double multiplier);
    Double CalculatePercentBusinessImpactedScore(String input, Double multiplier);
    Double CalculateWorkaroundAvailablePointsScore(String workAround, Double multiplier);
    Double CalculateWorkaroundQualityPointsScore(String quality, Double multiplier);
    Double CalculateSecurityIssueScore(String securityIssue, Double multiplier);
    Double CalculateRelatedKnownIssueScore(String knownIssue, Double multiplier);

}