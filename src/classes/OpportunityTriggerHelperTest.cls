@isTest
public class OpportunityTriggerHelperTest {

    static final String ACCOUNT_TYPE_CUSTOMERS = 'Customers';
    static final String CONTACT_TYPE_PARTNER = 'Partner Contact';
    static final String PROJECT_TYPE_PARENT_SAAS = 'PS Parent Project - SaaS';
    static final String PROJECT_TYPE_PHASE_SAAS = 'PS Project Phase SaaS';
    static final String OPPORTUNITY_TYPE_NEW = 'New Opportunity';
    //static final String OPPORTUNITY_TYPE_PS = 'PS Opportunity';

    static final Set<String> recordTypeSet = new Set<String>
    {
            ACCOUNT_TYPE_CUSTOMERS,
            CONTACT_TYPE_PARTNER,
            OPPORTUNITY_TYPE_NEW,
            PROJECT_TYPE_PARENT_SAAS,
            PROJECT_TYPE_PHASE_SAAS
    };
    static Map<String, Id> recordTypeMap = null;
    static Account testAccount = null;
    static Contact testContact = null;
    static Opportunity testOpp = null;
    static Project__c testPhase = null;
    static User impManagementUser = null;

    // Test the opportunity "Handed off to CC/CS" checkbox cannot be checked unless all related SaaS project phases are complete
    static testmethod void AvailableForCCHandOffTest(){

        createTestData();
        createOpportunity();
        createProjects();
        test.startTest();
        system.runAs(impManagementUser){
            testOpp.HandedOffToCCCS__c = true;
            Database.SaveResult result = Database.update(testOpp, false);
            system.assertEquals(false, result.isSuccess(), result.getErrors());
        }
        // change the phase status to 'Closed'
        testPhase.Phase_Status__c = 'Closed';
        update testPhase;
        system.runAs(impManagementUser){
            testOpp.HandedOffToCCCS__c = true;
            Database.SaveResult result = Database.update(testOpp, false);
            system.assertEquals(true, result.isSuccess(), result.getErrors());
        }
        test.stopTest();

    } // end of AvailableForCCHandOffTest()

    // Verify timestamp is captured when opportunity stage is changed
    static testMethod void timestampHelperTest(){

        createTestData();
        test.starttest();
        createOpportunity();
        test.stopTest();

        Opportunity oppResult = [
                Select Stage_2_Timestamp__c, Stage_3_Timestamp__c, Stage_4_Timestamp__c, Stage_5_Timestamp__c, Stage_6_Timestamp__c
                from Opportunity where Id = :testOpp.Id
        ];
        system.assertEquals(system.today(), oppResult.Stage_2_Timestamp__c);
        system.assertEquals(null, oppResult.Stage_3_Timestamp__c);
        system.assertEquals(null, oppResult.Stage_4_Timestamp__c);
        system.assertEquals(null, oppResult.Stage_5_Timestamp__c);
        system.assertEquals(null, oppResult.Stage_6_Timestamp__c);

        testOpp.StageName = OpportunityTriggerHelper.OPPORTUNITY_STAGE_FOUR;
        update testOpp;
        oppResult = [
                Select Stage_2_Timestamp__c, Stage_3_Timestamp__c, Stage_4_Timestamp__c, Stage_5_Timestamp__c, Stage_6_Timestamp__c
                from Opportunity where Id = :testOpp.Id
        ];
        system.assertEquals(system.today(), oppResult.Stage_2_Timestamp__c);
        system.assertEquals(null, oppResult.Stage_3_Timestamp__c);
        system.assertEquals(system.today(), oppResult.Stage_4_Timestamp__c);
        system.assertEquals(null, oppResult.Stage_5_Timestamp__c);
        system.assertEquals(null, oppResult.Stage_6_Timestamp__c);

        testOpp.StageName = OpportunityTriggerHelper.OPPORTUNITY_STAGE_CLOSED_WON;
        update testOpp;
        oppResult = [
                Select Stage_2_Timestamp__c, Stage_3_Timestamp__c, Stage_4_Timestamp__c, Stage_5_Timestamp__c, Stage_6_Timestamp__c
                from Opportunity where Id = :testOpp.Id
        ];
        system.assertEquals(system.today(), oppResult.Stage_2_Timestamp__c);
        system.assertEquals(null, oppResult.Stage_3_Timestamp__c);
        system.assertEquals(system.today(), oppResult.Stage_4_Timestamp__c);
        system.assertEquals(null, oppResult.Stage_5_Timestamp__c);
        system.assertEquals(system.today(), oppResult.Stage_6_Timestamp__c);

    } // end of timestampHelperTest()

    /* Create the test data required to execute the tests successfully */
    static void createTestData(){

        recordTypeMap = new Map<String, Id>();
        for(RecordType record : [
                Select Id, Name from RecordType
                where Name IN :recordTypeSet
        ])
        {
            recordTypeMap.put(record.Name, record.Id);
        }
        impManagementUser = [Select Id from User where Profile.Name = 'Implementation Management' and isActive = true LIMIT 1][0];
        createAccount();
        createContact();

    } // end of createTestData()

    static void createAccount()
    {
        testAccount = new Account(
                Name = 'OpportunityTriggerHelperTest Account',
                Type = 'Customer',
                RecordTypeId = recordTypeMap.get(ACCOUNT_TYPE_CUSTOMERS)
        );

        insert testAccount;

    } // end of createAccount()

    static void createContact() {

        testContact = new Contact(
                LastName = 'OpportunityTriggerHelperTest Contact',
                Email = 'contact1@incontact.com',
                RecordTypeId = recordTypeMap.get(CONTACT_TYPE_PARTNER),
                AccountId = testAccount.Id
        );
        insert testContact;
    }

    static void createOpportunity(){

        testOpp = new Opportunity(
                Name = 'ProjectTriggerHandlerTest Opp 1',
                AccountId = testAccount.Id,
                RecordTypeId = recordTypeMap.get(OPPORTUNITY_TYPE_NEW),
                StageName = OpportunityTriggerHelper.OPPORTUNITY_STAGE_TWO,
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
                WFM__c = 'NO',
                ownerId = impManagementUser.Id
        );
        insert testOpp;
    }

    static void createProjects(){

        Project__c parentProject = new Project__c();
        parentProject.RecordTypeId = recordTypeMap.get(PROJECT_TYPE_PARENT_SAAS);
        parentProject.Opportunity__c = testOpp.Id;
        parentProject.Account__c = testAccount.Id;
        parentProject.Projected_Deadline__c = system.today().addDays(7);
        insert parentProject;

        testPhase = new Project__c();
        testPhase.RecordTypeId = recordTypeMap.get(PROJECT_TYPE_PHASE_SAAS);
        testPhase.Phase_Status__c = 'Open';
        testPhase.ParentProject__c = parentProject.Id;
        insert testPhase;
    }
}