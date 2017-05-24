/**
 * Created by ravish.chawla on 5/24/2017.
 */

@IsTest
public class XMBusinessLayerTest {

    public static testMethod void TestGetGroupListByUserid() {

        XMRestGroupMockHttpGenerator fakeResponse = new XMRestGroupMockHttpGenerator(200,'Complete','[{"Name": "sForceTest1"}]',null);

//        Map<String,Schema.RecordTypeInfo> accountRecordTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByName();
//        Account testAccount = new Account(
//                Name = 'testCalculateAccountNetScore Account',
//                Type = 'Customer',
//                RecordTypeId = accountRecordTypeMap.get('Customers').getRecordTypeId(),
//                IsPartner__c = false,
//                CustomerSegment__c = 'Strategic',
//                Brand_Visibility__c = 'Yes',
//                Industry_Leadership_Vocality__c = 'Yes',
//                Social_Media_Presence__c = 'Yes',
//                Risk_of_Leaving__c = 'Low',
//                Referenceable__c = false,
//                GYRStatus__c = 'Green'
//        );
//
//        insert testAccount;
//        Map<String,Schema.RecordTypeInfo> recordTypeMap = Schema.SobjectType.Case.getRecordTypeInfosByName();
//        // known issue
//        //set default assignment rule
//        database.DMLOptions dmo = new database.DMLOptions();
//        dmo.assignmentRuleHeader.useDefaultRule = true;




        //setup test data
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.CadebillAccountNo__c = 9999999;
        acc.NICE_QM_Cluster__c = 'EN1';
        acc.NICE_WFM_Cluster__c = 'NWFM 1-2';
        acc.Verint_Cluster__c = 'V1';
        acc.inContact_Cluster__c =  'C9';

        insert acc;

        Opportunity o = new Opportunity();
        o.RecordTypeId = inContactBaseClass.SelectRecordTypeIDByName('Historical Products', 'Opportunity');
        o.Name = 'test';
        o.CloseDate = system.today().addDays(30);
        o.StageName = 'Open';
        o.AccountId = acc.Id;

        insert o;

        ImplementedProduct__c ip1 = new ImplementedProduct__c();
        ip1.Account__c = acc.Id;
        ip1.GoLiveDate__c = system.today() - 1;
        ip1.Status__c = 'Implemented';
        ip1.Product__c = 'inContact';
        ip1.Opportunity__c = o.Id;
        insert ip1;


        ImplementedProduct__c ip2 = new ImplementedProduct__c();
        ip2.Account__c = acc.Id;
        ip2.GoLiveDate__c = system.today() - 1;
        ip2.Status__c = 'Implemented';
        ip2.Product__c = 'NICE QM - Engage';
        ip2.Opportunity__c = o.Id;
        insert ip2;

        ImplementedProduct__c ip3 = new ImplementedProduct__c();
        ip3.Account__c = acc.Id;
        ip3.GoLiveDate__c = system.today() - 1;
        ip3.Status__c = 'Implemented';
        ip3.Product__c = 'NICE WFM - IEX';
        ip3.Opportunity__c = o.Id;
        insert ip3;

        test.startTest();
        XMBusinessLayer xmBusinessLayer = new XMBusinessLayer();
        Map<String, XMGroupProductCluster> groupListByUserId = xmBusinessLayer.GetGroupListByUserid('castiron', acc);
        test.stopTest();
        System.debug('groupListByUserIdTest -->' + groupListByUserId);
    }


    public static testMethod void TestUpdateXMUserToGrouops() {

        XMRestGroupMockHttpGenerator fakeResponse = new XMRestGroupMockHttpGenerator(200,'Complete','[{"Name": "sForceTest1"}]',null);

        test.startTest();

        Test.setMock(HttpCalloutMock.class, fakeResponse);

        List<XMGroupProductCluster> groupListTest = new List<XMGroupProductCluster>();
        XMGroupProductCluster groupProClusterTest = new XMGroupProductCluster();
        groupProClusterTest.Product = 'TestProduct1';
        groupProClusterTest.Cluster = 'TestCluster1';
        groupProClusterTest.PartnerPrefix = 'TestPartnerPrefix1';
        groupProClusterTest.XmattersGroupName = 'TestXmattersGroupName1';
        groupProClusterTest.selected = true;
        groupListTest.add(groupProClusterTest);

        XMGroupProductCluster groupProClusterTest1 = new XMGroupProductCluster();
        groupProClusterTest.Product = 'TestProduct2';
        groupProClusterTest.Cluster = 'TestCluster2';
        groupProClusterTest.PartnerPrefix = 'TestPartnerPrefix2';
        groupProClusterTest.XmattersGroupName = 'TestXmattersGroupName2';
        groupProClusterTest.selected = true;
        groupListTest.add(groupProClusterTest1);

        XMBusinessLayer xmBusinessLayer = new XMBusinessLayer();
        String responseMessageTest = xmBusinessLayer.UpdateXMUserToGrouops(groupListTest, 'castiron');
        test.stopTest();
        System.debug('responseMessageTest -->' + responseMessageTest);
    }
}