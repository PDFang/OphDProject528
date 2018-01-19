/**
 * Created by ravish.chawla on 1/16/2018.
 */

@IsTest
private class CSOCaseOrderDetailControllerTest {

    static Group groupTest = null;
    static Account accountTest = null;
    static Contact contactTest = null;
    static Case caseTest = null;
    static Case caseTest1 = null;
    static CustomerOrder__c customerOrderTest = null;
    static OrderLineGeneralItems__c orderLineGeneralItemsTest = null;
    static OrderLineGeneralItems__c childOrderLineGeneralItemsTest = null;
    static OrderLineSpecificItem__c orderLineSpecificItemTest = null;
    static CSOOrderResolutionColumnMapping__c csoOrderResolutionColumnMappingTest = null;
    static Id idTest;
    static CaseComment caseCommentTest = null;

    static testMethod void CSOCaseActionCompTest() {
        createTestData();
        Test.startTest();
        Test.setCurrentPage(Page.CSOCaseOrderDetail);

        ApexPages.currentPage().getParameters().put('id', caseTest.Id);
        CSOCaseActionCompController csoCaseActionCompContrTest = new CSOCaseActionCompController();
        Id copQueueId = '00G70000002CaKC';

        string commentTest = CSOCaseActionCompController.saveCaseComment( 'This is from test class', false, caseTest.Id);
        system.assertEquals('Success', commentTest);
        commentTest = CSOCaseActionCompController.saveCaseComment( '', false, caseTest.Id);
        system.assertEquals('Empty comments are not allowed to save.', commentTest);

        string commentTestError = CSOCaseActionCompController.saveCaseComment( 'This is from test class', false, 'test');

        string sendToCOPTest = CSOCaseActionCompController.SendToCOPQueue( copQueueId, caseTest.Id);
        system.assertEquals('Success', sendToCOPTest);

        string sendToCOPTestError = CSOCaseActionCompController.SendToCOPQueue( copQueueId, 'Test');

        string closeCaseTest = CSOCaseActionCompController.closeCSOCase( 'Access', caseTest.Id);
        system.assertEquals('Success', closeCaseTest);

        string closeCaseTestError = CSOCaseActionCompController.closeCSOCase( 'Access', 'Test');

        Test.stopTest();

    }


    static testMethod void CSOOrderActionCompTest() {
        createTestData();
        Test.startTest();
        Test.setCurrentPage(Page.CSOCaseOrderDetail);

        ApexPages.currentPage().getParameters().put('id', caseTest.Id);
        CSOOrderActionCompController CSOOrderActionCompContrTest = new CSOOrderActionCompController();
        String testItemStatus = CSOOrderActionCompContrTest.ItemStatus;
        String testPOPSite = CSOOrderActionCompContrTest.POPSite;

        string orderDetailTest = CSOOrderActionCompController.getCurrentOrderDetails(caseTest.Id);
        system.assertNotEquals(null, orderDetailTest);

        string orderDetailTestError = CSOOrderActionCompController.getCurrentOrderDetails('test');

        string saveCommentTest = CSOOrderActionCompController.saveComment( 'Test Comment', false, orderLineGeneralItemsTest.Id, caseTest.Id);
        system.assertEquals('Success', saveCommentTest);

        string saveCommentErrorTest = CSOOrderActionCompController.saveComment( null, false, orderLineGeneralItemsTest.Id, caseTest.Id);
        system.assertEquals('Empty comments are not allowed to save.', saveCommentErrorTest);
        saveCommentErrorTest = CSOOrderActionCompController.saveComment( 'Test Comment', false, orderLineGeneralItemsTest.Id,'Test');

        string updateStatusTest = CSOOrderActionCompController.updateStatus( 'Completed', orderLineGeneralItemsTest.Id, caseTest.Id, false);
        system.assertEquals('Success', updateStatusTest);
        updateStatusTest = CSOOrderActionCompController.updateStatus( 'Completed', orderLineGeneralItemsTest.Id, caseTest.Id, true);
        system.assertEquals('Success', updateStatusTest);
        string updateStatusErrorTest = CSOOrderActionCompController.updateStatus( '', orderLineGeneralItemsTest.Id, caseTest.Id, false);
        system.assertEquals('Invalid Staus.', updateStatusErrorTest);
        updateStatusErrorTest = CSOOrderActionCompController.updateStatus( 'Completed', orderLineGeneralItemsTest.Id, 'Test', false);

        string specificItemsTest = CSOOrderActionCompController.updatePOPSite( 'Access', orderLineGeneralItemsTest.Id);
        system.assertEquals('Success', specificItemsTest);
        specificItemsTest = CSOOrderActionCompController.updatePOPSite( '', orderLineGeneralItemsTest.Id);
        system.assertEquals('Invalid POP.', specificItemsTest);
        string specificItemsErrorTest = CSOOrderActionCompController.updatePOPSite( 'Access', 'Test');

        Test.stopTest();

    }

