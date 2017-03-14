public with sharing class ImpactCalculationService
{
    private ImpactCalculationInterface impactCalculator;
    private Map<String, Impact_Score_Multiplier__c> multiplierMap;

    public ImpactCalculationService(ImpactCalculationInterface impactCalculator)
    {
        //store the impactCalculator and the multiplier map for this.
        this.impactCalculator = impactCalculator;
        this.multiplierMap = Impact_Score_Multiplier__c.getAll();
    }

    public void CalculateIncidentNetScore(Case[] caseList)
    {
        for(Case caseRecord : caseList)
        {
            //calculate the net score

            Double netScore = impactCalculator.CalculateIncidentSeverityScore(caseRecord.Severity__c, GetMultiplierValue('severity'));
            netScore += impactCalculator.CalculatePercentBusinessImpactedScore(caseRecord.Business_Impacted__c, GetMultiplierValue('business impacted'));
            netScore += impactCalculator.CalculateWorkaroundAvailablePointsScore(caseRecord.Workaround_Available__c, GetMultiplierValue('workaround'));
            netScore += impactCalculator.CalculateWorkaroundQualityPointsScore(caseRecord.Quality_of_Workaround__c, GetMultiplierValue('workaround quality'));
            netScore += impactCalculator.CalculateSecurityIssueScore(caseRecord.Security_Issue__c, GetMultiplierValue('is security issue'));
            netScore += impactCalculator.CalculateRelatedKnownIssueScore(caseRecord.Related_to_Previous_Known_Issue__c, GetMultiplierValue('is known issue'));

            //store the net score
            caseRecord.Incident_Net_Score__c = netScore;
            system.debug('setting Incident_Net_Score__c to ' + netScore);
        }
    }

    private Double GetMultiplierValue(String key)
    {
        //if the key doesn't exist, return 1 as the multiplier.
        if(multiplierMap.containsKey(key))
        {
            return multiplierMap.get(key).Multiplier__c;
        }
        else
        {
            return 1;
        }
    }
}