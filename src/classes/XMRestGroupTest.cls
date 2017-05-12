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
        List<XMGroupMemberModel> d =  xm.GetXMPersonGroupsById('Test01');
        test.stopTest();
        system.debug(d);

    }


}




