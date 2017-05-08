@IsTest
private class CustomerOrderControllerTest {
    static Account testAccount = null;
    static final String ACCOUNT_TYPE = 'Customers';
    static final String CONTACT_TYPE = 'Customer-Other';
    static final String ACCOUNT_NAME = 'CustomerOrderControllerTest Account';
    static final decimal ACCOUNT_NUMBER = 4591810;
    static Contact testContact = null;
    static final String CONTACT_NAME = 'CustomerOrderControllerTest Contact';
    static CustomerOrder__c customerOrder = null;
    
    static void SetupTestData(){
        //Create Account
        system.debug('****creating default account');
        CreateAccount();
        //Create Contact
        system.debug('****creating default contact');
        CreateContact();
        //Create Valid CustomerOrder Base
        system.debug('****creating CustomerOrder Base');
        CreateCustomerOrder();
        //Create Valid OrderLineGeneralItem 
        system.debug('****creating OrderLineGeneralItem Base');
        CreateOrderLineItem();
    }
    static void CreateAccount(){
        Map<string, RecordTypeInfo> recordTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByName();
        testAccount = new Account(Name = ACCOUNT_NAME,
                                  RecordTypeId = recordTypeMap.get(ACCOUNT_TYPE).getRecordTypeId(),
                                  CadebillAccountNo__c = ACCOUNT_NUMBER);
        insert testAccount;
        system.debug('**** Account created successfully!');
    }
    static void CreateContact(){
        Map<String,Schema.RecordTypeInfo> ContactRecordTypeMap = Schema.SObjectType.Contact.getRecordTypeInfosByName();
        testContact = new Contact(RecordTypeId = contactRecordTypeMap.get(CONTACT_TYPE).getRecordTypeId());
        testContact.LastName = 'TestContact';
        testContact.Contact_Role__c = 'Main';
        testContact.Email = 'curt.houghton@incontact.com';
        testContact.Phone = '2013025577';
        testContact.AccountId = testAccount.Id;
        insert testContact;
        system.debug('**** Contact created successfully!');
    }
    static void CreateCustomerOrder(){
        customerOrder = new CustomerOrder__c();
        customerOrder.OrderDateTime__c = system.now();
        system.debug('****Customer Order DateTimeCreated - ' + customerOrder.OrderDateTime__c);
        customerOrder.OrderStatus__c = 'Completed';
        system.debug('****Customer Order Status - ' + customerOrder.OrderStatus__c);
        customerOrder.Username__c = 'UnitTest';
        customerOrder.Contact__c = testContact.Id;
        system.debug('****Customer Order Contact ID - ' + customerOrder.Contact__c);
        customerOrder.Customer__c = testAccount.Id;
        system.debug('****Customer Order Account ID - ' + customerOrder.Customer__c);
        insert customerOrder;
        system.debug('****Customer Order Id - ' + customerOrder.Id);
        system.debug('****Customer Order created successfully!');
    }
    static void CreateOrderLineItem(){
        OrderLineGeneralItems__c lineItem = new OrderLineGeneralItems__c();
        lineItem.StartDate__c = system.now();
        lineItem.InstrumentType__c = 12550;
        lineItem.InstrumentTypeName__c = 'Test';
        lineItem.Product2__c = '01t3900000RyWtyAAF';
        lineItem.OrderType__c = 'Add';
        lineItem.CustomerOrder__c = customerOrder.Id;
        lineItem.ItemStatus__c = 'New';
        insert lineItem;
        
    }
    static testMethod void CustomerOrderCompleted_ReturnOneLineItem(){
        SetupTestData();
        Test.startTest();
        CustomerOrderController controller = new CustomerOrderController();
        controller.customerOrderId = customerOrder.Id;
        CustomerOrderController.GeneralItems[] result = controller.GetOrderItems();
        Test.stopTest();
        system.assert(result.size() >0);
    }
}