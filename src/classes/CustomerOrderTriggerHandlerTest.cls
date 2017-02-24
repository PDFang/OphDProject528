@IsTest
private class CustomerOrderTriggerHandlerTest {
	static final String ACCOUNT_TYPE = 'Customers';
    static final decimal ACCOUNT_NUMBER = 4591810;
    static final String ACCOUNT_NAME = 'CustomerOrderTriggerHandlerTest Account';
    static Account newAccount = null;
    static CustomerOrder__c custOrder = null;
    
    static testMethod void AddCustomerOrder_NoCadebillAccount(){
        //Expecting exception to be thrown
        SetupTestData();
        string expectedMessage = 'Cadebill Account Number cannot be blank.';
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
    static void SetupTestData(){
        //Create Account
        System.debug('**** creating default account');
        AccountCreation();
        //Create CustomerOrder Base
        System.debug('**** creating CustomerOrder base');
        InitOrder();
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
    }
}