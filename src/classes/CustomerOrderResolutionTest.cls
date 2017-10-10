@IsTest
private class CustomerOrderResolutionTest {
    static final String ACCOUNT_TYPE = 'Customers';
    static final string CONTACT_TYPE ='Customer-Other';
    static final decimal ACCOUNT_NUMBER = 4591810;
    static final String ACCOUNT_NAME = 'CustomerOrderTriggerHandlerTest Account';
    static Account newAccount = null;
    static CustomerOrder__c order = null;
    static List<OrderLineGeneralItems__c> OrderLineItemList = null;
    static final String ORDER_STATUS_FAILED = 'Failed';
    static final String LINE_ITEM_STATUS_FAILED = 'Failed';
    static final String LINE_ITEM_STATUS_ABANDONED = 'Canceled';

    static void SetUpTestData() {
        CreateAccount();
        InitOrder();
        insert order;
        createOrderLineItems();
    }
    static void CreateAccount(){
        Map<string, RecordTypeInfo> recordTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByName();
        newAccount = new Account(Name = ACCOUNT_NAME,
                RecordTypeId = recordTypeMap.get(ACCOUNT_TYPE).getRecordTypeId(),
                CadebillAccountNo__c = ACCOUNT_NUMBER);
        newAccount.CG_Disconnect_Date__c = null;
        insert newAccount;
        system.debug('**** Account created successfully!');
    }
    static void InitOrder(){
        order = new CustomerOrder__c();
        order.OrderDateTime__c = system.now();
        order.OrderStatus__c = 'New';
        order.Username__c = 'unittest';
        order.Customer__C = newAccount.Id;
        order.CadebillAccountNumber__c = newAccount.CadebillAccountNo__c;

    }
    static void createOrderLineItems()
    {
        system.debug('**** Create Order Line Items');
        OrderLineItemList = new  List<OrderLineGeneralItems__c> ();

        OrderLineGeneralItems__c OL1 = new  OrderLineGeneralItems__c();
        OL1.CustomerOrder__c = order.Id;
        OL1.InstrumentType__c= 90 ;
        OL1.InstrumentTypeName__c='TEST';
        OL1.ItemStatus__c='New';
        OL1.StartDate__c = system.now();
        OrderLineItemList.add(OL1);

        OrderLineGeneralItems__c OL2 = new  OrderLineGeneralItems__c();
        OL2.CustomerOrder__c = order.Id;
        OL2.InstrumentType__c= 90 ;
        OL2.InstrumentTypeName__c='TEST';
        OL2.ItemStatus__c='New';
        OL2.StartDate__c = system.now();
        OrderLineItemList.add(OL2);

        OrderLineGeneralItems__c OL3 = new  OrderLineGeneralItems__c();
        OL3.CustomerOrder__c = order.Id;
        OL3.InstrumentType__c= 90 ;
        OL3.InstrumentTypeName__c='TEST';
        OL3.ItemStatus__c='New';
        OL3.StartDate__c = system.now();
        OrderLineItemList.add(OL3);

        insert OrderLineItemList;
    }
    static void UpdateOrderLineItems(string status)
    {
        system.debug('**** Update Order Line Items');
        for(OrderLineGeneralItems__c OrderLineItem: OrderLineItemList){
            OrderLineItem.ItemStatus__c = status;
            OrderLineItem.OrderErrorDetail__c='Test Error';
        }
        User CastIron = [SELECT Id FROM USER WHERE Profile.name ='_castiron Profile' LIMIT 1];
        system.runAs(CastIron)
        {
            update OrderLineItemList;
        }
    }
    public static testMethod void OrderStatus_NotFailed_DoesNot_ShowResolutionOptions() {
        SetupTestData();
        Test.startTest();
        ApexPages.StandardController controllerStandard = new ApexPages.standardController(order);
        CustomerOrderResolutionExtension custOrderResolution = new CustomerOrderResolutionExtension(controllerStandard);
        Test.stopTest();
        System.assertEquals(false, custOrderResolution.ShowPage());
        System.assertEquals(true, String.isNotEmpty(custOrderResolution.apexMessage));
    }
    public static testMethod void OrderStaus_Failed_But_NoLIneItemsToSolve() {
        SetupTestData();
        Test.startTest();
        order.OrderStatus__c = 'failed';
        update order;

        ApexPages.StandardController controllerStandard = new ApexPages.standardController(order);
        CustomerOrderResolutionExtension custOrderResolution = new CustomerOrderResolutionExtension(controllerStandard);
        Test.stopTest();
        System.assertEquals(true, custOrderResolution.ShowPage());
        System.assertEquals(true, String.isNotEmpty(custOrderResolution.apexMessage));
    }
    public static testMethod void UpdateLineItems_ReturnsToPrevPage() {
        SetupTestData();
        Test.startTest();
        order.OrderStatus__c = 'failed';
        update order;
        OrderLineItemList[0].ItemStatus__c = 'Failed';
        OrderLineItemList[1].ItemStatus__c = 'Failed';
        update OrderLineItemList;
        ApexPages.StandardController controllerStandard = new ApexPages.standardController(order);
        CustomerOrderResolutionExtension custOrderResolution = new CustomerOrderResolutionExtension(controllerStandard);

        PageReference result = custOrderResolution.SaveLineItems();
        Test.stopTest();
        system.assert(true,custOrderResolution.lineItems.size() == 2);
        System.assertEquals(true, custOrderResolution.ShowPage());
        System.assertEquals(false, String.isNotEmpty(custOrderResolution.apexMessage));

        system.assertEquals(result.getUrl(),'/'+ order.id);
    }

