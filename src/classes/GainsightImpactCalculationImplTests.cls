@isTest
public with sharing class GainsightImpactCalculationImplTests
{
    static testMethod void CalculateOutstandingIncidentCaseScore_ReturnsCorrectScore() {
        GainsightImpactCalculationImpl imp = new GainsightImpactCalculationImpl();

        Double caseOne = imp.CalculateOutstandingIncidentCaseScore(6, 2);
        Double caseTwo = imp.CalculateOutstandingIncidentCaseScore(4, 2);
        Double caseThree = imp.CalculateOutstandingIncidentCaseScore(2, 1);
        Double caseFour = imp.CalculateOutstandingIncidentCaseScore(1, 1);
        Double caseFive = imp.CalculateOutstandingIncidentCaseScore(0, 1);

        system.assertEquals(2, caseOne);
        system.assertEquals(1.5, caseTwo);
        system.assertEquals(.5, caseThree);
        system.assertEquals(.25, caseFour);
        system.assertEquals(0, caseFive);
    }

    static testMethod void CalculateIncidentsOpenedLastSixMonthsScore_ReturnsCorrectScore() {
        GainsightImpactCalculationImpl imp = new GainsightImpactCalculationImpl();

        Double caseOne = imp.CalculateIncidentsOpenedLastSixMonthsScore(50, 2);
        Double caseTwo = imp.CalculateIncidentsOpenedLastSixMonthsScore(25, 2);
        Double caseThree = imp.CalculateIncidentsOpenedLastSixMonthsScore(20, 1);
        Double caseFour = imp.CalculateIncidentsOpenedLastSixMonthsScore(15, 1);
        Double caseFive = imp.CalculateIncidentsOpenedLastSixMonthsScore(14, 1);

        system.assertEquals(2, caseOne);
        system.assertEquals(1.5, caseTwo);
        system.assertEquals(.5, caseThree);
        system.assertEquals(.25, caseFour);
        system.assertEquals(0, caseFive);
    }

    static testMethod void CalculateMttrIncidentScore_ReturnsCorrectScore() {
        GainsightImpactCalculationImpl imp = new GainsightImpactCalculationImpl();

        Double caseOne = imp.CalculateMttrIncidentScore(6, 2);
        Double caseTwo = imp.CalculateMttrIncidentScore(4, 2);
        Double caseThree = imp.CalculateMttrIncidentScore(2, 1);
        Double caseFour = imp.CalculateMttrIncidentScore(1, 1);
        Double caseFive = imp.CalculateMttrIncidentScore(0, 1);

        system.assertEquals(2, caseOne);
        system.assertEquals(1.5, caseTwo);
        system.assertEquals(.5, caseThree);
        system.assertEquals(.25, caseFour);
        system.assertEquals(0, caseFive);
    }

    static testMethod void CalculateAnnualContractValueScore_ReturnsCorrectScore() {
        GainsightImpactCalculationImpl imp = new GainsightImpactCalculationImpl();

        Double caseOne = imp.CalculateAnnualContractValueScore(500000, 2);
        Double caseTwo = imp.CalculateAnnualContractValueScore(300000, 2);
        Double caseThree = imp.CalculateAnnualContractValueScore(100000, 1);
        Double caseFour = imp.CalculateAnnualContractValueScore(25000, 1);
        Double caseFive = imp.CalculateAnnualContractValueScore(100, 1);

        system.assertEquals(2, caseOne);
        system.assertEquals(1.5, caseTwo);
        system.assertEquals(.5, caseThree);
        system.assertEquals(.25, caseFour);
        system.assertEquals(0, caseFive);
    }

    static testMethod void CalculateCreditGivenLastTwelveMonths_ReturnsCorrectScore() {
        GainsightImpactCalculationImpl imp = new GainsightImpactCalculationImpl();

        Double caseOne = imp.CalculateCreditGivenLastTwelveMonths(5000, 2);
        Double caseTwo = imp.CalculateCreditGivenLastTwelveMonths(3000, 2);
        Double caseThree = imp.CalculateCreditGivenLastTwelveMonths(2000, 1);
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

        Double caseOne = imp.CalculateHealthScore(75, 2);
        Double caseTwo = imp.CalculateHealthScore(50, 2);
        Double caseThree = imp.CalculateHealthScore(10, 1);

        system.assertEquals(0, caseOne);
        system.assertEquals(1, caseTwo);
        system.assertEquals(1, caseThree);
    }
}