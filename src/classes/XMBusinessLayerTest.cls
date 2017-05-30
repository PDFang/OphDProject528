/**
 * Created by ravish.chawla on 5/24/2017.
 */

@IsTest
public class XMBusinessLayerTest {

    public static testMethod void TestGetGroupListByUserid() {

        XMRestGroupMockHttpGenerator fakeResponse = new XMRestGroupMockHttpGenerator(200,'Complete','[{"Name": "sForceTest1"}]',null);

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

        ImplementedProduct__c ip4 = new ImplementedProduct__c();
        ip4.Account__c = acc.Id;
        ip4.GoLiveDate__c = system.today() - 1;
        ip4.Status__c = 'Implemented';
        ip4.Product__c = 'NICE WFM - NQM';
        ip4.Opportunity__c = o.Id;
        insert ip4;



        ProductEventMap__c pem = new ProductEventMap__c();
        pem.Name = 'inContact';
        pem.Product__c = 'inContact';
        pem.ImplementedProduct__c = 'inContact';
        pem.Platform__c = 'Cluster - inContact';
        pem.HasClusters__c = true;

        insert pem;

        ProductEventMap__c pem1 = new ProductEventMap__c();
        pem1.Name = 'NICE QM - Engage';
        pem1.Product__c = 'NICE QM - Engage';
        pem1.ImplementedProduct__c = 'NICE QM - Engage';
        pem1.Platform__c = 'Verint - inContact';
        pem1.HasClusters__c = true;

        insert pem1;

        ProductEventMap__c pem2 = new ProductEventMap__c();
        pem2.Name = 'NICE WFM - IEX';
        pem2.Product__c = 'NICE WFM - IEX';
        pem2.ImplementedProduct__c = 'NICE WFM - IEX';
        pem2.Platform__c = 'NWFM - inContact';
        pem2.HasClusters__c = true;

        insert pem2;

        ProductEventMap__c pem3 = new ProductEventMap__c();
        pem3.Name = 'NICE WFM - NQM';
        pem3.Product__c = 'NICE WFM - NQM';
        pem3.ImplementedProduct__c = 'NICE WFM - NQM';
        pem3.Platform__c = 'NQM - inContact';
        pem3.HasClusters__c = true;

        insert pem3;

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
        groupProClusterTest1.Product = 'TestProduct2';
        groupProClusterTest1.Cluster = 'TestCluster2';
        groupProClusterTest1.PartnerPrefix = 'TestPartnerPrefix2';
        groupProClusterTest1.XmattersGroupName = 'TestXmattersGroupName2';
        groupProClusterTest1.selected = true;
        groupListTest.add(groupProClusterTest1);


        XMGroupProductCluster groupProClusterTest2 = new XMGroupProductCluster();
        groupProClusterTest2.Product = 'TestProduct2';
        groupProClusterTest2.Cluster = 'TestCluster2';
        groupProClusterTest2.PartnerPrefix = 'TestPartnerPrefix2';
        groupProClusterTest2.XmattersGroupName = 'TestXmattersGroupName2';
        groupProClusterTest2.selected = false;
        groupListTest.add(groupProClusterTest2);

        XMBusinessLayer xmBusinessLayer = new XMBusinessLayer();
        String responseMessageTest = xmBusinessLayer.UpdateXMUserToGroups(groupListTest, 'castiron');
        test.stopTest();
        System.debug('responseMessageTest -->' + responseMessageTest);
    }
}