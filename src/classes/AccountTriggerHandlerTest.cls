@IsTest
private class AccountTriggerHandlerTest {
    static final String OPPORTUNITY_TYPE_NEW = 'New Opportunity';

    static testMethod void dissociateContactXmPersonTest() {

        Map<String,Schema.RecordTypeInfo> accountRecordTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Account testAccount = new Account(
                Name = 'dissociateContactXmPersonTest Account',
                Type = 'Customer',
                RecordTypeId = accountRecordTypeMap.get('Customers').getRecordTypeId(),
                IsPartner__c = false,
                CG_Disconnect_Date__c = null
        );

        insert testAccount;

        xmPerson__c person = new xmPerson__c(
                xmPersonUID__c = 'efrd-sqaw-123e-deft'
        );
        insert person;

        Map<String,Schema.RecordTypeInfo> contactRecordTypeMap = Schema.SObjectType.Contact.getRecordTypeInfosByName();
        Contact testContact = new Contact(
                LastName = 'Contact',
                FirstName = 'dissociateContactXmPersonTest',
                Email = 'contact11@test.com',
                RecordTypeId = contactRecordTypeMap.get('Customer-Other').getRecordTypeId(),
                AccountId = testAccount.Id,
                xmPerson__c = person.Id
        );

        insert testContact;

        test.startTest();

        test.setMock(HttpCalloutMock.class, new XMRestPeopleMockHttpGenerator(200,'Complete','[{"Id": "efrd-sqaw-123e-deft","Status":"INACTIVE"}]',null));

        // deactivate account
        testAccount.CG_Disconnect_Date__c = system.today();
        update testAccount;

        test.stopTest();

        // verify contact is dissociated
        Contact[] contactList = [Select Id from Contact where AccountId = :testAccount.Id];

        system.assertEquals(null, contactList[0].xmPerson__c, 'Contact was not dissociated.');

    }


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
                Brand_Visibility__c = 'Yes',
                Industry_Leadership_Vocality__c = 'No',
                Social_Media_Presence__c = 'Yes',
                Risk_of_Leaving__c = 'Low',
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
        Double ageOfCustomerScore = accountScoreCalculator.CalculateAgeOfCustomerInMonthsScore((Integer)testAccount.Age_of_Customer_in_Months__c, (Double)ageOfCustomerMultiplier.Multiplier__c);
        Double riskOfLeavingScore = accountScoreCalculator.CalculateRiskOfLeavingScore(testAccount.Risk_of_Leaving__c, (Double)riskOfLeavingMultiplier.Multiplier__c);
        Double gyrStatusScore = accountScoreCalculator.CalculateGYRColor(testAccount.GYRStatus__c);
        Double stategicAccountScore = accountScoreCalculator.CalculateStrategicAccountScore(testAccount.CustomerSegment__c, (Double)stategicAccountMultiplier.Multiplier__c);
        Double partnerAccountScore = accountScoreCalculator.CalculatePartnerAccountScore(testAccount.IsPartner__c, (Double)partnerAccountMultiplier.Multiplier__c);
        Double brandVisibilityScore = accountScoreCalculator.CalculateBrandVisibilityScore(testAccount.Brand_Visibility__c, (Double)brandVisibilityMultiplier.Multiplier__c);
        Double industryLeaderScore = accountScoreCalculator.CalculateIndustryLeaderScore(testAccount.Industry_Leadership_Vocality__c, (Double)industryLeaderMultiplier.Multiplier__c);
        Double socialMediaScore = accountScoreCalculator.CalculateSocialMediaPresenceScore(testAccount.Social_Media_Presence__c, (Double)socialMediaMultiplier.Multiplier__c);
        Double referenceableScore = accountScoreCalculator.CalculateCurrentReferenceScore(testAccount.Referenceable__c, (Double)referenceableMultiplier.Multiplier__c);

        Double accountNetScore = ageOfCustomerScore + riskOfLeavingScore + gyrStatusScore + stategicAccountScore + partnerAccountScore
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
                Brand_Visibility__c = 'No',
                Industry_Leadership_Vocality__c = 'Yes',
                Social_Media_Presence__c = 'Yes',
                Risk_of_Leaving__c = 'Low',
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

        testIncident.Risk_of_Leaving__c = 'Medium';
        testIncident.CustomerSegment__c = 'Large';
        testIncident.GYRStatus__c = 'Yellow';
        testIncident.IsPartner__c = true;
        testIncident.Brand_Visibility__c = 'Yes';
        testIncident.Industry_Leadership_Vocality__c = 'No';
        testIncident.Social_Media_Presence__c = 'no';
        testIncident.Referenceable__c = true;

        test.startTest();
        update testIncident;
        test.stopTest();



