
@IsTest
private class CustomerInfoTriggerHandlerTest {
    static testMethod void testInsert() {

        Account customer = [Select Id from Account Limit 1];
        JBCXM__ScoringScheme__c scoringScheme = new JBCXM__ScoringScheme__c(
            Name = 'test'
        );
        JBCXM__ScoringSchemeDefinition__c scoringSchemeDefinition = new JBCXM__ScoringSchemeDefinition__c(
                JBCXM__Score__c = 2.0
        );
        JBCXM__CustomerInfo__c customerInfo = new JBCXM__CustomerInfo__c(
                JBCXM__Account__c = customer.Id,
//                JBCXM__CurScoreId__c,
//                JBCXM__CurScoreId__r.JBCXM__Score__c,
                JBCXM__ASV__c = 1800000,
                JBCXM_CreatedCases__c = 15,
                JBCXM_OpenCases__c = 20,
                JBCXM_Credits__c = 2500,
                JBCXM_MTTR_IN_Hours__c = 504
        );

        insert scoringScheme;
        scoringSchemeDefinition.JBCXM__SchemeId__c = scoringScheme.Id;

        insert scoringSchemeDefinition;
        customerInfo.JBCXM__CurScoreId__c = scoringSchemeDefinition.Id;

        //create the impact score multiplier
        GainsightImpactCalculationInterface impactCalculator = new GainsightImpactCalculationImpl();
        Impact_Score_Multiplier__c[] multipliers = new Impact_Score_Multiplier__c[]{};

        //outstanding incidents
        Impact_Score_Multiplier__c outstandingIncidents = new Impact_Score_Multiplier__c(
                Name = 'outstanding incidents',
                Multiplier__c = 2.0
        );
        multipliers.add(outstandingIncidents);
        Double outstandingIncidentScore = impactCalculator.CalculateOutstandingIncidentCaseScore((Integer)customerInfo.JBCXM_OpenCases__c, (Double)outstandingIncidents.Multiplier__c);
        system.debug('CalculateOutstandingIncidentCaseScore: ' + customerInfo.JBCXM_OpenCases__c + ', ' + outstandingIncidents.Multiplier__c + ' = ' + outstandingIncidentScore);

        //incidents opened in last six months
        Impact_Score_Multiplier__c incidentsLastSixMonths = new Impact_Score_Multiplier__c(
                Name = 'incidents opened last six months',
                Multiplier__c = 3.0
        );
        multipliers.add(incidentsLastSixMonths);
        Double incidentsLastSixMonthsScore = impactCalculator.CalculateIncidentsOpenedLastSixMonthsScore((Integer)customerInfo.JBCXM_CreatedCases__c, (Double)incidentsLastSixMonths.Multiplier__c);
        system.debug('CalculateIncidentsOpenedLastSixMonthsScore: ' + customerInfo.JBCXM_CreatedCases__c + ', ' + incidentsLastSixMonths.Multiplier__c + ' = ' + incidentsLastSixMonthsScore);

        //mttr last six months
        Impact_Score_Multiplier__c mttrLastSixMonths = new Impact_Score_Multiplier__c(
                Name = 'mttr last six months',
                Multiplier__c = 4.0
        );
        multipliers.add(mttrLastSixMonths);
        Double mttrScore = impactCalculator.CalculateMttrIncidentScore((Integer)(customerInfo.JBCXM_MTTR_IN_Hours__c/24/7), (Double)mttrLastSixMonths.Multiplier__c);
        system.debug('CalculateMttrIncidentScore: ' + customerInfo.JBCXM_MTTR__c + ', ' + mttrLastSixMonths.Multiplier__c + ' = ' + mttrScore);

        //annual contract value
        Impact_Score_Multiplier__c annualValue = new Impact_Score_Multiplier__c(
                Name = 'annual contract value',
                Multiplier__c = 5.0
        );
        multipliers.add(annualValue);
        Double annualContractValueScore = impactCalculator.CalculateAnnualContractValueScore((Integer)customerInfo.JBCXM__ASV__c, (Double)annualValue.Multiplier__c);
        system.debug('CalculateAnnualContractValueScore: ' + customerInfo.JBCXM__ASV__c + ', ' + annualValue.Multiplier__c + ' = ' + annualContractValueScore);

        //credits last 12 months
        Impact_Score_Multiplier__c credits = new Impact_Score_Multiplier__c(
                Name = 'credits last 12 months',
                Multiplier__c = 6.0
        );
        multipliers.add(credits);
        Double creditsScore = impactCalculator.CalculateCreditGivenLastTwelveMonths((Integer)customerInfo.JBCXM_Credits__c, (Double)credits.Multiplier__c);
        system.debug('CalculateCreditGivenLastTwelveMonths: ' + customerInfo.JBCXM_Credits__c + ', ' + credits.Multiplier__c + ' = ' + creditsScore);

        //health score
        Impact_Score_Multiplier__c health = new Impact_Score_Multiplier__c(
                Name = 'health score',
                Multiplier__c = 7.0
        );
        multipliers.add(health);
        Double healthScore = impactCalculator.CalculateHealthScore((Integer)customerInfo.JBCXM__CurScoreId__r.JBCXM__Score__c, (Double)health.Multiplier__c);
        system.debug('CalculateHealthScore: ' + customerInfo.JBCXM__CurScoreId__r.JBCXM__Score__c + ', ' + health.Multiplier__c + ' = ' + healthScore);

        insert multipliers;

        test.startTest();
        insert customerInfo;
        test.stopTest();

        customer = [Select GainSight_Net_Score__c from Account where Id = :customer.Id];
        Double netScore = outstandingIncidentScore
                + incidentsLastSixMonthsScore
                + mttrScore
                + annualContractValueScore
                + creditsScore
                + healthScore;

        system.assert(customer.GainSight_Net_Score__c == netScore, 'The GainSight_Net_Score__c value was not correct. expected: ' + netScore + ' actual: ' + customer.GainSight_Net_Score__c);
    }

