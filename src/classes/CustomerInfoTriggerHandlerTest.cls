
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
                JBCXM__MRR__c = 30000,
                JBCXM_Credits__c = 2500
        );
        customerInfo.recalculateFormulas();
        insert scoringScheme;
        scoringSchemeDefinition.JBCXM__SchemeId__c = scoringScheme.Id;

        insert scoringSchemeDefinition;
        customerInfo.JBCXM__CurScoreId__c = scoringSchemeDefinition.Id;

        //create the impact score multiplier
        GainsightImpactCalculationInterface impactCalculator = new GainsightImpactCalculationImpl();
        Impact_Score_Multiplier__c[] multipliers = new Impact_Score_Multiplier__c[]{};

        //annual contract value
        Impact_Score_Multiplier__c mrrValue = new Impact_Score_Multiplier__c(
                Name = 'mrr',
                Multiplier__c = 5.0
        );
        multipliers.add(mrrValue);
        Double mrrValueScore = impactCalculator.CalculateMRRScore((Integer)customerInfo.JBCXM__MRR__c, (Double)mrrValue.Multiplier__c);
        system.debug('CalculateMRRValueScore: ' + customerInfo.JBCXM__MRR__c + ', ' + mrrValue.Multiplier__c + ' = ' + mrrValueScore);

        //credits last 12 months
        Impact_Score_Multiplier__c credits = new Impact_Score_Multiplier__c(
                Name = 'credits last 12 months',
                Multiplier__c = 2.0
        );
        multipliers.add(credits);
        Double creditsScore = impactCalculator.CalculateCreditGivenLastTwelveMonths((Integer)customerInfo.JBCXM_Credits__c, (Double)credits.Multiplier__c);
        system.debug('CalculateCreditGivenLastTwelveMonths: ' + customerInfo.JBCXM_Credits__c + ', ' + credits.Multiplier__c + ' = ' + creditsScore);

        //health score
        Impact_Score_Multiplier__c health = new Impact_Score_Multiplier__c(
                Name = 'health score',
                Multiplier__c = 4.0
        );
        multipliers.add(health);
        Double healthScore = impactCalculator.CalculateHealthScore((Integer)customerInfo.JBCXM__CurScoreId__r.JBCXM__Score__c, (Double)health.Multiplier__c);
        system.debug('CalculateHealthScore: ' + customerInfo.JBCXM__CurScoreId__r.JBCXM__Score__c + ', ' + health.Multiplier__c + ' = ' + healthScore);

        insert multipliers;

        test.startTest();
        insert customerInfo;
        test.stopTest();

        customer = [Select GainSight_Net_Score__c from Account where Id = :customer.Id];
        Double netScore =
                mrrValueScore
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
                JBCXM__MRR__c = 1800000,
                JBCXM_Credits__c = 2500
        );

        insert scoringScheme;
        scoringSchemeDefinition.JBCXM__SchemeId__c = scoringScheme.Id;

        insert scoringSchemeDefinition;
        customerInfo.JBCXM__CurScoreId__c = scoringSchemeDefinition.Id;

        insert customerInfo;

        //create the impact score multiplier
        GainsightImpactCalculationInterface impactCalculator = new GainsightImpactCalculationImpl();
        Impact_Score_Multiplier__c[] multipliers = new Impact_Score_Multiplier__c[]{};

        //annual contract value
        Impact_Score_Multiplier__c mrrValue = new Impact_Score_Multiplier__c(
                Name = 'mrr',
                Multiplier__c = 5.0
        );
        multipliers.add(mrrValue);
        Double mrrValueScore = impactCalculator.CalculateMRRScore((Integer)customerInfo.JBCXM__MRR__c, (Double)mrrValue.Multiplier__c);
        system.debug('CalculateMRRValueScore: ' + customerInfo.JBCXM__MRR__c + ', ' + mrrValue.Multiplier__c + ' = ' + mrrValueScore);

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

        customerInfo.JBCXM__MRR__c *= 2;
        customerInfo.JBCXM_Credits__c *= 2;
        scoringSchemeDefinition.JBCXM__Score__c *= 2;

        update scoringSchemeDefinition;

        test.startTest();
        update customerInfo;
        test.stopTest();

        customer = [Select GainSight_Net_Score__c from Account where Id = :customer.Id];
        Double netScore = mrrValueScore
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