@isTest
public class ImpactCalculationServiceTests {

    static testMethod void CalculateIncidentNetScore_WillSetScoreCorrectly(){

        Case[] caseList = new Case[]{
                new Case(
                        Severity__c = 's1',
                        Business_Impacted__c = '>75%',
                        Workaround_Available__c = 'yes',
                        Quality_of_Workaround__c = 'medium',
                        Security_Issue__c = 'no',
                        Related_to_Previous_Known_Issue__c = 'no'
                )
        };

        // Set stub methods to always return the same value

        IncidentImpactCalculationStub calculationStub = new IncidentImpactCalculationStub();
        calculationStub.IncidentIdentityScore = 1;
        calculationStub.PercentBusinessImpactScore = 1;
        calculationStub.WorkaroundAvailablePoints = 1;
        calculationStub.WorkaroundQualityPointsScore = 1;
        calculationStub.SecurityIssueScore = 1;
        calculationStub.RelatedKnownIssueScore = 1;

        ImpactCalculationService impactService = new ImpactCalculationService(calculationStub);

        impactService.CalculateIncidentNetScore(caseList);

        for(Case caseRecord : caseList)
        {
            system.assertEquals(6, caseRecord.Incident_Net_Score__c);
        }
    }
}