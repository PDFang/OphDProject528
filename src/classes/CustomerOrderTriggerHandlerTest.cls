@IsTest()
private class CustomerOrderTriggerHandlerTest {
	static final String ACCOUNT_TYPE = 'Customers';
    static final string CONTACT_TYPE ='Customer-Other';
    static final decimal ACCOUNT_NUMBER = 4591810;
    static final String ACCOUNT_NAME = 'CustomerOrderTriggerHandlerTest Account';
    static final String Contact_NAME = 'CustomerOrderTriggerHandlerTest Contact';
    static Account newAccount = null;
    static CustomerOrder__c custOrder = null;  
    static CustomerOrder__c custOrder2 = null;
    static CustomerOrder__c custOrderCompleted = null;
    static Contact newContact = null;
    static Contact mainContact = null;
    static List<OrderLineGeneralItems__c> OrderLineItemList = null;
    static List<OrderLineGeneralItems__c> OrderLineItemListComplete = null;       
    
    static testMethod void AddCustomerOrder_NoCadebillAccount(){
        //Expecting exception to be thrown
        SetupTestData();
        string expectedMessage = 'Account null does not exist in Salesforce.';
        string actualMessage = 'actualMessage';
        Test.startTest();
        try{
            System.debug('**** Creating Order without a Cadebill Account');
            insert custOrder;
        }
        catch(exception ex){
            actualMessage = ex.getMessage();
            System.debug('**** Expected exception thrown');
            System.debug('**** Exception Message: ' + ex.getMessage());
        }
       finally{
            system.assert(actualMessage.contains(expectedMessage));
       }
        Test.stopTest();
    }
    static testMethod void AddCustomerOrder_InvalidCadebillAccount(){
        //Expecting exception to be thrown
        SetupTestData();
        System.debug('**** test data');
        decimal invalidCadebillAccount = (newAccount.CadebillAccountNo__c * -1);
        string expected = 'Account ' + invalidCadebillAccount + ' does not exist in Salesforce.';
        string actual = 'actual';
        Test.startTest();
        try{
            System.debug('**** Creating Order with invalid Cadebill Account');
            custOrder.CadebillAccountNumber__c = invalidCadebillAccount;
            insert custOrder;
        }
        catch(exception ex){
            System.debug('**** Expected exception thrown...');
            System.debug('**** Exception Message: ' + ex.getMessage());
            actual = ex.getMessage();
        }
        finally{
            system.assert(actual.contains(expected));
        }
        Test.stopTest();
    }
    
    static testMethod void AddCustomerOrder_Valid(){
        //No Exception should be thrown
        SetupTestData();
        Test.startTest();
        custOrder.CadebillAccountNumber__c = newAccount.CadebillAccountNo__c;
        insert custOrder;
        System.debug('**** successfully created valid order');
        Test.stopTest();
        List<CustomerOrder__c> orderList = [Select Id from CustomerOrder__c where Id = :custOrder.Id];
        system.assert(orderList.size() > 0);
        
    }
    
    static testMethod void UpdateCustomerOrder(){
        //No Exception should be thrown
        SetupTestData();
        Test.startTest();                           
        System.debug('**** successfully created valid order');
        UpdateOrderLineItems();                                    
        Test.stopTest(); 
        List<Case> CaseList = [SELECT Id FROM Case WHERE AccountId = :custOrder2.Customer__C];
        System.debug('**** Venkata Case List :' + CaseList);
        system.assert(CaseList.size()>0);
    }
    static testMethod void OrderStatusCompleted_emailNotification(){
        //No Exception should be thrown
        SetupTestData();
        
        Test.startTest();
        	custOrderCompleted.CadebillAccountNumber__c = newAccount.CadebillAccountNo__c;
        				        
            OrderLineItemListComplete[0].Itemstatus__c = 'Completed';
            User CastIron = [SELECT Id FROM USER WHERE Profile.name ='_castiron Profile' LIMIT 1];
           system.runAs(CastIron)
           {
             update OrderLineItemListComplete;
           }                          
        Test.stopTest(); 
        
        system.assert(CustomerOrderTriggerHandler.emailSent == true);
        
    }	
    static void SetupTestData(){
        //Create Account
        System.debug('**** creating default account');
        AccountCreation();
        CreateContact();
        //Create CustomerOrder Base
        System.debug('**** creating CustomerOrder base');
        InitOrder();
        insert custOrder2;
        insert custOrderCompleted;
        System.debug('INSERTING OBJECTS');
        
        createOrderLineItems(); 
    }
    
