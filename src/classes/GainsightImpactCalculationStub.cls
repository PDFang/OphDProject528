public with sharing class GainsightImpactCalculationStub implements GainsightImpactCalculationInterface
{
    //test values
    public Double OutstandingIncidentCaseScore { get; set; }
    public Double IncidentsOpenedLastSixMonthsScore { get; set; }
    public Double MttrIncidentScore { get; set; }
    public Double AnnualContractValueScore { get; set; }
    public Double CreditGivenLastTwelveMonthsScore { get; set; }
    public Double HealthScore { get; set; }

    public Double CalculateOutstandingIncidentCaseScore(Integer openCaseCount, Double multiplier)
    {
        return OutstandingIncidentCaseScore;
    }

    public Double CalculateIncidentsOpenedLastSixMonthsScore(Integer openIssueCount, Double multiplier)
    {
        return IncidentsOpenedLastSixMonthsScore;
    }

    public Double CalculateMttrIncidentScore(Integer openIssueCount, Double multiplier)
    {
        return MttrIncidentScore;
    }

    public Double CalculateAnnualContractValueScore(Decimal annualContractValue, Double multiplier)
    {
        return AnnualContractValueScore;
    }

    public Double CalculateCreditGivenLastTwelveMonths(Decimal creditGiven, Double multiplier)
    {
        return CreditGivenLastTwelveMonthsScore;
    }

    public Double CalculateHealthScore(Integer healthScore, Double multiplier)
    {
        return HealthScore;
    }
}