    public static testMethod void UpdateLineItems_AbandonAllLineItems() {
        SetupTestData();
        Test.startTest();
        order.OrderStatus__c = 'failed';
        update order;
        OrderLineItemList[0].ItemStatus__c = 'Failed';
        OrderLineItemList[1].ItemStatus__c = 'Failed';
        update OrderLineItemList;

        ApexPages.StandardController controllerStandard = new ApexPages.standardController(order);
        CustomerOrderResolutionExtension custOrderResolution = new CustomerOrderResolutionExtension(controllerStandard);

        custOrderResolution.updateAllResolution = custOrderResolution.UpdateAllOptions.get(2).getValue();
        custOrderResolution.UpdateAll();
        Test.stopTest();

        for(OrderLineGeneralItems__c item: custOrderResolution.lineItems){
            System.assert(true, item.ItemStatus__c == LINE_ITEM_STATUS_ABANDONED);
        }
    }
    public static testMethod void UpdateLineItems_AbandonOne() {
        SetupTestData();
        Test.startTest();
        order.OrderStatus__c = 'failed';
        update order;
        OrderLineItemList[0].ItemStatus__c = 'Failed';
        OrderLineItemList[1].ItemStatus__c = 'Failed';
        update OrderLineItemList;

        ApexPages.StandardController controllerStandard = new ApexPages.standardController(order);
        CustomerOrderResolutionExtension custOrderResolution = new CustomerOrderResolutionExtension(controllerStandard);

        custOrderResolution.lineItems[0].LineItemResolution__c = LINE_ITEM_STATUS_ABANDONED;
        custOrderResolution.SaveLineItems();
        Test.stopTest();

        System.assert(true, custOrderResolution.lineItems[0].ItemStatus__c == LINE_ITEM_STATUS_ABANDONED);
        System.assert(true, custOrderResolution.lineItems[1].ItemStatus__c == LINE_ITEM_STATUS_FAILED);
        System.assert(true,  OrderLineItemList[0].ItemStatus__c == LINE_ITEM_STATUS_ABANDONED);
        System.assert(true,  OrderLineItemList[1].ItemStatus__c == LINE_ITEM_STATUS_FAILED);

    }


}