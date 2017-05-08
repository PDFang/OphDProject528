public class XMRestDeviceService {
    private final String XMDeviceEndpoint = 'devices/';

    public XMDeviceModel createDeviceForPerson(XMDeviceModel deviceModel) {

        XMDeviceModel createdDevice = null;

        String deviceToCreateJson = JSON.serialize(deviceModel);

        system.debug('createDeviceForPerson(): Attempting to create device' + deviceToCreateJson);

        XMRestWrapper wrapper = new XMRestWrapper();

        String jsonDevice = wrapper.performCallOut(this.XMDeviceEndpoint, 'POST', deviceToCreateJson);

        system.debug('createDeviceForPerson(): Device Created ' + jsonDevice);

        createdDevice = (XMDeviceModel) JSON.deserialize(jsonDevice, XMDeviceModel.class);

        return createdDevice;
    }

    public List<XMDeviceModel> getAllDevicesByxMattersUserId(String userGuid) {

        List<XMDeviceModel> userDevices = new List<XMDeviceModel>();

        XMRestWrapper wrapper = new XMRestWrapper();

        String deviceEndpoint = '/people/' + userGUid + '/devices';

        //  system.debug('getAllDevicesByxMattersUserId(): Attempting to call ' + deviceEndpoint);

        String jsonDevices = wrapper.performCallOut(deviceEndpoint, 'GET', null);

        Map <String, Object> root = (Map <String, Object>) JSON.deserializeUntyped(jsonDevices);
        List<Object> items = (List<Object>)root.get('data');

        for(Object item : items){
            Map<String, Object> i = (Map<String, Object>)item;

            XMDeviceModel device = null;

            if(String.valueOf(i.get('deviceType')) == 'TEXT_PHONE'){
               device = new XMSmsDevice();
                ((XMSmsDevice)device).phoneNumber = String.valueOf(i.get('phoneNumber'));
            } else if(String.valueOf(i.get('deviceType')) == 'EMAIL') {
                device = new XMEmailDevice();
                ((XMEmailDevice)device).emailAddress = String.valueOf(i.get('emailAddress'));
            } else{
                continue; // Unsupported Type for now
            }

            device.name = String.valueOf(i.get('name'));
            device.deviceType = String.valueOf(i.get('deviceType'));
            device.description = String.valueOf(i.get('description'));
            device.targetName = String.valueOf(i.get('targetName'));

            system.debug('Found Deivce  ==> ' + device);

            userDevices.add(device);
        }


        return userDevices;
    }
}
