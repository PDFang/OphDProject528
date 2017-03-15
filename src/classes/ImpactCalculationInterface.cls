public interface ImpactCalculationInterface
{
    // Incident Related Methods
    Double CalculateIncidentSeverityScore(String severity, Double multiplier);
    Double CalculatePercentBusinessImpactedScore(String input, Double multiplier);
    Double CalculateWorkaroundAvailablePointsScore(String workAround, Double multiplier);
    Double CalculateWorkaroundQualityPointsScore(String quality, Double multiplier);
    Double CalculateSecurityIssueScore(String securityIssue, Double multiplier);
    Double CalculateRelatedKnownIssueScore(String knownIssue, Double multiplier);

    // Gainsight Related Methods
    Double CalculateOutstandingIncidentCaseScore(Integer openedCases, Double multiplier);
    Double CalculateIncidentOpenedLastSixMonthScore(Integer openedCases, Double multiplier);
    Double CalculateMttrIncidentCaseScore(Integer numberOfWeeks, Double multiplier);
    Double CalculateAnnualContractValueScore(Decimal contractDollarAmount, Double multiplier);
    Double CalculateCreditGivenScore(Decimal creditDollarAmount, Double multiplier);
    Double CalculateHealthScore(String currentScore, Double multiplier);

    // Known Issue related Methods
    Decimal CalculateDaysIssuePresent(DateTime oldestDate, integer multiplier);
    Decimal CalculateNumberIncidentsTiedToIssue (integer issueCount,  integer multiplier);
    Decimal CalculateDollarAmountTiedToIssue(decimal accountSum,  integer multiplier);
}