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

        test.startTest();

        Test.setMock(HttpCalloutMock.class, fakeResponse);
        Account acc = new Account();
        acc.id = '0013C000006KV7CQAW';
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