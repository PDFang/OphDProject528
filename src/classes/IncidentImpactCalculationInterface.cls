public interface IncidentImpactCalculationInterface {
    Double CalculateIncidentSeverityScore(String severity, Double multiplier);
    Double CalculateIncidentPriorityScore(String priority, Double multiplier);
    Double CalculateSecurityIssueScore(String securityIssue, Double multiplier);
    Double CalculateRelatedKnownIssueScore(String knownIssue, Double multiplier);
    Double CalculateRepeatIssueScore(String repeatIssue, Double multiplier);
}