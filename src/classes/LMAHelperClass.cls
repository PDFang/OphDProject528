public class LMAHelperClass {

    Public static boolean isLMAHelperClassCalled = false;
    
    public static void CreateCustomer(set<Id> acctIds, list<sfLma__License__c> lstLicenses, map<Id, String> mpOrderType, map<Id, Double> mpSeatNumber)
    {
        
        map<Id, Account> mpAccounts = new map<Id, Account>();
        map<Id, Id> mpCustomerOrgIds = new map<Id, Id>();      
        set<Id> custIds = new set<Id>();       
        list<CHANNEL_ORDERS__Customer__c> lstCusts = new list<CHANNEL_ORDERS__Customer__c>();
        set<string> orgIds = new set<string>();



        // get all orgIds
		for(sfLma__License__c lic : lstLicenses){
	            orgIds.add(lic.sfLma__Subscriber_Org_ID__c);
        }
        
        // get all related account details for the licenses
     	for( Account act : [select Id, BillingCity,BillingState,BillingCountry,BillingStreet,
              			    BillingPostalCode, Name  From Account where Id in : acctIds])
        {
        
             mpAccounts.put(act.Id, act);
    	}   
        
        // find out if there are any existing COA record exist, if yes ignore those.
        mpCustomerOrgIds = LMAHelperClass.getExistingCustomers(orgIds);
        
        
        // loop through all licenses and create the COA records
        for(sfLma__License__c lic : lstLicenses)
        {
            // construct the list of COA to insert.
            if(!mpCustomerOrgIds.containsKey(lic.sfLma__Subscriber_Org_ID__c))
            {
                CHANNEL_ORDERS__Customer__c cust = new CHANNEL_ORDERS__Customer__c();
                Account customer = mpAccounts.get(lic.sfLma__Account__c);
                cust.CHANNEL_ORDERS__Customer_City__c = customer.BillingCity;
                cust.CHANNEL_ORDERS__Customer_State__c = customer.BillingState;
                if(String.isNotBlank(customer.BillingCountry))
                    cust.CHANNEL_ORDERS__Customer_Country__c = customer.BillingCountry.substring(0,2).toUpperCase();
                cust.CHANNEL_ORDERS__Customer_ZIP_Postal_Code__c = customer.BillingPostalCode;
                cust.CHANNEL_ORDERS__Customer_Company_Name__c = customer.Name;
                cust.CHANNEL_ORDERS__Customer_Street__c = customer.BillingStreet;
                cust.CHANNEL_ORDERS__Customer_Org_ID__c = lic.sfLma__Subscriber_Org_ID__c;
                lstCusts.add(cust);
                
            }
            else
            	custIds.add(mpCustomerOrgIds.get(lic.sfLma__Subscriber_Org_ID__c));    
                
        }     
        
        if(lstCusts.size() > 0){
            Database.SaveResult[] lstsr = Database.insert(lstCusts, true);
            
            for(Database.SaveResult sr : lstsr){
               if(sr.isSuccess()) 
                   custIds.add(sr.getId());
            }
        }
       if(custIds.size() > 0)
           insertOrders(custIds, lstLicenses,mpOrderType,mpSeatNumber);
        
        isLMAHelperClassCalled = true;
        
    }
    
    public static  map<Id, Id> getExistingCustomers(set<string> orgIds)
    {
        
         map<Id, Id> mpCustomerOrgIds = new map<Id, Id>();
        
        // get all existing COA records
        for(CHANNEL_ORDERS__Customer__c cust : [select Id,CHANNEL_ORDERS__Customer_Org_ID__c 
                                                from  CHANNEL_ORDERS__Customer__c 
                                                where CHANNEL_ORDERS__Customer_Org_ID__c in : orgIds])
        {
           mpCustomerOrgIds.put(cust.CHANNEL_ORDERS__Customer_Org_ID__c,cust.Id);
                
        }
		return mpCustomerOrgIds;        
    }
    
    public static set<Id> checkExistingOrders(set<Id> custIds, map<Id, string> mpOrderType){
       
        set<Id> existingOrders = new set<Id>();
       
        // get all existing SO records
        for(CHANNEL_ORDERS__Service_Order__c cust : [select Id,CHANNEL_ORDERS__Customer__c, CHANNEL_ORDERS__Order_Type__c,CHANNEL_ORDERS__Customer_Org_ID__c
                                                from  CHANNEL_ORDERS__Service_Order__c 
                                                where CHANNEL_ORDERS__Customer__c in : custIds])
        {
            if(mpOrderType.get(cust.CHANNEL_ORDERS__Customer_Org_ID__c) == cust.CHANNEL_ORDERS__Order_Type__c)
         			existingOrders.add(cust.CHANNEL_ORDERS__Customer__c);   
        } 
        
        return existingOrders;
        
    }
        
        
        
    public static void insertOrders(set<Id> custIds, list<sfLma__License__c> lstLicenses, map<Id, string> mpOrderType, Map<Id, Double> mpSeatNumber){
        set<Id> existingOrders = new set<Id>();
        set<Id> requiredcustomers = new set<Id>();
        list<CHANNEL_ORDERS__Service_Order__c> lstSO = new list<CHANNEL_ORDERS__Service_Order__c>();
        list<CHANNEL_ORDERS__Service_Order_Detail__c> lstSoDetails = new list<CHANNEL_ORDERS__Service_Order_Detail__c>();
        Id productIds;
	    list<EDA__c> EDArecords = new list<EDA__c>();
	    map<Id, list<id>> licenseServiceOrders = new map<Id, list<Id>>();
			    // set the product names
        set<string> productNames = new set<string>{'ISVForce inContact Agent Console (Per User)'};
		set<Id> stNewOrders = new set<Id>();  




       system.debug('productNames ==>' + productNames);
        if(custIds.size() > 0)
        {
        		   
                // get the contract
                CHANNEL_ORDERS__Partner_Contract_Terms__c ct = [select Id from CHANNEL_ORDERS__Partner_Contract_Terms__c where Name =: 'inContact_ISVForce_USD' limit 1];
                // get all the products
                productIds = [select Id, Name from CHANNEL_ORDERS__Partner_Product_Catalog__c 
                              where Name in :productNames limit 1].id;           
                
                // create the orders for each customer
                for(CHANNEL_ORDERS__Customer__c cust: [select Id,CHANNEL_ORDERS__Customer_Org_ID__c 
                                                   from  CHANNEL_ORDERS__Customer__c 
                                                   where Id in : custIds])
                {
                   CHANNEL_ORDERS__Service_Order__c so = new CHANNEL_ORDERS__Service_Order__c(
                       CHANNEL_ORDERS__Order_Type__c = mpOrderType.get(cust.CHANNEL_ORDERS__Customer_Org_ID__c),   
                       CHANNEL_ORDERS__Service_Start_Date__c = system.today(),
                       CHANNEL_ORDERS__Partner_Contract_Rules__c = ct.Id,
                       CHANNEL_ORDERS__Customer_Org_ID__c = cust.CHANNEL_ORDERS__Customer_Org_ID__c,
                       CHANNEL_ORDERS__Customer__c = cust.Id,
                       CHANNEL_ORDERS__Date_Partner_Received_Customer_Order__c = system.today(),
                       CHANNEL_ORDERS__Date_Customer_Accepted_SFDC_Svc_Agrmnt__c = system.today(),
              		   CHANNEL_ORDERS__Service_Order_Status__c = 'Received'
                    );

                 lstSO.add(so);



                }
                
                
        
               if(lstSO.size() > 0)
               {
                    Database.SaveResult[] lstsr = Database.insert(lstSO, true);            
                   // if successfull insert the order details
                    for(Database.SaveResult sr : lstsr)
                    {
                        if(sr.isSuccess()) 
                       		stNewOrders.add(sr.getId());                      
                        
                    }

                   for(CHANNEL_ORDERS__Service_Order__c so : [select Id, CHANNEL_ORDERS__Customer_Org_ID__c
                                                              from CHANNEL_ORDERS__Service_Order__c 
                                                              where Id in :stNewOrders])
                   {
                       
                            CHANNEL_ORDERS__Service_Order_Detail__c sodetail = new CHANNEL_ORDERS__Service_Order_Detail__c();
                            sodetail.CHANNEL_ORDERS__pc_Partner_Contract_Term__c = ct.Id;
                            sodetail.CHANNEL_ORDERS__Partner_Order__c = so.Id;
                            sodetail.CHANNEL_ORDERS__Product_Name__c = productIds;
                            sodetail.CHANNEL_ORDERS__Application__c = 'inContact Agent Console';                       
                            sodetail.CHANNEL_ORDERS__Customer_Price_Per_Month__c = 15;
                            sodetail.CHANNEL_ORDERS__Quantity__c = mpSeatNumber.get(so.CHANNEL_ORDERS__Customer_Org_ID__c);
                            
                            lstSoDetails.add(sodetail);

	                   // Add linecense to orders
	                   for(sfLma__License__c license : lstLicenses){
		                   if(so.CHANNEL_ORDERS__Customer_Org_ID__c ==  license.sfLma__Subscriber_Org_ID__c){
			                   if(licenseServiceOrders.containsKey(license.Id))
				                   licenseServiceOrders.get(license.Id).add(so.Id);
			                   else
					               licenseServiceOrders.put(license.Id, new list<Id>{so.Id});
		                   }
	                   }

                   }

	               if(licenseServiceOrders.size() > 0){
		               for(Id licenseId : licenseServiceOrders.keySet()){
			               for(Id soId : licenseServiceOrders.get(licenseId)){
				               EDA__c eda = new EDA__c();
				               eda.License__c = licenseId;
				               eda.Service_Order__c = soId;
				               EDArecords.add(eda);
			               }
		               }
	               }

                   if(EDArecords.size() > 0){
	                   insert EDArecords;
                   }

                   if(lstSoDetails.size() > 0)
                       insert lstSoDetails;
                }    
            
        }
        
    } 
     
        
        
        
        
    
}