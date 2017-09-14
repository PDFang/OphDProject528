@istest
public class LicenseTriggerTest {

    public static void setup(){
    	Account acct = new Account(Name = 'test',
                                   BillingCity = 'SLC',
                                   BillingState = 'UT',
                                   BillingCountry = 'US',
                                   BillingStreet = 'test street',
              			    	   BillingPostalCode = '12345' 
                                  );
        
        insert acct;
        
        //Create package
        sfLma__Package__c pack = new sfLma__Package__c(
            Name = 'test',
            sfLma__Developer_Name__c = 'test',
            sfLma__Developer_Org_ID__c = 'abc',
            sfLma__Latest_Version__c = '3',
            sfLma__Lead_Manager__c = UserInfo.getUserId(),
            sfLma__Package_ID__c = '3',
            sfLma__Release_Date__c = system.today().addDays(-30)
        );
        insert pack;
        
        //Create a package version
        sfLma__Package_Version__c packVersion = new sfLma__Package_Version__c(
            Name = 'test',
            sfLma__Package__c = pack.id,
            sfLma__Is_Beta__c = false,
            sfLma__Release_Date__c = system.today(),
            sfLma__Sequence__c = 1,
            sfLma__Version__c = '3.1.2',
            sfLma__Version_ID__c = '3.1.2'
        );
        insert packVersion;
        
        //Ceate a license record
        
        Id recordTypeIdTrial = [select Id from RecordType where Name = 'Trial' and SobjectType = 'sfLma__License__c'].Id;
        
        sfLma__License__c lic = new sfLma__License__c(
            RecordTypeId = recordTypeIdTrial,
            sfLma__Status__c = 'Trial',
            sfLma__Seats__c = 10,
            //sfLma__Used_Licenses__c = 10,
            sfLma__License_Type__c = 'Editable',
            sfLma__Account__c = acct.Id,
            sfLma__Expiration__c = Date.newInstance(1970, 1, 1),// system.today().addDays(365),
            sfLma__Install_Date__c = system.today(),
            sfLma__Package_Version__c = packVersion.Id,
            sfLma__Org_Instance__c = 'NA1',
            sfLma__Version_Number__c = '1',
			sfLma__Subscriber_Org_ID__c = '00D5B0000008bOp',
			sfLma__Proxy_User__c = '033i0000000ty0uaas@00ds0000003eehamaw'            
        );
        insert lic;	 
        
        // insert Contract 
        CHANNEL_ORDERS__Partner_Contract_Terms__c cont = new CHANNEL_ORDERS__Partner_Contract_Terms__c(
        	Name = 'inContact_ISVForce_USD',
            CHANNEL_ORDERS__Partner_API_Key__c = 'a7bdgbdjbgf84',
            CHANNEL_ORDERS__Default_Contract_Currency__c = 'USD'            
        );
        
        insert cont;
        
        CHANNEL_ORDERS__Partner_Product_Catalog__c prod = new CHANNEL_ORDERS__Partner_Product_Catalog__c(
			Name = 'ISVForce inContact Agent Console (Per User)',
			CHANNEL_ORDERS__Product_ID__c = 'test',
			CHANNEL_ORDERS__Partner_Contract_Terms__c = cont.Id            
        );
        
        insert prod;
        
        
        
        
    }
    public static testmethod void insertCustomerTest(){
        //Create account license can be attached to
		LicenseTriggerTest.setup();
        
       test.startTest();
        sfLma__License__c lic = [select Id, sfLma__Status__c, RecordTypeId from sfLma__License__c Limit 1];
        Id recordTypeId = [select Id from RecordType where Name = 'Active' and SobjectType = 'sfLma__License__c'].Id;
        
        lic.sfLma__Status__c = 'Active';
        lic.RecordTypeId = recordTypeId;
        update lic;
        
        CHANNEL_ORDERS__Customer__c cor = [select CHANNEL_ORDERS__Customer_Country__c from CHANNEL_ORDERS__Customer__c limit 1];
        system.assertEquals('US', cor.CHANNEL_ORDERS__Customer_Country__c); 
        CHANNEL_ORDERS__Service_Order__c so = [select CHANNEL_ORDERS__Customer_Org_ID__c from CHANNEL_ORDERS__Service_Order__c where CHANNEL_ORDERS__Customer__c =: cor.Id Limit 1];
       // system.assertEquals('00D5B0000008bOp', so.CHANNEL_ORDERS__Customer_Org_ID__c);
		CHANNEL_ORDERS__Service_Order_Detail__c sod = [select CHANNEL_ORDERS__Quantity__c from CHANNEL_ORDERS__Service_Order_Detail__c where CHANNEL_ORDERS__Product_Name__r.Name =: 'ISVForce inContact Agent Console (Per User)' Limit 1];
     //   system.assertEquals(10, sod.CHANNEL_ORDERS__Quantity__c);
       test.stopTest();
    }
    public static testmethod void existingCustomerTest(){
                
        
         LicenseTriggerTest.setup();
         //insert the customer
         CHANNEL_ORDERS__Customer__c cust = new CHANNEL_ORDERS__Customer__c(
             CHANNEL_ORDERS__Customer_City__c = 'SLC',
             CHANNEL_ORDERS__Customer_State__c = 'UT',
         	 CHANNEL_ORDERS__Customer_Country__c = 'US',
             CHANNEL_ORDERS__Customer_ZIP_Postal_Code__c = '12345',
             CHANNEL_ORDERS__Customer_Company_Name__c = 'test',
             CHANNEL_ORDERS__Customer_Street__c = 'test',
             CHANNEL_ORDERS__Customer_Org_ID__c = '00D5B0000008bOp'
         );
        
        insert cust;
        
       test.startTest();
        sfLma__License__c lic = [select Id, sfLma__Status__c, RecordTypeId from sfLma__License__c Limit 1];
        Id recordTypeId = [select Id from RecordType where Name = 'Active' and SobjectType = 'sfLma__License__c'].Id;
        
        
        lic.sfLma__Status__c = 'Active';
        lic.RecordTypeId = recordTypeId;
        
        update lic;
        
       integer customerCount = [select count() from CHANNEL_ORDERS__Customer__c];
       system.assertEquals(1, customerCount);  
        
       CHANNEL_ORDERS__Service_Order__c so = [select CHANNEL_ORDERS__Customer_Org_ID__c from CHANNEL_ORDERS__Service_Order__c where CHANNEL_ORDERS__Customer__c =: cust.Id Limit 1];
       //system.assertEquals('00D5B0000008bOp', so.CHANNEL_ORDERS__Customer_Org_ID__c);
	   CHANNEL_ORDERS__Service_Order_Detail__c sod = [select CHANNEL_ORDERS__Quantity__c from CHANNEL_ORDERS__Service_Order_Detail__c where CHANNEL_ORDERS__Product_Name__r.Name =: 'ISVForce inContact Agent Console (Per User)' Limit 1];
       //system.assertEquals(10, sod.CHANNEL_ORDERS__Quantity__c);
        EDA__c[] edaRecord = [select Id, License__c from EDA__c];
	    system.debug('edaRecord =>' + edaRecord);

        //system.assertEquals(lic.Id, edaRecord[0].License__c, 'Matching License found');
      test.stopTest();  
    }
    public static testmethod void existingOrderTest(){
                
        
         LicenseTriggerTest.setup();
         //insert the customer
         CHANNEL_ORDERS__Customer__c cust = new CHANNEL_ORDERS__Customer__c(
             CHANNEL_ORDERS__Customer_City__c = 'SLC',
             CHANNEL_ORDERS__Customer_State__c = 'UT',
         	 CHANNEL_ORDERS__Customer_Country__c = 'US',
             CHANNEL_ORDERS__Customer_ZIP_Postal_Code__c = '12345',
             CHANNEL_ORDERS__Customer_Company_Name__c = 'test',
             CHANNEL_ORDERS__Customer_Street__c = 'test',
             CHANNEL_ORDERS__Customer_Org_ID__c = '00D5B0000008bOp'
         );
        
         insert cust;
        
         Id ContId = [select Id from CHANNEL_ORDERS__Partner_Contract_Terms__c limit 1].Id;
        
         CHANNEL_ORDERS__Service_Order__c so = new CHANNEL_ORDERS__Service_Order__c(
              CHANNEL_ORDERS__Order_Type__c = 'Initial',   
              CHANNEL_ORDERS__Service_Start_Date__c = system.today(),
              CHANNEL_ORDERS__Partner_Contract_Rules__c = ContId,
              CHANNEL_ORDERS__Customer_Org_ID__c = '00D5B0000008bOp',
              CHANNEL_ORDERS__Customer__c = cust.Id,
              CHANNEL_ORDERS__Date_Partner_Received_Customer_Order__c = system.today(),
              CHANNEL_ORDERS__Date_Customer_Accepted_SFDC_Svc_Agrmnt__c = system.today()
         );
        
         insert so;
        
         test.startTest();
         sfLma__License__c lic = [select Id, sfLma__Status__c, RecordTypeId from sfLma__License__c Limit 1];
         Id recordTypeId = [select Id from RecordType where Name = 'Active' and SobjectType = 'sfLma__License__c'].Id;
        
        
         lic.sfLma__Status__c = 'Active';
        update lic;
         lic.RecordTypeId = recordTypeId;
        update lic;
         
        
         integer customerCount = [select count() from CHANNEL_ORDERS__Customer__c];
         system.assertEquals(1, customerCount);  
         
         integer orderCount = [select count() from CHANNEL_ORDERS__Service_Order__c];
         //system.assertEquals(2, orderCount);  
         test.stopTest();  
    }
    public static testmethod void licenseAddOnTest(){
        
         LicenseTriggerTest.setup();
         //insert the customer
         CHANNEL_ORDERS__Customer__c cust = new CHANNEL_ORDERS__Customer__c(
             CHANNEL_ORDERS__Customer_City__c = 'SLC',
             CHANNEL_ORDERS__Customer_State__c = 'UT',
         	 CHANNEL_ORDERS__Customer_Country__c = 'US',
             CHANNEL_ORDERS__Customer_ZIP_Postal_Code__c = '12345',
             CHANNEL_ORDERS__Customer_Company_Name__c = 'test',
             CHANNEL_ORDERS__Customer_Street__c = 'test',
             CHANNEL_ORDERS__Customer_Org_ID__c = '00D5B0000008bOp'
         );
        
         insert cust;
        
		  test.startTest();
         sfLma__License__c lic = [select Id, sfLma__Status__c, RecordTypeId from sfLma__License__c Limit 1];
         
        lic.sfLma__Status__c = 'Active';
          update lic;
         LMAHelperClass.isLMAHelperClassCalled = false;
         lic.sfLma__Seats__c = 30;
        
         update lic;
        
         CHANNEL_ORDERS__Service_Order_Detail__c sod = [select CHANNEL_ORDERS__Quantity__c from CHANNEL_ORDERS__Service_Order_Detail__c 
                                                       where CHANNEL_ORDERS__Partner_Order__r.CHANNEL_ORDERS__Order_Type__c =:'Add-On' limit 1];
         system.assertEquals(20, sod.CHANNEL_ORDERS__Quantity__c);  
         
         CHANNEL_ORDERS__Service_Order__c so = [select CHANNEL_ORDERS__Order_Type__c from CHANNEL_ORDERS__Service_Order__c where CHANNEL_ORDERS__Order_Type__c =:'Add-On' limit 1]; 	
         
	     system.assertEquals('Add-On', so.CHANNEL_ORDERS__Order_Type__c);

	    EDA__c[] edaRecord = [select Id, License__c from EDA__c];
	    system.debug('edaRecord =>' + edaRecord);

	   // system.assertEquals(3, edaRecord.size(), '3 Service orders found');

         test.stopTest();  
    }
    public static testmethod void licenseReductiOnTest(){
        
         LicenseTriggerTest.setup();
         //insert the customer
         CHANNEL_ORDERS__Customer__c cust = new CHANNEL_ORDERS__Customer__c(
             CHANNEL_ORDERS__Customer_City__c = 'SLC',
             CHANNEL_ORDERS__Customer_State__c = 'UT',
         	 CHANNEL_ORDERS__Customer_Country__c = 'US',
             CHANNEL_ORDERS__Customer_ZIP_Postal_Code__c = '12345',
             CHANNEL_ORDERS__Customer_Company_Name__c = 'test',
             CHANNEL_ORDERS__Customer_Street__c = 'test',
             CHANNEL_ORDERS__Customer_Org_ID__c = '00D5B0000008bOp'
         );
        
         insert cust;
        
		  test.startTest();
         sfLma__License__c lic = [select Id, sfLma__Status__c, RecordTypeId from sfLma__License__c Limit 1];
         
        lic.sfLma__Status__c = 'Active';
          update lic;
        LMAHelperClass.isLMAHelperClassCalled = false;
         lic.sfLma__Seats__c = 5;
        
         update lic;
        
         CHANNEL_ORDERS__Service_Order_Detail__c sod = [select CHANNEL_ORDERS__Quantity__c from CHANNEL_ORDERS__Service_Order_Detail__c 
                                                       where CHANNEL_ORDERS__Partner_Order__r.CHANNEL_ORDERS__Order_Type__c =:'Reduction' limit 1];
         system.assertEquals(-5, sod.CHANNEL_ORDERS__Quantity__c);  
         
         CHANNEL_ORDERS__Service_Order__c so = [select CHANNEL_ORDERS__Order_Type__c from CHANNEL_ORDERS__Service_Order__c
                                                where CHANNEL_ORDERS__Order_Type__c =:'Reduction' limit 1]; 	
         
          system.assertEquals('Reduction', so.CHANNEL_ORDERS__Order_Type__c);  
         test.stopTest();  
    }
    public static testmethod void licenseExpireTest(){
       LicenseTriggerTest.setup();
         //insert the customer
         CHANNEL_ORDERS__Customer__c cust = new CHANNEL_ORDERS__Customer__c(
             CHANNEL_ORDERS__Customer_City__c = 'SLC',
             CHANNEL_ORDERS__Customer_State__c = 'UT',
         	 CHANNEL_ORDERS__Customer_Country__c = 'US',
             CHANNEL_ORDERS__Customer_ZIP_Postal_Code__c = '12345',
             CHANNEL_ORDERS__Customer_Company_Name__c = 'test',
             CHANNEL_ORDERS__Customer_Street__c = 'test',
             CHANNEL_ORDERS__Customer_Org_ID__c = '00D5B0000008bOp'
         );
        
         insert cust;
         
         test.startTest();
         
         sfLma__License__c lic = [select Id, sfLma__Expiration_Date__c, RecordTypeId from sfLma__License__c Limit 1];
         
        
         lic.sfLma__Status__c = 'Active';
         update lic;
        LMAHelperClass.isLMAHelperClassCalled = false;
         lic.sfLma__Expiration__c = system.today();
             update lic;
         CHANNEL_ORDERS__Service_Order__c sod = [select CHANNEL_ORDERS__Order_Type__c from CHANNEL_ORDERS__Service_Order__c 
                                                       where CHANNEL_ORDERS__Order_Type__c =:'Cancellation Order' limit 1];
         system.assertEquals('Cancellation Order', sod.CHANNEL_ORDERS__Order_Type__c);  
         
        
         test.stopTest();
         
    }
   
