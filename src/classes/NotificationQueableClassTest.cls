@isTest
public class NotificationQueableClassTest {
    static testmethod void testQueable() {
        
        Id jobId;
        
        // startTest/stopTest block to force async processes 
        //   to run in the test.
        Test.startTest();       
        string caseNumber = '25602';      
        
        NotificationHelperClass.EmailTemplate[] templateList = new NotificationHelperClass.EmailTemplate[]{};        
            NotificationHelperClass.EmailTemplate template1 = new NotificationHelperClass.EmailTemplate();
        templateList.add(template1);
        template1.recipients = new String[]{ 'test@test.com' };
            template1.subject = 'test';
        template1.htmlBody = 'test';
        template1.textBody = 'test';
        template1.templateId = 3;
        template1.isResell = false; //caseNumber;
        NotificationHelperClass.EmailTemplate template2 = new NotificationHelperClass.EmailTemplate();
        templateList.add(template2);
        template2.recipients = new String[]{ 'test@test.com' };
            template2.subject = 'test';
        template2.htmlBody = 'test';
        template2.textBody = 'test';
        template2.templateId = 3;
        template2.isResell = false; //caseNumber;
        Test.setMock(WebServiceMock.class, new INotificationProxy());
        jobId = System.enqueueJob(new NotificationQueableClass(templateList, ''));
        //NotificationHelperClass.futureCallout(new String[] { 'test@test.com' }, 'test', 'test', 'test', 3);
        Test.stopTest();
        
        // Validate that the job has run 
        Number_Of_Retry__c retry = new Number_Of_Retry__c();   
        retry = Number_Of_Retry__c.getInstance(jobId);
        system.debug('retry.Retry__c ==>' + retry.Retry__c);
        System.assertNotEquals(0, retry.Retry__c);
        //System.assertEquals(3, retry.Retry__c);
    }
    
}