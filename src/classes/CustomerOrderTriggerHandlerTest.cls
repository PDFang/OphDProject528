@IsTest
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
    static CustomerOrder__c CustmerOrderTwoProducts = null;
    static Contact newContact = null;
    static Contact mainContact = null;
    static List<OrderLineGeneralItems__c> OrderLineItemList = null;
    static List<OrderLineGeneralItems__c> OrderLineItemListComplete = null;
    static OrderLineGeneralItems__c didLineItem = null;
    
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
        custOrder2.CadebillAccountNumber__c = newAccount.CadebillAccountNo__c;
        update custorder2;
        Test.startTest();                           
        System.debug('**** successfully created valid order');
        UpdateOrderLineItems();                                    
        Test.stopTest(); 
        List<Case> CaseList = [SELECT Id FROM Case WHERE AccountId = :custOrder2.Customer__C];
        System.debug('**** Venkata Case List :' + CaseList.size());
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
    static testMethod void OrderStatusProcessed_AbandonedItemsCaseUpdate(){
        //No Exception should be thrown
        SetupTestData();
        custOrder2.CadebillAccountNumber__c = newAccount.CadebillAccountNo__c;
        UpdateOrderLineItems(); // create failed case

        custOrder2.OrderStatus__c ='Completed (Partial)';// Update Order Status
        update custorder2;
        Test.startTest();

        OrderLineItemListComplete[0].Itemstatus__c = 'Canceled';
        User CastIron = [SELECT Id FROM USER WHERE Profile.name ='_castiron Profile' LIMIT 1];
        system.runAs(CastIron)
        {
            update OrderLineItemListComplete;
        }
        Test.stopTest();
        List<Case> CaseList = [SELECT Id FROM Case WHERE AccountId = :custOrder2.Customer__C];
        System.debug('**** Case List: ' + CaseList);
        system.assert(CaseList.size()>0);

    }
    static testMethod void OrderStatusNew_CreateLocalDIDsCase(){
        //No Exception should be thrown
        SetupTestData();
        CreateSpecificDIDItems();
        CustmerOrderTwoProducts.CadebillAccountNumber__c = newAccount.CadebillAccountNo__c;

        CustmerOrderTwoProducts.OrderStatus__c ='New';// Update Order Status

        Test.startTest();

        User CastIron = [SELECT Id FROM USER WHERE Profile.name ='_castiron Profile' LIMIT 1];
        system.runAs(CastIron)
        {
            update CustmerOrderTwoProducts;
        }
        Test.stopTest();
        List<Case> CaseList = [SELECT Id FROM Case WHERE AccountId = :CustmerOrderTwoProducts.Customer__C];
        List<CaseComment> commentList = [SELECT CommentBody FROM CaseComment WHERE Parent.CustomerOrder__c = :CustmerOrderTwoProducts.Id];
        System.debug('**** Case List: ' + CaseList);
        system.debug('***** Comment Body: ' + commentList[0].CommentBody);
        system.assert(CaseList.size()>0);
        system.assert(commentList.size()>0);
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
        insert CustmerOrderTwoProducts;
        System.debug('INSERTING OBJECTS');
        
        createOrderLineItems(); 
    }
    
    static void AccountCreation(){
        Map<string, RecordTypeInfo> recordTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByName();
        newAccount = new Account(Name = ACCOUNT_NAME,
                                 RecordTypeId = recordTypeMap.get(ACCOUNT_TYPE).getRecordTypeId(),
                                 CadebillAccountNo__c = ACCOUNT_NUMBER);
        newAccount.CG_Disconnect_Date__c = null;
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

        CustmerOrderTwoProducts = new CustomerOrder__c();
        CustmerOrderTwoProducts.OrderDateTime__c = system.now();
        CustmerOrderTwoProducts.OrderStatus__c = 'Pre-New';
        CustmerOrderTwoProducts.Username__c = 'LocalDIDUnitTest';
        CustmerOrderTwoProducts.Customer__C = newAccount.Id;
        CustmerOrderTwoProducts.Contact__c = newContact.Id;
        
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

        didLineItem = new  OrderLineGeneralItems__c();
        didLineItem.CustomerOrder__c = CustmerOrderTwoProducts.Id;
        didLineItem.InstrumentTypeName__c='TEST';
        didLineItem.ItemStatus__c='New';
        didLineItem.InstrumentType__c = 12554;
        didLineItem.StartDate__c = system.now();
        OrderLineItemList.add(didLineItem);

        OrderLineGeneralItems__c OL4 = new  OrderLineGeneralItems__c();
        OL4.CustomerOrder__c = CustmerOrderTwoProducts.Id;
        OL4.InstrumentType__c= 90 ;
        OL4.InstrumentTypeName__c='TEST';
        OL4.ItemStatus__c='New';
        OL4.StartDate__c = system.now();
        OrderLineItemList.add(OL4);
       
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

    static void CreateSpecificDIDItems(){
        List<OrderLineSpecificItem__c> specificItems = new List<OrderLineSpecificItem__c>();

        OrderLineSpecificItem__c npa = new OrderLineSpecificItem__c();
        npa.SpecificItem__c = 'NPA';
        npa.ItemValue__c = '801';
        npa.OrderLineGeneralItem__c = didLineItem.Id;
        specificItems.add(npa);

        OrderLineSpecificItem__c nxx = new OrderLineSpecificItem__c();
        nxx.SpecificItem__c = 'NXX';
        nxx.ItemValue__c = '504';
        nxx.OrderLineGeneralItem__c = didLineItem.Id;
        specificItems.add(nxx);

        OrderLineSpecificItem__c rateCenter = new OrderLineSpecificItem__c();
        rateCenter.SpecificItem__c = 'Rate Center';
        rateCenter.ItemValue__c = '801';
        rateCenter.OrderLineGeneralItem__c = didLineItem.Id;
        specificItems.add(rateCenter);

        OrderLineSpecificItem__c state = new OrderLineSpecificItem__c();
        state.SpecificItem__c = 'State';
        state.ItemValue__c = 'UT';
        state.OrderLineGeneralItem__c = didLineItem.Id;
        specificItems.add(state);

        OrderLineSpecificItem__c quantity = new OrderLineSpecificItem__c();
        quantity.SpecificItem__c = 'Quantity';
        quantity.ItemValue__c = '2';
        quantity.OrderLineGeneralItem__c = didLineItem.Id;
        specificItems.add(quantity);

        insert specificItems;

    }
}