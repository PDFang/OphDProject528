public with sharing class GainsightImpactCalculationStub implements GainsightImpactCalculationInterface
{
    //test values
    public Double MrrValueScore { get; set; }
    public Double CreditGivenLastTwelveMonthsScore { get; set; }
    public Double HealthScore { get; set; }


    public Double CalculateMRRScore(Decimal mrrValue, Double multiplier)
    {
        return MrrValueScore;
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