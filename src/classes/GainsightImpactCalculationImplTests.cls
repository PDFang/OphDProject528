@isTest
public with sharing class GainsightImpactCalculationImplTests
{
    static testMethod void CalculateOutstandingIncidentCaseScore_ReturnsCorrectScore()
    {
        GainsightImpactCalculationImpl imp = new GainsightImpactCalculationImpl();
        Double multiplier = 1;
        Double scoreOne = imp.CalculateOutstandingIncidentCaseScore(6, multiplier);
        Double scoreTwo = imp.CalculateOutstandingIncidentCaseScore(4, multiplier);
    }
}