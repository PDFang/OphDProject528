@isTest
public class TestUtilities
{

    public static Account CreateAccount(string name, id recordTypeId, boolean isInserted)
    {
        Account a = CreateAccount(name, false);
        a.RecordTypeId = recordTypeId;
        
        if(isInserted)
        {
            insert a;
    	}
        
        return a;
    }
    
    public static Account CreateAccount(string name, boolean isInserted)
    {
        Account a = new Account();
        a.Name = name;
        
        if(isInserted)
        {
            insert a;
    	}
        
        return a;
    }
    
    
	
	public static Contact CreateContact(string accountId, string firstName, string lastName, string email, boolean isInserted)
	{
		Contact c = new Contact();
		c.AccountId = accountId;
		c.FirstName = firstName;
		c.LastName = lastName;
		c.Email = email;
		
        
        if(isInserted)
        {
            insert c;
    	}
        
		return c;
	}
    
    
	
	public static Contact CreateContact(string accountId, string firstName, string lastName, string email, string recordTypeId, boolean isInserted)
	{
		Contact c = new Contact();
		c.AccountId = accountId;
		c.FirstName = firstName;
		c.LastName = lastName;
		c.Email = email;
		c.RecordTypeId = recordTypeId;
		
        
        if(isInserted)
        {
            insert c;
    	}
        
		return c;
	}
    
    
	
	public static Case CreateCase(string accountId, string contactId, string recordTypeId, string subject)
	{
		//set default assignment rule       
        database.DMLOptions dmo = new database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
		
		
		Case c = new Case();
		c.AccountId = accountId;
		c.ContactId = contactId;
		c.RecordTypeId = recordTypeId;
		c.Subject = subject;
		
		c.setOptions(dmo);
		
		return c;
	}
    
    public static GYR__c CreateGyr(Id accountId, string status, boolean isInserted)
    {
        GYR__c gyr = new GYR__c();
        gyr.Account__c = accountId;
        gyr.GYRStartDate__c = system.today();
        gyr.GYRStatus__c = status;
        gyr.ReasonCategory__c = 'reason-category';
        
        if(isInserted)
        {
            insert gyr;
        }
        
        return gyr;
    }
    
    
    public static void CreateTfsAssignment(string name, string team)
    {
        TfsAssignment__c existing = tfsAssignment__c.getValues(name);
        
        if(existing == null)
        {
            TfsAssignment__c tfs = new TfsAssignment__c();
            tfs.Name = name;
            tfs.Team__c = team;
            
            insert tfs;
        }
    }
    public static void insertCCRControlCustomSetting(){
    	insert new CCRControls__c(Name = 'NetworkNew',
        						  AdminstratorReviewQueue__c = '00G70000001fnfb',
        						  BypassMasterReview__c = false,
        						  CalendarImgUrl__c = 'https://images.ucn.net/salesforce/red.png',
        						  CCBBoardRecordTypeID__c = '01239000000UQoi',
        						  CCBMasterRecordTypeID__c = '01239000000UQog',
        						  CCBMastersQueue__c = '00G70000001fnfb',
        						  CCBMembersGroupId__c = '00G70000001fnfc',
        						  CCRApprovedRecordTypeID__c = '01239000000UQoh',
        						  CCRClosedRecordTypeID__c	= '01239000000UQoj',
        						  CCRDeployedRecordTypeID__c = '01239000000UQok',
        						  CCRSpecialQueueId__c = '',
        						  ChecklistUrl__c = 'http://mojo/itdev/Documents/Release%20Deliverables%20Checklist%20Template.docx',
        						  CustomerImpact__c = false,
        						  EmailHeaderURL__c = 'https://images.ucn.net/Email/network-product-banner.png',
        						  Environment__c = 'PRODUCTION',
        						  MaintenanceWindow__c = true,
        						  NewRecordTypeID__c = '01239000000UQof',
        						  NumberOfApproversRequired__c = 3,
        						  PeerReviewRecordTypeId__c = '01239000000UQol',
        						  RequireChecklist__c = true,
        						  RequirePeerReview__c = true,
        						  RequirePlanAttachments__c = true);
    
    }
    
