/**
 * Created by arnab.karsarkar on 3/15/2017.
 */

public with sharing class KnownIssueImpactCalculationClass {

    private ImpactCalculationInterface impactCalculator;
    private Map<String, Impact_Score_Multiplier__c> multiplierMap;

    public KnownIssueImpactCalculationClass(ImpactCalculationInterface impactCalculator)
    {
        //store the impactCalculator and the multiplier map for this.
        this.impactCalculator = impactCalculator;
        this.multiplierMap = Impact_Score_Multiplier__c.getAll();
    }

    public void CalculateKnownIssueScore(list<Case> knownIssueList){
        


    }


}