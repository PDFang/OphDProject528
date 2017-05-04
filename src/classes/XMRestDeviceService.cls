public class XMRestDeviceService {
    private final String XMDeviceEndpoint = 'devices/';

    public XMDeviceModel createDeviceForPerson(XMDeviceModel deviceModel){

        XMDeviceModel createdDevice = null;

        String deviceToCreateJson = JSON.serialize(deviceModel);

        system.debug('createDeviceForPerson(): Attempting to create device' + deviceToCreateJson);

        XMRestWrapper wrapper = new XMRestWrapper();

        String jsonDevice = wrapper.performCallOut(this.XMDeviceEndpoint, 'POST', deviceToCreateJson);

        system.debug('createDeviceForPerson(): Device Created ' + jsonDevice);

        createdDevice = (XMDeviceModel)JSON.deserialize(jsonDevice, XMDeviceModel.class);

        return createdDevice;
    }

    public List<XMDeviceModel> getAllDevicesByxMattersUserId(String userGuid){

        List<XMDeviceModel> userDevices = new List<XMDeviceModel>();

        XMRestWrapper wrapper = new XMRestWrapper();

        String deviceEndpoint = '/people/' + userGUid + '/devices';

        system.debug('getAllDevicesByxMattersUserId(): Attempting to call ' + deviceEndpoint);

        String jsonDevices = wrapper.performCallOut(deviceEndpoint, 'GET', null);

        JSONParser parser = JSON.createParser(jsonDevices);

        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                while (parser.nextToken() != null) {
                    if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                        XMDeviceModel userDevice = (XMDeviceModel) parser.readValueAs(XMDeviceModel.class);
                         userDevices.add(userDevice);
                        system.debug('getAllDevicesByxMattersUserId(): userDevice - ' + userDevice);
                    }

                }
            }
        }

        return userDevices;
    }
}