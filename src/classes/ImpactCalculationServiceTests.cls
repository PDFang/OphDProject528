@isTest
public class ImpactCalculationServiceTests {

    static testMethod void CalculateIncidentNetScore_WillSetScoreCorrectly() {

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

        for (Case caseRecord : caseList) {
            system.assertEquals(6, caseRecord.Incident_Net_Score__c);
        }
    }

    static testMethod void CalculateAccountScore_WillSetScoreCorrectly() {
        Account[] accountList = new Account[]{
                new Account(
                        Name = 'My little Account',
                        Risk_of_Leaving__c = '3', // 3
                        GYRStatus__c = 'Red',  // 1,
                        CustomerSegment__c = 'Strategic', // 1
                        IsPartner__c = false, //0,
                        Brand_Visibility__c = 'no', // 0,
                        Industry_Leadership_Vocality__c = 'no', // 0
                        Social_Media_Presence__c = 'no', // 0
                        Referenceable__c = true  // 1
                )
        };

        AccountImpactCalculationStub accountImpactCalculationStub = new AccountImpactCalculationStub();
        accountImpactCalculationStub.AgeOfCustomerInMonthsScore = 1;
        accountImpactCalculationStub.RiskOfLeavingScore = 1;
        accountImpactCalculationStub.StrategicAccountScore = 1;
        accountImpactCalculationStub.PartnerAccountScore = 1;
        accountImpactCalculationStub.BrandVisibilityScore = 1;
        accountImpactCalculationStub.IndustryLeaderScore = 1;
        accountImpactCalculationStub.SocialMediaPresenceScore = 1;
        accountImpactCalculationStub.CurrentReferenceScore = 1;
        accountImpactCalculationStub.GRYColor = 1;

        ImpactCalculationService impactService = new ImpactCalculationService(accountImpactCalculationStub);

        impactService.CalculateAccountNetScore(accountList);

        for(Account accountRecord : accountList){
            system.assertEquals(8, accountRecord.Account_Net_Score__c);
        }
    }

    static testMethod void CalculateGainsightNetScore_WillSetScoreCorrectly() {
        Account[] accountList = new Account[]{
                new Account(
                        Name = 'My little Account'
                )
        };

        insert accountList;

        JBCXM__CustomerInfo__c[] customerInfoRecords = new JBCXM__CustomerInfo__c[]{
                new JBCXM__CustomerInfo__c(
                        JBCXM_CreatedCases__c = 2,
                        JBCXM__ASV__c = 1,
                        JBCXM_Credits__c = 2,
                        JBCXM__Account__c = accountList[0].Id
                )
        };

        GainsightImpactCalculationStub gainsightImpactCalculationStub = new  GainsightImpactCalculationStub();
        gainsightImpactCalculationStub.AnnualContractValueScore = 1;
        gainsightImpactCalculationStub.CreditGivenLastTwelveMonthsScore = 1;
        gainsightImpactCalculationStub.HealthScore = 1;
        gainsightImpactCalculationStub.IncidentsOpenedLastSixMonthsScore = 1;
        gainsightImpactCalculationStub.MttrIncidentScore = 1;
        gainsightImpactCalculationStub.OutstandingIncidentCaseScore = 1;

        ImpactCalculationService impactService = new ImpactCalculationService(gainsightImpactCalculationStub);

        impactService.CalculateGainsightNetScore(customerInfoRecords);

        for(Account accountRecord :[Select Gainsight_Net_Score__c from Account]){
            system.assertEquals(3, accountRecord.Gainsight_Net_Score__c);
        }
    }
}