    static void AccountCreation(){
        Map<string, RecordTypeInfo> recordTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByName();
        newAccount = new Account(Name = ACCOUNT_NAME,
                                 RecordTypeId = recordTypeMap.get(ACCOUNT_TYPE).getRecordTypeId(),
                                 CadebillAccountNo__c = ACCOUNT_NUMBER);
        insert newAccount;

    }
    
    static void InitOrder(){
        custOrder = new CustomerOrder__c();
        custOrder.OrderDateTime__c = system.now();
        custOrder.OrderStatus__c = 'New';
        custOrder.Username__c = 'unittest';
        
        custOrder2 = new CustomerOrder__c();
        custOrder2.OrderDateTime__c = system.now();
        custOrder2.OrderStatus__c = 'New';
        custOrder2.Username__c = 'unittest';
        custOrder2.Customer__C = newAccount.Id;
        custOrder2.Contact__c = newContact.Id;
        
        custOrderCompleted = new CustomerOrder__c();
        custOrderCompleted.OrderDateTime__c = system.now();
        custOrderCompleted.OrderStatus__c = 'New';
        custOrderCompleted.Username__c = 'unittest';
        custOrderCompleted.Customer__C = newAccount.Id;
        custOrderCompleted.Contact__c = newContact.Id;
        
    }
    
    static void createOrderLineItems()
    {
       system.debug('**** Create Order Line Items');
       OrderLineItemList = new  List<OrderLineGeneralItems__c> ();
       OrderLineGeneralItems__c OL1 = new  OrderLineGeneralItems__c();
       
       OL1.CustomerOrder__c = custOrder2.Id;
       OL1.InstrumentType__c= 90 ;
       OL1.InstrumentTypeName__c='TEST';       
       OL1.ItemStatus__c='New';  
       OL1.StartDate__c = system.now();
       OrderLineItemList.add(OL1); 
      
       OrderLineGeneralItems__c OL2 = new  OrderLineGeneralItems__c();
       OL2.CustomerOrder__c = custOrder2.Id;        
       OL2.InstrumentType__c= 90 ;
       OL2.InstrumentTypeName__c='TEST';
       OL2.ItemStatus__c='New';              
       OL2.StartDate__c = system.now(); 
       OrderLineItemList.add(OL2);
        
       OrderLineItemListComplete = new  List<OrderLineGeneralItems__c> ();
	   OrderLineGeneralItems__c OL3 = new  OrderLineGeneralItems__c();       
       OL3.CustomerOrder__c = custOrderCompleted.Id;
       OL3.InstrumentType__c= 90 ;
       OL3.InstrumentTypeName__c='TEST';       
       OL3.ItemStatus__c='New';  
       OL3.StartDate__c = system.now();
       OrderLineItemListComplete.add(OL3);
       
       insert OrderLineItemListComplete;
       insert OrderLineItemList;
    }
    
    static void UpdateOrderLineItems()
    {
         system.debug('**** Update Order Line Items');
       for(OrderLineGeneralItems__c OrderLineItem: OrderLineItemList){
           OrderLineItem.ItemStatus__c = 'Failed';
           OrderLineItem.OrderErrorDetail__c='Test Error';
       }
       User CastIron = [SELECT Id FROM USER WHERE Profile.name ='_castiron Profile' LIMIT 1];
       system.runAs(CastIron)
       {
         update OrderLineItemList;
       }
    }
    
    static void CreateContact()
    {
        system.debug('**** calling contact');
        Map<String,Schema.RecordTypeInfo> ContactRecordTypeMap = Schema.SObjectType.Contact.getRecordTypeInfosByName();
        system.debug('**** Venkata contact: ' + ContactRecordTypeMap);
        newContact = new Contact(RecordTypeId = ContactRecordTypeMap.get(CONTACT_TYPE).getRecordTypeId());   
        newContact.LastName ='TestContact';  
        newContact.Contact_Role__c ='Agent';
        newContact.Email='abc@gmail.com';
        newContact.Phone='2018859338';        
        newContact.AccountId = newAccount.Id;   
        insert newContact;
        
        mainContact = new Contact(RecordTypeId = ContactRecordTypeMap.get(CONTACT_TYPE).getRecordTypeId());   
        mainContact.LastName ='TestContact';  
        mainContact.Contact_Role__c ='MAIN';
        mainContact.Email='abc@gmail.com';
        mainContact.Phone='2018859338';        
        mainContact.AccountId = newAccount.Id;   
        insert mainContact;
    }
}