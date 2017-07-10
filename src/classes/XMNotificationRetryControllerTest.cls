/**
 * Created by mohandaas.rangaswamy on 7/10/2017.
 */

@IsTest
private class XMNotificationRetryControllerTest {

    static testMethod void testBehavior() {

        Test.startTest();

        Test.setCurrentPage(Page.XMNotificationRetry);
        ApexPages.currentPage().getParameters().put('caseId', null);

        XMNotificationRetryController controller = new XMNotificationRetryController();

        ApexPages.hasMessages(ApexPages.Severity.ERROR);

        Test.stopTest();

    }
}