    public static BMCServiceDesk__Change_Request__c createRFChangeRequest(){
    	//Creates a CCR record
    	Map<String,Id> status =  TestUtilities.createRFStatusRecords();
       BMCServiceDesk__Change_Request__c changeRequest = 
       						new BMCServiceDesk__Change_Request__c(RF_Summary__c = 'Testing CCRs', 
       															  BMCServiceDesk__FKInitiator__c = userInfo.getUserId(),
       															  RF_CCR_Start_Time__c= system.today(),
       															  RF_Change_Reason__c = 'Fix'  ,
       															  RF_Monitoring_set_up_on_device__c='Yes',
       															  HIGH_Profile__c = 'Yes',
       															  ImpactPicklist__c = 'SEV 1',
       															  UrgencyPicklist__c = 'HIGH',
       															  BMCServiceDesk__Change_Type__c = 'NORMAL',
       															  RF_Cluster_s__c = 'B2;B3',
       															  BMCServiceDesk__FKStatus__c = status.get('OPENED'),
       															  ReleasePicklist__c = 'Architecture',
       															  RF_Contingency_Owner__c = userInfo.getUserId(),
       															  RF_Contingency_Deadline__c = system.today()+ 4,
       															  BMCServiceDesk__Change_Description__c = 'Test summary',
       															  RF_Description_of_Testing__c = 'Test summary',
       															  RF_Contingency_Plan__c = 'Test summary',
       															  RF_Release_Date__c = system.today() +4,
       															  RF_System_Apps_Processes_Impacted__c = 'Test summary',
       															  BMCServiceDesk__Reason_for_Change_Details__c = 'Test summary',
       															  RF_Customer_Impact_Analysis__c = 'Test summary',
       															  RF_Escalation_Path__c = 'Test summary',
       															  RF_Deployment_Method__c = 'Manual',
       															  RF_Experience__c = '0 - This has been successfully completed before',
       															  RF_Prep_Time_Required__c = '3 - 15-30 days',
       															  RF_Requires_User_Education__c = '2 - Minimal',
       															  RF_Business_Impact__c ='3 - Major, not high profile' ,
       															  ImpactsBilling__c = 'yes',
       															  RF_Documentation__c = '4 - Considerable amount',
       															  RF_Resources_Required__c = '2 - 2 people, same group',
       															  RF_Maintenance_Window__c = '8 - Outside',
       															  RF_Security__c = '2 - Access affected',
       															  RF_Validation__c = '3 - Minor',
       															  RF_Backout__c = '2 - In place, easy to do',
       															  RF_Outage_Scope__c = '6 - Partial System',
       															  RF_CR_has_been_tested_in_the_Lab__c = 'Yes'
       															  );
  
       return changeRequest; 
    }
    
    public static List<BMCServiceDesk__Urgency__c> createRFUrgencyRecords(){
    	List<BMCServiceDesk__Urgency__c> urgencies = new List<BMCServiceDesk__Urgency__c>();
    	//Creates a CCR record
       BMCServiceDesk__Urgency__c urgency1 = 
       						new BMCServiceDesk__Urgency__c(Name = 'HIGH');
   	   BMCServiceDesk__Urgency__c urgency2 = 
       						new BMCServiceDesk__Urgency__c(Name = 'LOW');
   	   BMCServiceDesk__Urgency__c urgency3 = 
       						new BMCServiceDesk__Urgency__c(Name = 'MEDIUM');
  	   urgencies.add(urgency1);
  	   urgencies.add(urgency2);
  	   urgencies.add(urgency3);
       return urgencies; 
    }
    
    public static List<BMCServiceDesk__Impact__c> createRFImpactRecords(){
    	List<BMCServiceDesk__Impact__c> impacts = new List<BMCServiceDesk__Impact__c>();
    	//Creates a CCR record
       BMCServiceDesk__Impact__c impact1 = 
       						new BMCServiceDesk__Impact__c(Name = 'SEV 1');
   	   BMCServiceDesk__Impact__c impact2 = 
       						new BMCServiceDesk__Impact__c(Name = 'SEV 2');
   	   BMCServiceDesk__Impact__c impact3 = 
       						new BMCServiceDesk__Impact__c(Name = 'SEV 3');
   	   BMCServiceDesk__Impact__c impact4 = 
       						new BMCServiceDesk__Impact__c(Name = 'SEV 4');
  	   impacts.add(impact1);
  	   impacts.add(impact2);
  	   impacts.add(impact3);
  	   impacts.add(impact4);
       return impacts; 
    }
    
    public static List<BMCServiceDesk__Task__c> createRFTaskRecords(BMCServiceDesk__Change_Request__c changeReq,
    																Id status){
    	List<BMCServiceDesk__Task__c> tasks = new List<BMCServiceDesk__Task__c>();
    	//Creates a CCR record
       BMCServiceDesk__Task__c task1 = 
       						new BMCServiceDesk__Task__c(BMCServiceDesk__templateOrder__c = 1,
       													BMCServiceDesk__FKOpenBy__c = userinfo.getUserId(),
       													BMCServiceDesk__taskDescription__c = 'Validation',
       													BMCServiceDesk__duration__c = 1,
       													BMCServiceDesk__FKStatus__c = status,
       													RF_Task_Type__c = 'Validation Task',
       													BMCServiceDesk__FKChange__c = changeReq.Id);
   	   BMCServiceDesk__Task__c task2 = 
       						new BMCServiceDesk__Task__c(BMCServiceDesk__templateOrder__c = 1,
       													BMCServiceDesk__FKOpenBy__c = userinfo.getUserId(),
       													BMCServiceDesk__taskDescription__c = 'Commuinication',
       													BMCServiceDesk__duration__c = 1,
       													BMCServiceDesk__FKStatus__c = status,
       													RF_Task_Type__c = 'Communication Task',
       													BMCServiceDesk__FKChange__c = changeReq.Id);
   	   BMCServiceDesk__Task__c task3 = 
       						new BMCServiceDesk__Task__c(BMCServiceDesk__templateOrder__c = 1,
       													BMCServiceDesk__FKOpenBy__c = userinfo.getUserId(),
       													BMCServiceDesk__taskDescription__c = 'WORK',
       													BMCServiceDesk__duration__c = 1,
       													BMCServiceDesk__FKStatus__c = status,
       													RF_Task_Type__c = 'Work Task',
       													BMCServiceDesk__FKChange__c = changeReq.Id);
  	   tasks.add(task1);
  	   tasks.add(task2);
  	   tasks.add(task3);
  	   
       return tasks; 
    }
    