    static testMethod void CSOCaseOrderDetailTest() {
        createTestData();
        Test.startTest();
        Test.setCurrentPage(Page.CSOCaseOrderDetail);

        ApexPages.currentPage().getParameters().put('id', caseTest.Id);
        CSOCaseOrderDetailHelper csoCaseOrderDetailHelperTest = new CSOCaseOrderDetailHelper(caseTest.Id);
        CSOCaseOrderDetailController CSOCaseOrderDetailCntrlTest = new CSOCaseOrderDetailController();
        Boolean hasorderTest = CSOCaseOrderDetailCntrlTest.getHasNoOrder();
        list<CSOCaseOrderDetailController.CSOCaseComment> commentsTest = CSOCaseOrderDetailCntrlTest.comments;
        Case CurrentCaseTest = CSOCaseOrderDetailCntrlTest.CurrentCase;

        ApexPages.currentPage().getParameters().put('id', caseTest1.Id);
        CSOCaseOrderDetailController CSOCaseOrderDetailCntrlTest1 = new CSOCaseOrderDetailController();
        CSOCaseOrderDetailHelper csoCaseOrderDetailHelper1 = new CSOCaseOrderDetailHelper(caseTest1.Id);
        CSOCaseOrderDetailHelper.getFieldList();


        Test.stopTest();
    }

    static void createTestData(){
        groupTest = [select Id from Group where DeveloperName = 'TechSupportQueue' limit 1];
        idTest = '00G70000001ciT7';
        accountTest = inContactBaseClass.CreateAccount('testName');
        insert accountTest;

        contactTest = inContactBaseClass.CreateContact(accountTest.Id, 'firstName', 'lastName', 'email@test.com');
        insert contactTest;

        customerOrderTest = new CustomerOrder__c(
                Customer__c = accountTest.Id,
                Contact__c = contactTest.id,
                OrderDateTime__c = System.now(),
                OrderStatus__c = 'failed',
                Username__c = 'JusticeLeague_i'
        );

        insert customerOrderTest;

        orderLineGeneralItemsTest = new OrderLineGeneralItems__c(
                CustomerOrder__c = customerOrderTest.Id,
                ItemStatus__c = 'New',
                InstrumentType__c = 12554,
                InstrumentTypeName__c = 'SOFTPHONE LICENSE',
                StartDate__c = System.now()
        );

        insert OrderLineGeneralItemsTest;

        childOrderLineGeneralItemsTest = new OrderLineGeneralItems__c(
                CustomerOrder__c = customerOrderTest.Id,
                ItemStatus__c = 'New',
                InstrumentType__c = 12554,
                RelatedLineItem__c = orderLineGeneralItemsTest.Id,
                InstrumentTypeName__c = 'SOFTPHONE LICENSE',
                StartDate__c = System.now()
        );

        insert childOrderLineGeneralItemsTest;

        orderLineSpecificItemTest = new OrderLineSpecificItem__c(
                ItemValue__c = 'testPOP',
                OrderLineGeneralItem__c = orderLineGeneralItemsTest.Id,
                SpecificItem__c = 'POP'

        );

        insert orderLineSpecificItemTest;

        csoOrderResolutionColumnMappingTest = new CSOOrderResolutionColumnMapping__c(
                CSO_Resolution_Type__c = 'DID - Add - Manual Process',
                DisplayColumns__c = 'Rate Center; State; NPA; NXX; Quantity',
                Display_Buttons__c = 'Add Comment; Update Status',
                Line_Item_Status__c = 'Retry; Backordered; Canceled; Completed',
                Threshold_Exceeds_Message__c = ''
        );

        insert csoOrderResolutionColumnMappingTest;

        caseTest = inContactBaseClass.CreateCase(accountTest.Id, contactTest.Id, inContactBaseClass.SelectRecordTypeIDByName('Work Orders', 'Case'), 'Test Subject');
        caseTest.OwnerId =idTest;
        caseTest.Origin = 'Web';
        caseTest.Severity__c = 'S1';
        caseTest.Priority = 'P1';
        caseTest.CustomerOrder__c = customerOrderTest.Id;
        caseTest.CSO_Resolution_Type__c = csoOrderResolutionColumnMappingTest.CSO_Resolution_Type__c;

        insert caseTest;

        caseCommentTest = new CaseComment(
                CommentBody = 'Test',
                ParentId = caseTest.Id,
                IsPublished = false
        );

        insert caseCommentTest;

        caseTest1 = inContactBaseClass.CreateCase(accountTest.Id, contactTest.Id, inContactBaseClass.SelectRecordTypeIDByName('Work Orders', 'Case'), 'Test Subject');
        caseTest1.OwnerId =idTest;
        caseTest1.Origin = 'Web';
        caseTest1.Severity__c = 'S1';
        caseTest1.Priority = 'P1';

        insert caseTest1;
    }
}