    public static testMethod void ExpireAccounts(){
        LicenseTriggerTest.setup();
        //insert the customer
        CHANNEL_ORDERS__Customer__c cust = new CHANNEL_ORDERS__Customer__c(
             CHANNEL_ORDERS__Customer_City__c = 'SLC',
             CHANNEL_ORDERS__Customer_State__c = 'UT',
         	 CHANNEL_ORDERS__Customer_Country__c = 'US',
             CHANNEL_ORDERS__Customer_ZIP_Postal_Code__c = '12345',
             CHANNEL_ORDERS__Customer_Company_Name__c = 'test',
             CHANNEL_ORDERS__Customer_Street__c = 'test',
             CHANNEL_ORDERS__Customer_Org_ID__c = '00D5B0000008bOp'
         );
        
        insert cust;
        test.startTest();
         
        sfLma__License__c lic = [select Id, sfLma__Expiration_Date__c, RecordTypeId from sfLma__License__c Limit 1];
         
         lic.sfLma__Status__c = 'Active';
         update lic;
          LMAHelperClass.isLMAHelperClassCalled = false;
         Account testAct = [select Id,CG_Disconnect_Date__c  from Account Limit 1];
         
         testAct.CG_Disconnect_Date__c = system.today();
        
         update testAct;
        
         CHANNEL_ORDERS__Service_Order__c sod = [select CHANNEL_ORDERS__Order_Type__c from CHANNEL_ORDERS__Service_Order__c 
                                                       where CHANNEL_ORDERS__Order_Type__c =:'Cancellation Order' limit 1];
        
         system.assertEquals('Cancellation Order', sod.CHANNEL_ORDERS__Order_Type__c);  
        test.stopTest(); 
        
    } 
    
}