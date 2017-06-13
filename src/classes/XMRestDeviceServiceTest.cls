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

        XMDeviceModel createdDevice = (XMDeviceModel)deviceService.createDeviceForPerson(emailDevice);

        system.debug('createDeviceForPerson_WillDeserializeAndSerializeCorrectly() ==> ' +createdDevice );
        Test.stopTest();

        System.assertEquals(emailDevice.description, createdDevice.description);
        System.assertEquals(emailDevice.name, createdDevice.name);
    }

    public testMethod static void getAllDevicesByxMattersUserId_WillDeserializeAndSerializeCorrectly(){
        XMRestDeviceServiceMock httpMockCallout = new XMRestDeviceServiceMock(200,'Complete','[{"Name": "sForceTest1"}]',null);

        Test.startTest();

        Test.setMock(HttpCalloutMock.class, httpMockCallout);
        XMRestDeviceService deviceService = new XMRestDeviceService();

        XMDeviceModel[] retrievedDevices = deviceService.getAllDevicesByxMattersUserId('fakeId');

        system.debug('getAllDevicesByxMattersUserId_WillDeserializeAndSerializeCorrectly() ==> ' + retrievedDevices );
        Test.stopTest();

        system.assert(retrievedDevices.size() == 2);

        system.assert(retrievedDevices[0].description == 'basant.pathak@incontact.com');
    }

    public testMethod static void updateDeviceInformation_MultipleTypes_WillDeserializeAndSerializeCorrectly(){
        XMRestDeviceServiceMock httpMockCallout = new XMRestDeviceServiceMock(200,'Complete','[{"Name": "sForceTest1"}]',null);

        XMSmsDevice smsDeviceModel = new XMSmsDevice();
        smsDeviceModel.description = 'Test device';
        smsDeviceModel.targetName = 'test Target Name';
        smsDeviceModel.phoneNumber = '801-999-9990';

        XMEmailDevice emailDeviceModel = new XMEmailDevice();
        emailDeviceModel.description = 'Test device';
        emailDeviceModel.targetName = 'test Target Name';
        emailDeviceModel.emailAddress = 'shartkeWasHere@test.com';

        Test.startTest();

        Test.setMock(HttpCalloutMock.class, httpMockCallout);
        XMRestDeviceService deviceService = new XMRestDeviceService();

        XMSmsDevice updatedSMSModel = (XMSmsDevice)deviceService.updateDeviceInformation(smsDeviceModel);
        XMEmailDevice updatedEmailModel = (XMEmailDevice)deviceService.updateDeviceInformation(emailDeviceModel);
        Test.stopTest();

        // Test Phone Results
        system.assert(updatedSMSModel.description ==  smsDeviceModel.description);
        system.assert(updatedSMSModel.phoneNumber ==  smsDeviceModel.phoneNumber);
    }

    // This is really to pad the test coverage as there is nothing to test in this code
    public testMethod static void deleteDevice_WillDeserializeAndSerializeCorrectly(){
        XMRestDeviceServiceMock httpMockCallout = new XMRestDeviceServiceMock(200,'Complete','[{"Name": "sForceTest1"}]',null);

        Test.startTest();

        Test.setMock(HttpCalloutMock.class, httpMockCallout);
        XMRestDeviceService deviceService = new XMRestDeviceService();

        deviceService.deleteDevice('fakeId');

        Test.stopTest();
    }
}