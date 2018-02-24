@isTest
public with sharing class GainsightImpactCalculationImplTests
{

    static testMethod void CalculateMRRScore_ReturnsCorrectScore() {
        GainsightImpactCalculationImpl imp = new GainsightImpactCalculationImpl();

        Double caseOne = imp.CalculateMRRScore(50000, 2);
        Double caseTwo = imp.CalculateMRRScore(30000, 2);
        Double caseThree = imp.CalculateMRRScore(10000, 1);
        Double caseFour = imp.CalculateMRRScore(3000, 1);
        Double caseFive = imp.CalculateMRRScore(100, 1);

        system.assertEquals(2, caseOne);
        system.assertEquals(1.5, caseTwo);
        system.assertEquals(.5, caseThree);
        system.assertEquals(.25, caseFour);
        system.assertEquals(0, caseFive);
    }

    static testMethod void CalculateCreditGivenLastTwelveMonths_ReturnsCorrectScore() {
        GainsightImpactCalculationImpl imp = new GainsightImpactCalculationImpl();

        Double caseOne = imp.CalculateCreditGivenLastTwelveMonths(5000, 2);
        Double caseTwo = imp.CalculateCreditGivenLastTwelveMonths(3001, 2);
        Double caseThree = imp.CalculateCreditGivenLastTwelveMonths(2001, 1);
        Double caseFour = imp.CalculateCreditGivenLastTwelveMonths(1, 1);
        Double caseFive = imp.CalculateCreditGivenLastTwelveMonths(0, 1);

        system.assertEquals(2, caseOne);
        system.assertEquals(1.5, caseTwo);
        system.assertEquals(.5, caseThree);
        system.assertEquals(.25, caseFour);
        system.assertEquals(0, caseFive);
    }

    static testMethod void CalculateHealthScore_ReturnsCorrectScore() {
        GainsightImpactCalculationImpl imp = new GainsightImpactCalculationImpl();

        Double caseOne = imp.CalculateHealthScore(86, 2);
        Double caseTwo = imp.CalculateHealthScore(67, 2);
        Double caseThree = imp.CalculateHealthScore(10, 1);

        system.assertEquals(0, caseOne);
        system.assertEquals(1, caseTwo);
        system.assertEquals(1, caseThree);
    }
}