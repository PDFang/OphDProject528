public class XMRestDeviceService {
    private final String XMDeviceEndpoint = 'devices/';

    public XMDeviceModel createDeviceForPerson(XMDeviceModel createDevice){

        XMDeviceModel createdDevice = null;

        String deviceToCreateJson = JSON.serialize(createdDevice);

        system.debug('createDeviceForPerson(): Attempting to create device' + deviceToCreateJson);

        XMRestWrapper wrapper = new XMRestWrapper();

        String jsonDevice = wrapper.performCallOut(this.XMDeviceEndpoint, 'POST', deviceToCreateJson);

        system.debug('createDeviceForPerson(): Device Crated ' + jsonDevice);

        createdDevice = (XMDeviceModel)JSON.deserialize(jsonDevice, XMDeviceModel.class);

        return createdDevice;
    }

    public List<XMDeviceModel> getAllDevicesByxMattersUserId(String userGuid){

        List<XMDeviceModel> userDevices = new List<XMDeviceModel>();


        return userDevices;
    }
}