@IsTest
private class AccountTriggerHandlerTest {
    static final String OPPORTUNITY_TYPE_NEW = 'New Opportunity';

    static testMethod void testCalculateAccountNetScore() {

        AccountImpactCalculationImpl accountScoreCalculator = new AccountImpactCalculationImpl();

        Map<String,Schema.RecordTypeInfo> accountRecordTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> opportunityRecordTypeMap = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();

        Impact_Score_Multiplier__c[] multipliers = new Impact_Score_Multiplier__c[]{};

        Account testAccount = new Account(
                Name = 'testCalculateAccountNetScore Account',
                Type = 'Customer',
                RecordTypeId = accountRecordTypeMap.get('Customers').getRecordTypeId(),
                IsPartner__c = false,
                CustomerSegment__c = 'Strategic',
                Brand_Visibility__c = 'Medium',
                Industry_Leadership_Vocality__c = 'Low',
                Social_Media_Presence__c = 'Yes',
                Risk_of_Leaving__c = '1',
                Referenceable__c = false,
                GYRStatus__c = 'Green'
        );

        // Create Multiplier Records
        Impact_Score_Multiplier__c ageOfCustomerMultiplier = new Impact_Score_Multiplier__c(
                Name = 'age of customer',
                Multiplier__c = 3.0
        );

        Impact_Score_Multiplier__c riskOfLeavingMultiplier = new Impact_Score_Multiplier__c(
                Name = 'risk of leaving',
                Multiplier__c = 3.0
        );

        Impact_Score_Multiplier__c stategicAccountMultiplier = new Impact_Score_Multiplier__c(
                Name = 'strategic account',
                Multiplier__c = 3.0
        );

        Impact_Score_Multiplier__c partnerAccountMultiplier = new Impact_Score_Multiplier__c(
                Name = 'partner account',
                Multiplier__c = 3.0
        );

        Impact_Score_Multiplier__c brandVisibilityMultiplier = new Impact_Score_Multiplier__c(
                Name = 'brand visibility',
                Multiplier__c = 3.0
        );

        Impact_Score_Multiplier__c industryLeaderMultiplier = new Impact_Score_Multiplier__c(
                Name = 'industry leadership/vocality',
                Multiplier__c = 3.0
        );

        Impact_Score_Multiplier__c socialMediaMultiplier = new Impact_Score_Multiplier__c(
                Name = 'social media presence',
                Multiplier__c = 3.0
        );

        Impact_Score_Multiplier__c referenceableMultiplier = new Impact_Score_Multiplier__c(
                Name = 'currently referenceable',
                Multiplier__c = 3.0
        );

        // Add to the multipler list so we can save them
        multipliers.add(ageOfCustomerMultiplier);
        multipliers.add(riskOfLeavingMultiplier);
        multipliers.add(stategicAccountMultiplier);
        multipliers.add(partnerAccountMultiplier);
        multipliers.add(brandVisibilityMultiplier);
        multipliers.add(industryLeaderMultiplier);
        multipliers.add(socialMediaMultiplier);
        multipliers.add(referenceableMultiplier);

        // Calculate Values
        Double riskOfLeavingScore = accountScoreCalculator.CalculateRiskOfLeavingScore(testAccount.Risk_of_Leaving__c, (Double)riskOfLeavingMultiplier.Multiplier__c);
        Double gyrStatusScore = accountScoreCalculator.CalculateGYRColor(testAccount.GYRStatus__c);
        Double stategicAccountScore = accountScoreCalculator.CalculateStrategicAccountScore(testAccount.CustomerSegment__c, (Double)stategicAccountMultiplier.Multiplier__c);
        Double partnerAccountScore = accountScoreCalculator.CalculatePartnerAccountScore(testAccount.IsPartner__c, (Double)partnerAccountMultiplier.Multiplier__c);
        Double brandVisibilityScore = accountScoreCalculator.CalculateBrandVisibilityScore(testAccount.Brand_Visibility__c, (Double)brandVisibilityMultiplier.Multiplier__c);
        Double industryLeaderScore = accountScoreCalculator.CalculateIndustryLeaderScore(testAccount.Industry_Leadership_Vocality__c, (Double)industryLeaderMultiplier.Multiplier__c);
        Double socialMediaScore = accountScoreCalculator.CalculateSocialMediaPresenceScore(testAccount.Social_Media_Presence__c, (Double)socialMediaMultiplier.Multiplier__c);
        Double referenceableScore = accountScoreCalculator.CalculateCurrentReferenceScore(testAccount.Referenceable__c, (Double)referenceableMultiplier.Multiplier__c);

        Double accountNetScore = riskOfLeavingScore + gyrStatusScore + stategicAccountScore + partnerAccountScore
                + brandVisibilityScore + industryLeaderScore + socialMediaScore + referenceableScore;

        // Insert multipliers
        insert multipliers;
        test.startTest();

        insert testAccount;
        test.stopTest();

        Account customer = [Select Account_Net_Score__c from Account where Id = :testAccount.Id];
        system.assert(customer.Account_Net_Score__c == accountNetScore, 'Account Net Score did not match the expected value');

    }


