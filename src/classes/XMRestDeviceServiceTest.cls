@isTest
public class XMRestDeviceServiceTest {
    public testMethod static void createDeviceForPerson_WillDeserializeAndSerializeCorrectly(){
        XMRestDeviceServiceMock httpMockCallout = new XMRestDeviceServiceMock(200,'Complete','[{"Name": "sForceTest1"}]',null);

        XMEmailDevice emailDevice = new XMEmailDevice();
        emailDevice.name = 'Email Device Name';
        emailDevice.description = 'This is a device for unit Testing';
        emailDevice.targetName = 'Device TargetName';

        Test.startTest();

        Test.setMock(HttpCalloutMock.class, httpMockCallout);
        XMRestDeviceService deviceService = new XMRestDeviceService();

        XMDeviceModel createdDevice =  (XMDeviceModel)deviceService.createDeviceForPerson(emailDevice);

        Test.stopTest();

        System.assertEquals(emailDevice.targetName, createdDevice.targetName);
        System.assertEquals(emailDevice.description, createdDevice.description);
        System.assertEquals(emailDevice.name, createdDevice.name);
    }
}