    public static Map<String,Id> createRFStatusRecords(){
    	List<BMCServiceDesk__Status__c> status = new List<BMCServiceDesk__Status__c>();
    	Map<String,Id> StatusNameId = new Map<String,Id>();
    	
    	//Creates a CCR record
       BMCServiceDesk__Status__c status1 = new BMCServiceDesk__Status__c(Name = 'OPENED',
       																	 BMCServiceDesk__appliesToTask__c= true,
       																	 BMCServiceDesk__appliesToChange__c = true);
   	   BMCServiceDesk__Status__c status2 = new BMCServiceDesk__Status__c(Name = 'APPROVED',BMCServiceDesk__appliesToTask__c= true,
       																	 BMCServiceDesk__appliesToChange__c = true);
   	   BMCServiceDesk__Status__c status3 = new BMCServiceDesk__Status__c(Name = 'DEPLOYED',BMCServiceDesk__appliesToTask__c= true,
       																	 BMCServiceDesk__appliesToChange__c = true);
   	   BMCServiceDesk__Status__c status4 = new BMCServiceDesk__Status__c(Name = 'PEER REVIEW',BMCServiceDesk__appliesToTask__c= true,
       																	 BMCServiceDesk__appliesToChange__c = true);
   	   BMCServiceDesk__Status__c status5 = new BMCServiceDesk__Status__c(Name = 'ADMINISTRATOR REVIEW',BMCServiceDesk__appliesToTask__c= true,
       																	 BMCServiceDesk__appliesToChange__c = true);
   	   BMCServiceDesk__Status__c status6 = new BMCServiceDesk__Status__c(Name = 'READY FOR DEPLOYMENT',BMCServiceDesk__appliesToTask__c= true,
       																	 BMCServiceDesk__appliesToChange__c = true);
   	   BMCServiceDesk__Status__c status7 = new BMCServiceDesk__Status__c(Name = 'BOARD REVIEW',BMCServiceDesk__appliesToTask__c= true,
       																	 BMCServiceDesk__appliesToChange__c = true);
   	   BMCServiceDesk__Status__c status8 = new BMCServiceDesk__Status__c(Name = 'ADMINISTRATOR REJECTED',BMCServiceDesk__appliesToTask__c= true,
       																	 BMCServiceDesk__appliesToChange__c = true);
   	   BMCServiceDesk__Status__c status9 = new BMCServiceDesk__Status__c(Name = 'TECHNICAL RISK REVIEW',BMCServiceDesk__appliesToTask__c= true,
       																	 BMCServiceDesk__appliesToChange__c = true);
   	   BMCServiceDesk__Status__c status10 = new BMCServiceDesk__Status__c(Name = 'ON_HOLD',BMCServiceDesk__appliesToTask__c= true,
       																	 BMCServiceDesk__appliesToChange__c = true);
   	   BMCServiceDesk__Status__c status11 = new BMCServiceDesk__Status__c(Name = 'TECHNICAL RISK REVIEW REJECTED',BMCServiceDesk__appliesToTask__c= true,
       																	 BMCServiceDesk__appliesToChange__c = true);
   	   BMCServiceDesk__Status__c status12 = new BMCServiceDesk__Status__c(Name = 'CANCELLED',BMCServiceDesk__appliesToTask__c= true,
       																	 BMCServiceDesk__appliesToChange__c = true);
   	   BMCServiceDesk__Status__c status13 = new BMCServiceDesk__Status__c(Name = 'PEER REVIEW REJECTED',BMCServiceDesk__appliesToTask__c= true,
       																	 BMCServiceDesk__appliesToChange__c = true);
   	   BMCServiceDesk__Status__c status14 = new BMCServiceDesk__Status__c(Name = 'CCR FAILED',BMCServiceDesk__appliesToTask__c= true,
       																	 BMCServiceDesk__appliesToChange__c = true);
   	   BMCServiceDesk__Status__c status15 = new BMCServiceDesk__Status__c(Name = 'CLOSED',BMCServiceDesk__appliesToTask__c= true,
       																	 BMCServiceDesk__appliesToChange__c = true);
   	   
  	   status.add(status1);status.add(status2);status.add(status3);
  	   status.add(status4);status.add(status5);status.add(status6);
  	   status.add(status7);status.add(status8);status.add(status9);
  	   status.add(status10);status.add(status11);status.add(status12);
  	   status.add(status13);status.add(status14);status.add(status15);
  	   insert status;
  	   For(BMCServiceDesk__Status__c st : status){
  	   		StatusNameId.put(st.Name,st.Id);
  	   }
       return StatusNameId; 
    }
    
}