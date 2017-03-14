public interface ImpactCalculationInterface
{
    Double CalculateIncidentSeverityScore(String severity, Double multiplier);
    Double CalculatePercentBusinessImpactedScore(Decimal input, Double multiplier);
    Double CalculateWorkaroundAvailablePointsScore(Boolean hasWorkaround, Double multiplier);
    Double CalculateWorkaroundQualityPointsScore(String quality, Double multiplier);
    Double CalculateSecurityIssueScore(Boolean isSecurityIssue, Double multiplier);
    Double CalculateRelatedKnownIssueScore(Boolean isKnownIssue, Double multiplier);
}