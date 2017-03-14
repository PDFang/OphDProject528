public interface ImpactCalculationInterface
{
    Double CalculateIncidentSeverityScore(String severity, Double multiplier);
    Double CalculatePercentBusinessImpactedScore(Decimal input, Double multiplier);
    Double CalculateWorkaroundAvailablePointsScore(String workAround, Double multiplier);
    Double CalculateWorkaroundQualityPointsScore(String quality, Double multiplier);
    Double CalculateSecurityIssueScore(String securityIssue, Double multiplier);
    Double CalculateRelatedKnownIssueScore(String knownIssue, Double multiplier);
}