    static testMethod void testCalculateAccountNetScore_WhenAccountUpdated() {

        AccountImpactCalculationImpl accountScoreCalculator = new AccountImpactCalculationImpl();

        Map<String,Schema.RecordTypeInfo> accountRecordTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> opportunityRecordTypeMap = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();

        Impact_Score_Multiplier__c[] multipliers = new Impact_Score_Multiplier__c[]{};

        Account testAccount = new Account(
                Name = 'testCalculateAccountNetScore Account',
                Type = 'Customer',
                RecordTypeId = accountRecordTypeMap.get('Customers').getRecordTypeId(),
                IsPartner__c = false,
                CustomerSegment__c = 'Strategic',
                Brand_Visibility__c = 'Medium',
                Industry_Leadership_Vocality__c = 'Low',
                Social_Media_Presence__c = 'Yes',
                Risk_of_Leaving__c = '1',
                Referenceable__c = false,
                GYRStatus__c = 'Green'
        );

        Date sixMonthsFromToday = system.Today().addMonths(-6);

        Opportunity testOpp = new Opportunity(
                Name = 'ProjectTriggerHandlerTest Opp 1',
                AccountId = testAccount.Id,
                RecordTypeId = opportunityRecordTypeMap.get(OPPORTUNITY_TYPE_NEW).getRecordTypeId(),
                StageName = OpportunityTriggerHelper.OPPORTUNITY_STAGE_THREE,
                CloseDate = Date.today(),
                Probability = 25,
                Partner_Deal__c = 'NO',
                Contract_Type__c = 'New Customer',
                inContact__c = 'YES',
                inContact_Setup_Fee__c = 1000,
                inContact_Seats__c = 1,
                inContact_MRC_Min__c = 1000,
                inContact_Ports__c = 1,
                inContact_MRC_Exp__c = 1000,
                ECHO__c = 'NO',
                eLearning__c = 'NO',
                Hiring__c = 'NO',
                WFM__c = 'NO'
        );

        ImplementedProduct__c ip = new ImplementedProduct__c(
                Account__c = testAccount.Id,
                EstimatedGoLiveDate__c = sixMonthsFromToday,
                GoLiveDate__c = sixMonthsFromToday,
                Product__c = 'inContact',
                Status__c = 'Implemented',
                Opportunity__c = testOpp.Id);  //TODO: Should get the product dynamically?

        // Create Multiplier Records
        Impact_Score_Multiplier__c ageOfCustomerMultiplier = new Impact_Score_Multiplier__c(
                Name = 'age of customer',
                Multiplier__c = 3.0
        );

        Impact_Score_Multiplier__c riskOfLeavingMultiplier = new Impact_Score_Multiplier__c(
                Name = 'risk of leaving',
                Multiplier__c = 3.0
        );

        Impact_Score_Multiplier__c stategicAccountMultiplier = new Impact_Score_Multiplier__c(
                Name = 'strategic account',
                Multiplier__c = 3.0
        );

        Impact_Score_Multiplier__c partnerAccountMultiplier = new Impact_Score_Multiplier__c(
                Name = 'partner account',
                Multiplier__c = 3.0
        );

        Impact_Score_Multiplier__c brandVisibilityMultiplier = new Impact_Score_Multiplier__c(
                Name = 'brand visibility',
                Multiplier__c = 3.0
        );

        Impact_Score_Multiplier__c industryLeaderMultiplier = new Impact_Score_Multiplier__c(
                Name = 'industry leadership/vocality',
                Multiplier__c = 3.0
        );

        Impact_Score_Multiplier__c socialMediaMultiplier = new Impact_Score_Multiplier__c(
                Name = 'social media presence',
                Multiplier__c = 3.0
        );

        Impact_Score_Multiplier__c referenceableMultiplier = new Impact_Score_Multiplier__c(
                Name = 'currently referenceable',
                Multiplier__c = 3.0
        );

        // Add to the multipler list so we can save them
        multipliers.add(ageOfCustomerMultiplier);
        multipliers.add(riskOfLeavingMultiplier);
        multipliers.add(stategicAccountMultiplier);
        multipliers.add(partnerAccountMultiplier);
        multipliers.add(brandVisibilityMultiplier);
        multipliers.add(industryLeaderMultiplier);
        multipliers.add(socialMediaMultiplier);
        multipliers.add(referenceableMultiplier);

        // Calculate Values
        Double riskOfLeavingScore = accountScoreCalculator.CalculateRiskOfLeavingScore(testAccount.Risk_of_Leaving__c, (Double)riskOfLeavingMultiplier.Multiplier__c);
        Double gyrStatusScore = accountScoreCalculator.CalculateGYRColor(testAccount.GYRStatus__c);
        Double stategicAccountScore = accountScoreCalculator.CalculateStrategicAccountScore(testAccount.CustomerSegment__c, (Double)stategicAccountMultiplier.Multiplier__c);
        Double partnerAccountScore = accountScoreCalculator.CalculatePartnerAccountScore(testAccount.IsPartner__c, (Double)partnerAccountMultiplier.Multiplier__c);
        Double brandVisibilityScore = accountScoreCalculator.CalculateBrandVisibilityScore(testAccount.Brand_Visibility__c, (Double)brandVisibilityMultiplier.Multiplier__c);
        Double industryLeaderScore = accountScoreCalculator.CalculateIndustryLeaderScore(testAccount.Industry_Leadership_Vocality__c, (Double)industryLeaderMultiplier.Multiplier__c);
        Double socialMediaScore = accountScoreCalculator.CalculateSocialMediaPresenceScore(testAccount.Social_Media_Presence__c, (Double)socialMediaMultiplier.Multiplier__c);
        Double referenceableScore = accountScoreCalculator.CalculateCurrentReferenceScore(testAccount.Referenceable__c, (Double)referenceableMultiplier.Multiplier__c);

        Double accountNetScore = riskOfLeavingScore + gyrStatusScore + stategicAccountScore + partnerAccountScore
                + brandVisibilityScore + industryLeaderScore + socialMediaScore + referenceableScore;

        // Insert multipliers
        insert multipliers;
        test.startTest();

        insert testAccount;
        test.stopTest();

        Account customer = [Select Account_Net_Score__c from Account where Id = :testAccount.Id];
        system.assert(customer.Account_Net_Score__c == accountNetScore, 'Account Net Score did not match the expected value');
    }
}