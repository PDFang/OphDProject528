@IsTest
private class AccountTriggerHandlerTest {
    static final String OPPORTUNITY_TYPE_NEW = 'New Opportunity';

    static testMethod void testCalculateAccountNetScore_Insert() {

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

        // Insert multipliers
        insert multipliers;
        insert testAccount;

        Account testIncident = [Select Id, Risk_of_Leaving__c, GYRStatus__c, CustomerSegment__c, IsPartner__c, Brand_Visibility__c,Industry_Leadership_Vocality__c,Social_Media_Presence__c,Referenceable__c  from Account where Id = :testAccount.Id];

        testIncident.Risk_of_Leaving__c = '2';
        testIncident.CustomerSegment__c = 'Large';
        testIncident.GYRStatus__c = 'Yellow';
        testIncident.IsPartner__c = true;
        testIncident.Brand_Visibility__c = 'Low';
        testIncident.Industry_Leadership_Vocality__c = 'Medium';
        testIncident.Social_Media_Presence__c = 'no';
        testIncident.Referenceable__c = true;

        test.startTest();
        update testIncident;
        test.stopTest();



        // Calculate Values
        Double riskOfLeavingScore = accountScoreCalculator.CalculateRiskOfLeavingScore(testIncident.Risk_of_Leaving__c, (Double)riskOfLeavingMultiplier.Multiplier__c);
        Double gyrStatusScore = accountScoreCalculator.CalculateGYRColor(testIncident.GYRStatus__c);
        Double stategicAccountScore = accountScoreCalculator.CalculateStrategicAccountScore(testIncident.CustomerSegment__c, (Double)stategicAccountMultiplier.Multiplier__c);
        Double partnerAccountScore = accountScoreCalculator.CalculatePartnerAccountScore(testIncident.IsPartner__c, (Double)partnerAccountMultiplier.Multiplier__c);
        Double brandVisibilityScore = accountScoreCalculator.CalculateBrandVisibilityScore(testIncident.Brand_Visibility__c, (Double)brandVisibilityMultiplier.Multiplier__c);
        Double industryLeaderScore = accountScoreCalculator.CalculateIndustryLeaderScore(testIncident.Industry_Leadership_Vocality__c, (Double)industryLeaderMultiplier.Multiplier__c);
        Double socialMediaScore = accountScoreCalculator.CalculateSocialMediaPresenceScore(testIncident.Social_Media_Presence__c, (Double)socialMediaMultiplier.Multiplier__c);
        Double referenceableScore = accountScoreCalculator.CalculateCurrentReferenceScore(testIncident.Referenceable__c, (Double)referenceableMultiplier.Multiplier__c);

        Double accountNetScore = riskOfLeavingScore + gyrStatusScore + stategicAccountScore + partnerAccountScore
                + brandVisibilityScore + industryLeaderScore + socialMediaScore + referenceableScore;


        Account customer = [Select Account_Net_Score__c from Account where Id = :testAccount.Id];
        system.assert(customer.Account_Net_Score__c == accountNetScore, 'Account Net Score did not match the expected value');
    }
}