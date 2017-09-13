/**
 * Created by william.nelson on 5/8/2017.
 */
@isTest
public  class XMRestGroupTest {
//set up the mock class

    public static testmethod void TestGetXMPersonGroupsById() {

        XMRestGroupMockHttpGenerator fakeResponse = new XMRestGroupMockHttpGenerator(200,'Complete','[{"Name": "sForceTest1"}]',null);


        test.startTest();

        Test.setMock(HttpCalloutMock.class, fakeResponse);
        XMRestGroup xm = new XMRestGroup();
        List<XMGroupMemberModel> d =  xm.GetXMPersonGroupsById('Test01', 'eventType');
        test.stopTest();
        system.debug(d);

    }


    public static testmethod void TestAddUserToGroup() {

        XMRestGroupMockHttpGenerator fakeResponse = new XMRestGroupMockHttpGenerator(200,'Complete','[{"Name": "sForceTest1"}]',null);
        test.startTest();

        Test.setMock(HttpCalloutMock.class, fakeResponse);
        XMRestGroup xm = new XMRestGroup();
        xm.AddUserToGroup('GroupTest01', 'Test02', 'TypeTest01');
        test.stopTest();
    }

    public static testmethod void TestDeleteAGroup() {

        XMRestGroupMockHttpGenerator fakeResponse = new XMRestGroupMockHttpGenerator(200,'Complete','[{"Name": "sForceTest1"}]',null);
        test.startTest();

        Test.setMock(HttpCalloutMock.class, fakeResponse);
        XMRestGroup xm = new XMRestGroup();
        xm.DeleteAGroup('GroupTest01');
        test.stopTest();
    }

    public static testmethod void TestRemoveUserFromAGroup() {

        XMRestGroupMockHttpGenerator fakeResponse = new XMRestGroupMockHttpGenerator(200,'Complete','[{"Name": "sForceTest1"}]',null);
        test.startTest();

        Test.setMock(HttpCalloutMock.class, fakeResponse);
        XMRestGroup xm = new XMRestGroup();
        xm.RemoveUserFromAGroup('GroupTest01', 'Test02');
        test.stopTest();
    }


    public static testmethod void TestGetAllGroupsByPrefix() {

        XMRestGroupMockHttpGenerator fakeResponse = new XMRestGroupMockHttpGenerator(200,'Complete','[{"Name": "sForceTest1"}]',null);
        test.startTest();

        Test.setMock(HttpCalloutMock.class, fakeResponse);
        XMRestGroup xm = new XMRestGroup();
        List<XMGroupModel> xmGroupModelTest =  xm.GetAllGroupsByPrefix('Test01');
        test.stopTest();
        System.debug('xmGroupModelTest -->' + xmGroupModelTest);
    }

    public static testmethod void TestGetMyCustomerGroups() {

        XMRestGroupMockHttpGenerator fakeResponse = new XMRestGroupMockHttpGenerator(200,'Complete','[{"Name": "sForceTest1"}]',null);
        test.startTest();

        Test.setMock(HttpCalloutMock.class, fakeResponse);
        XMRestGroup xm = new XMRestGroup();
//        Account acc = new Account();
        //Create a new Account object
        Account acct = inContactBaseClass.CreateAccount('Test Account');
        acct.CadebillAccountNo__c = 9999999;
        acct.inContact_Cluster__c = 'C6';
        insert acct;

        List<XMPersonGroupData> xmPersonGroupDataTest =  xm.GetMyCustomerGroups(acct);
        test.stopTest();
        System.debug('xmPersonGroupDataTest -->' + xmPersonGroupDataTest);
    }

    public static testmethod void TestCreateNewGroup() {

        XMRestGroupMockHttpGenerator fakeResponse = new XMRestGroupMockHttpGenerator(200,'Complete','[{"Name": "sForceTest1"}]',null);
        test.startTest();

        Test.setMock(HttpCalloutMock.class, fakeResponse);
        XMRestGroup xm = new XMRestGroup();
        Boolean isGroupCreated =  xm.CreateNewGroup('Test01');
        test.stopTest();
        System.debug('isGroupCreated -->' + isGroupCreated);
    }


}