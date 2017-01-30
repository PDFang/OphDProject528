@IsTest
private class OrderLineGeneralItemTriggerHandlerTest {
    
    static final String ACCOUNT_TYPE_CUSTOMERS = 'Customers';
    static Account acct = null;      
    static CustomerOrder__c o1 = null;
    static List<OrderLineGeneralItems__c> OrderLineItemList = null;    
    
    static testMethod void AddCustomerOrder()
    {
        createTestData();
        
        Test.startTest();    
        
        OrderLineItemList[0].Itemstatus__c = 'Inprogress';        
        Update OrderLineItemList[0];
        
        
        
        CustomerOrder__c Order = [select OrderStatus__c FROM CustomerOrder__c WHERE CadebillAccountNumber__c =100001];
        system.assertEquals('New', Order.OrderStatus__c); 
        
        OrderLineItemList[1].Itemstatus__c = 'Completed';
        Update OrderLineItemList[1];
        
        Test.stopTest();
        
        Order = [select OrderStatus__c FROM CustomerOrder__c WHERE CadebillAccountNumber__c =100001];
        system.assertEquals('Completed', Order.OrderStatus__c);  
   
    }
    
    static void createTestData()
    {

        createAccount();
		system.debug('**** calling createorders');        
        createOrders();
        system.debug('**** '+o1);        
        createOrderLineItems();        
    }
    
    
    static void createAccount()
    {
		Map<String, RecordTypeInfo> rtMap = Schema.SObjectType.Account.getRecordTypeInfosByName();
        acct = new Account(
                Name = 'OrderLineGeneralItemTriggerHandlerTest Account',
                RecordTypeId = rtMap.get(ACCOUNT_TYPE_CUSTOMERS).getRecordTypeId()
        );
        insert acct;
    }

    static void createOrders()
    {
        
        o1 = new CustomerOrder__c();
        o1.OrderDateTime__c     = system.now();
        o1.CadebillAccountNumber__c =100001;
        o1.OrderStatus__c = 'New';
        o1.Username__c='testuser';
        o1.OrderDateTime__c = system.now();   
        insert o1;
    }

    static void createOrderLineItems()
    {
       OrderLineItemList = new  List<OrderLineGeneralItems__c> ();
       OrderLineGeneralItems__c OL1 = new  OrderLineGeneralItems__c();
       
       OL1.CustomerOrder__c = o1.Id;
       OL1.InstrumentType__c= 90 ;
       OL1.InstrumentTypeName__c='TEST';       
       OL1.ItemStatus__c='New';  
       OL1.StartDate__c = system.now();
       OrderLineItemList.add(OL1); 
      
       OrderLineGeneralItems__c OL2 = new  OrderLineGeneralItems__c();
       OL2.CustomerOrder__c = o1.Id;        
       OL2.InstrumentType__c= 90 ;
       OL2.InstrumentTypeName__c='TEST';
       OL2.ItemStatus__c='New';              
       OL2.StartDate__c = system.now(); 
       OrderLineItemList.add(OL2);
      
       insert OrderLineItemList;
    }
}