    static testMethod void testUpdate() {
        Account customer = [Select Id from Account Limit 1];
        JBCXM__ScoringScheme__c scoringScheme = new JBCXM__ScoringScheme__c(
                Name = 'test'
        );
        JBCXM__ScoringSchemeDefinition__c scoringSchemeDefinition = new JBCXM__ScoringSchemeDefinition__c(
                JBCXM__Score__c = 2.0
        );
        JBCXM__CustomerInfo__c customerInfo = new JBCXM__CustomerInfo__c(
                JBCXM__Account__c = customer.Id,
//                JBCXM__CurScoreId__c,
//                JBCXM__CurScoreId__r.JBCXM__Score__c,
                JBCXM__ASV__c = 1800000,
                JBCXM_CreatedCases__c = 15,
                JBCXM_OpenCases__c = 20,
                JBCXM_Credits__c = 2500,
                JBCXM_MTTR_IN_Hours__c = 504
        );

        insert scoringScheme;
        scoringSchemeDefinition.JBCXM__SchemeId__c = scoringScheme.Id;

        insert scoringSchemeDefinition;
        customerInfo.JBCXM__CurScoreId__c = scoringSchemeDefinition.Id;

        insert customerInfo;

        //create the impact score multiplier
        GainsightImpactCalculationInterface impactCalculator = new GainsightImpactCalculationImpl();
        Impact_Score_Multiplier__c[] multipliers = new Impact_Score_Multiplier__c[]{};

        //outstanding incidents
        Impact_Score_Multiplier__c outstandingIncidents = new Impact_Score_Multiplier__c(
                Name = 'outstanding incidents',
                Multiplier__c = 2.0
        );
        multipliers.add(outstandingIncidents);
        Double outstandingIncidentScore = impactCalculator.CalculateOutstandingIncidentCaseScore(((Integer)customerInfo.JBCXM_OpenCases__c) * 2, (Double)outstandingIncidents.Multiplier__c);
        system.debug('CalculateOutstandingIncidentCaseScore: ' + (customerInfo.JBCXM_OpenCases__c * 2) + ', ' + outstandingIncidents.Multiplier__c + ' = ' + outstandingIncidentScore);

        //incidents opened in last six months
        Impact_Score_Multiplier__c incidentsLastSixMonths = new Impact_Score_Multiplier__c(
                Name = 'incidents opened last six months',
                Multiplier__c = 3.0
        );
        multipliers.add(incidentsLastSixMonths);
        Double incidentsLastSixMonthsScore = impactCalculator.CalculateIncidentsOpenedLastSixMonthsScore(((Integer)customerInfo.JBCXM_CreatedCases__c) * 2, (Double)incidentsLastSixMonths.Multiplier__c);
        system.debug('CalculateIncidentsOpenedLastSixMonthsScore: ' + (customerInfo.JBCXM_CreatedCases__c * 2) + ', ' + incidentsLastSixMonths.Multiplier__c + ' = ' + incidentsLastSixMonthsScore);

        //mttr last six months
        Impact_Score_Multiplier__c mttrLastSixMonths = new Impact_Score_Multiplier__c(
                Name = 'mttr last six months',
                Multiplier__c = 4.0
        );
        multipliers.add(mttrLastSixMonths);
        Double mttrScore = impactCalculator.CalculateMttrIncidentScore((Integer)(customerInfo.JBCXM_MTTR_IN_Hours__c/24/7) * 2, (Double)mttrLastSixMonths.Multiplier__c);
        system.debug('CalculateMttrIncidentScore: ' + ((customerInfo.JBCXM_MTTR_IN_Hours__c/24/7) * 2) + ', ' + mttrLastSixMonths.Multiplier__c + ' = ' + mttrScore);

        //annual contract value
        Impact_Score_Multiplier__c annualValue = new Impact_Score_Multiplier__c(
                Name = 'annual contract value',
                Multiplier__c = 5.0
        );
        multipliers.add(annualValue);
        Double annualContractValueScore = impactCalculator.CalculateAnnualContractValueScore(((Integer)customerInfo.JBCXM__ASV__c) * 2, (Double)annualValue.Multiplier__c);
        system.debug('CalculateAnnualContractValueScore: ' + (customerInfo.JBCXM__ASV__c * 2) + ', ' + annualValue.Multiplier__c + ' = ' + annualContractValueScore);

        //credits last 12 months
        Impact_Score_Multiplier__c credits = new Impact_Score_Multiplier__c(
                Name = 'credits last 12 months',
                Multiplier__c = 6.0
        );
        multipliers.add(credits);
        Double creditsScore = impactCalculator.CalculateCreditGivenLastTwelveMonths(((Integer)customerInfo.JBCXM_Credits__c) * 2, (Double)credits.Multiplier__c);
        system.debug('CalculateCreditGivenLastTwelveMonths: ' + (customerInfo.JBCXM_Credits__c * 2) + ', ' + credits.Multiplier__c + ' = ' + creditsScore);

        //health score
        Impact_Score_Multiplier__c health = new Impact_Score_Multiplier__c(
                Name = 'health score',
                Multiplier__c = 7.0
        );
        system.debug(customerInfo.JBCXM__CurScoreId__r);
        multipliers.add(health);
        Double healthScore = impactCalculator.CalculateHealthScore(((Integer)scoringSchemeDefinition.JBCXM__Score__c) * 2, (Double)health.Multiplier__c);
        system.debug('CalculateHealthScore: ' + (scoringSchemeDefinition.JBCXM__Score__c * 2) + ', ' + health.Multiplier__c + ' = ' + healthScore);

        insert multipliers;


        //change the values and update to ensure the score is correct.break
        //all of the values were doubled to get the expected score value
        customerInfo.JBCXM_OpenCases__c *= 2;
        customerInfo.JBCXM_CreatedCases__c *= 2;
        customerInfo.JBCXM_MTTR_IN_Hours__c *= 2;
        customerInfo.JBCXM__ASV__c *= 2;
        customerInfo.JBCXM_Credits__c *= 2;
        scoringSchemeDefinition.JBCXM__Score__c *= 2;

        update scoringSchemeDefinition;

        test.startTest();
        update customerInfo;
        test.stopTest();

        customer = [Select GainSight_Net_Score__c from Account where Id = :customer.Id];
        Double netScore = outstandingIncidentScore
                + incidentsLastSixMonthsScore
                + mttrScore
                + annualContractValueScore
                + creditsScore
                + healthScore;

        system.assert(customer.GainSight_Net_Score__c == netScore, 'The GainSight_Net_Score__c value was not correct. expected: ' + netScore + ' actual: ' + customer.GainSight_Net_Score__c);
    }

    @TestSetup
    private static void createTestData(){

        Map<String,Schema.RecordTypeInfo> accountRecordTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Account testAccount = new Account(
                Name = 'CustomerInfoTriggerHandlerTest Account',
                Type = 'Customer',
                RecordTypeId = accountRecordTypeMap.get('Customers').getRecordTypeId()
        );

        insert testAccount;
    }
}