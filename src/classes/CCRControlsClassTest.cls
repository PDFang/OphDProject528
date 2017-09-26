@isTest
private class CCRControlsClassTest {

    static testMethod void ValidateCCRCOntrols() {
        BMCServiceDesk__Change_Request__c changeRequest = TestUtilities.createRFChangeRequest();
       	insert changeRequest;
       	TestUtilities.insertCCRControlCustomSetting();
       	//Call ChangeControlRequest object
        ChangeControlRequest__c changeControlRequest = 
       						new ChangeControlRequest__c(Summary__c = 'Testing CCRs', 
       															  CCRStartTime__c= system.today(),
       															  ChangeReason__c = 'Fix'  ,
       															  Monitoring_set_up_on_device__c='Yes',
       															  Impact__c = 'SEV 1',
       															  Urgency__c = 'HIGH',
       															  RFCType__c = 'NORMAL',
       															  Cluster__c = 'B2;B3',
																  ReleasePicklist__c = 'Architecture',
       															  ContingencyOwner__c = userInfo.getUserId(),
       															  ContingencyDeadline__c = system.today()+ 4,
       															  Description__c = 'Test summary',
       															  DescriptionOfTesting__c = 'Test summary',
       															  ContingencyPlan__c = 'Test summary',
       															  ReleaseDate__c = system.today() +4,
       															  SystemsAppsProcessesImpacted__c = 'Test summary',
       															  Experience__c = '0 - This has been successfully completed before',
       															  PrepTimeRequired__c = '3 - 15-30 days',
       															  RequiresUserEducation__c = '2 - Minimal',
       															  BusinessImpact__c ='3 - Major, not high profile' ,
       															  Documentation__c = '4 - Considerable amount',
       															  ResourcesRequired__c = '2 - 2 people, same group',
       															  MaintenanceWindow__c = '8 - Outside',
       															  Security__c = '2 - Access affected',
       															  Validation__c = '3 - Minor',
       															  Backout__c = '2 - In place, easy to do',
       															  OutageScope__c = '6 - Partial System'
       															  );
  
       insert changeControlRequest; 
       RecordType rt = [select Id from RecordType where Name = 'Communication Task' and SobjectType = 'CCRTask__c'];
       CCRTask__c task123 = new CCRTask__c(Order__c = 1,
       													AssignedTo__c = userinfo.getUserId(),
       													Description__c = 'Validation',
       													Duration__c = 1,
       													Status__c = 'OPEN',
       													RecordTypeID = rt.id,
       													ChangeControlRequest__c = changeControlRequest.Id);
       insert task123;
       BMCServiceDesk__Status__c statusvalop = [Select Id,Name from BMCServiceDesk__Status__c where Name='OPENED'];
       	List<BMCServiceDesk__Task__c> tasks = TestUtilities.createRFTaskRecords(changeRequest,statusvalop.Id); 
       	insert tasks;
       	
        CCRControlsClass ccrCont = new CCRControlsClass('NetworkNew');
        Set<String> status1 = CCRControlsClass.openStatuses1;
        
        Set<String> status2 = ccrCont.openStatuses;
        ccrCont.IsCCBMasterMember(userInfo.getUserId());
        ccrCont.SendTaskEmail(changeControlRequest.Id,'TestSubject');
        ccrCont.SendSingleTaskEmail(task123.Id,'TestSubject');
        ccrCont.SendTaskEmailForRfChangeRequest(changeRequest.Id,'TestSubject');
        ccrCont.SendSingleTaskEmailForRfChangeRequest(tasks[1].Id,'TestSubject');
        CCRControlsClass.ChangeControlRequestId();
        CCRControlsClass.ChangeRequestId();
        
    }
}