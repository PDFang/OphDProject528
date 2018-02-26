public interface GainsightImpactCalculationInterface {
    /*Double CalculateOutstandingIncidentCaseScore(Integer openCaseCount, Double multiplier);
    Double CalculateIncidentsOpenedLastSixMonthsScore(Integer openIssueCount, Double multiplier);
    Double CalculateMttrIncidentScore(Integer openIssueCount, Double multiplier);
    Double CalculateAnnualContractValueScore(Decimal annualContractValue, Double multiplier);*/
    Double CalculateMRRScore(Decimal mrrValue, Double multiplier);
    Double CalculateCreditGivenLastTwelveMonths(Decimal creditGiven, Double multiplier);
    Double CalculateHealthScore(Integer healthScore, Double multiplier);
}