        // Calculate Values
        Double ageOfCustomerScore = accountScoreCalculator.CalculateAgeOfCustomerInMonthsScore((Integer)testIncident.Age_of_Customer_in_Months__c, (Double)ageOfCustomerMultiplier.Multiplier__c);
        Double riskOfLeavingScore = accountScoreCalculator.CalculateRiskOfLeavingScore(testIncident.Risk_of_Leaving__c, (Double)riskOfLeavingMultiplier.Multiplier__c);
        Double gyrStatusScore = accountScoreCalculator.CalculateGYRColor(testIncident.GYRStatus__c);
        Double stategicAccountScore = accountScoreCalculator.CalculateStrategicAccountScore(testIncident.CustomerSegment__c, (Double)stategicAccountMultiplier.Multiplier__c);
        Double partnerAccountScore = accountScoreCalculator.CalculatePartnerAccountScore(testIncident.IsPartner__c, (Double)partnerAccountMultiplier.Multiplier__c);
        Double brandVisibilityScore = accountScoreCalculator.CalculateBrandVisibilityScore(testIncident.Brand_Visibility__c, (Double)brandVisibilityMultiplier.Multiplier__c);
        Double industryLeaderScore = accountScoreCalculator.CalculateIndustryLeaderScore(testIncident.Industry_Leadership_Vocality__c, (Double)industryLeaderMultiplier.Multiplier__c);
        Double socialMediaScore = accountScoreCalculator.CalculateSocialMediaPresenceScore(testIncident.Social_Media_Presence__c, (Double)socialMediaMultiplier.Multiplier__c);
        Double referenceableScore = accountScoreCalculator.CalculateCurrentReferenceScore(testIncident.Referenceable__c, (Double)referenceableMultiplier.Multiplier__c);

        Double accountNetScore = ageOfCustomerScore + riskOfLeavingScore + gyrStatusScore + stategicAccountScore + partnerAccountScore
                + brandVisibilityScore + industryLeaderScore + socialMediaScore + referenceableScore;


        Account customer = [Select Account_Net_Score__c from Account where Id = :testAccount.Id];
        system.assert(customer.Account_Net_Score__c == accountNetScore, 'Account Net Score did not match the expected value');
    }

    static testMethod void testCalculationAccountNetScore_BulkInsert(){
        List<Account> accountsToInsert = new List<Account>();

        AccountImpactCalculationImpl accountScoreCalculator = new AccountImpactCalculationImpl();

        Map<String,Schema.RecordTypeInfo> accountRecordTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> opportunityRecordTypeMap = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();

        Impact_Score_Multiplier__c[] multipliers = new Impact_Score_Multiplier__c[]{};

        for(Integer i=0; i < 100; i++){
            Account testAccount = new Account(
                    Name = 'testCalculateAccountNetScore Account ' + i,
                    Type = 'Customer',
                    RecordTypeId = accountRecordTypeMap.get('Customers').getRecordTypeId(),
                    IsPartner__c = false,
                    CustomerSegment__c = 'Strategic',
                    Brand_Visibility__c = 'No',
                    Industry_Leadership_Vocality__c = 'Yes',
                    Social_Media_Presence__c = 'Yes',
                    Risk_of_Leaving__c = 'Low',
                    Referenceable__c = false,
                    GYRStatus__c = 'Green'
            );

            accountsToInsert.add(testAccount);
        }


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
        Double ageOfCustomerScore = accountScoreCalculator.CalculateAgeOfCustomerInMonthsScore((Integer)accountsToInsert[0].Age_of_Customer_in_Months__c, (Double)ageOfCustomerMultiplier.Multiplier__c);
        Double riskOfLeavingScore = accountScoreCalculator.CalculateRiskOfLeavingScore(accountsToInsert[0].Risk_of_Leaving__c, (Double)riskOfLeavingMultiplier.Multiplier__c);
        Double gyrStatusScore = accountScoreCalculator.CalculateGYRColor(accountsToInsert[0].GYRStatus__c);
        Double stategicAccountScore = accountScoreCalculator.CalculateStrategicAccountScore(accountsToInsert[0].CustomerSegment__c, (Double)stategicAccountMultiplier.Multiplier__c);
        Double partnerAccountScore = accountScoreCalculator.CalculatePartnerAccountScore(accountsToInsert[0].IsPartner__c, (Double)partnerAccountMultiplier.Multiplier__c);
        Double brandVisibilityScore = accountScoreCalculator.CalculateBrandVisibilityScore(accountsToInsert[0].Brand_Visibility__c, (Double)brandVisibilityMultiplier.Multiplier__c);
        Double industryLeaderScore = accountScoreCalculator.CalculateIndustryLeaderScore(accountsToInsert[0].Industry_Leadership_Vocality__c, (Double)industryLeaderMultiplier.Multiplier__c);
        Double socialMediaScore = accountScoreCalculator.CalculateSocialMediaPresenceScore(accountsToInsert[0].Social_Media_Presence__c, (Double)socialMediaMultiplier.Multiplier__c);
        Double referenceableScore = accountScoreCalculator.CalculateCurrentReferenceScore(accountsToInsert[0].Referenceable__c, (Double)referenceableMultiplier.Multiplier__c);

        Double accountNetScore = ageOfCustomerScore + riskOfLeavingScore + gyrStatusScore + stategicAccountScore + partnerAccountScore
                + brandVisibilityScore + industryLeaderScore + socialMediaScore + referenceableScore;

        // Insert multipliers
        insert multipliers;
        test.startTest();

        insert accountsToInsert;
        test.stopTest();

        List<Account> customerList = [Select Account_Net_Score__c from Account];

        for(Account accountRecord :customerList){
            system.assert(accountRecord.Account_Net_Score__c == accountNetScore, 'Account Net Score did not match the expected value');
        }
    }
}