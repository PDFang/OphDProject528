@isTest
public class NotificationHelperClassTest {

    static testmethod void testNotification() {
        
        Test.startTest();       
        string caseNumber = '25602';
        Number_Of_Retry__c retry = new Number_Of_Retry__c();    
        retry.Name = 'Enqueued';    
        retry.Retry__c = 0;
        insert retry;
        Test.setMock(WebServiceMock.class, new INotificationProxy());
        NotificationHelperClass.futureCallout(new String[] { 'test@test.com' }, 'test', 'test', 'test', 3);
        Test.stopTest();
        
        // Validate that the job has run 
        retry = new Number_Of_Retry__c();   
        retry = Number_Of_Retry__c.getInstance('Enqueued');
        System.assertNotEquals(0, retry.Retry__c);
        
    }
    
    static testmethod void testNotificationExceedRetry() {
        
        Test.startTest();       
        string caseNumber = '25602';
        Number_Of_Retry__c retry = new Number_Of_Retry__c();    
        retry.Name = 'Enqueued';    
        retry.Retry__c = 3;
        insert retry;
        Test.setMock(WebServiceMock.class, new INotificationProxy());
        NotificationHelperClass.futureCallout(new String[] { 'test@test.com' }, 'test', 'test', 'test', 3);
        Test.stopTest();
        
        // Validate that the job has run 
        retry = new Number_Of_Retry__c();   
        retry = Number_Of_Retry__c.getInstance('Enqueued');
        System.assertEquals(0, retry.Retry__c);
        
    }
}