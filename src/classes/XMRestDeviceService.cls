public class XMRestDeviceService {
    private final String XMDeviceEndpoint = 'devices/';

    public XMDeviceModel createDeviceForPerson(XMDeviceModel deviceModel) {

        XMDeviceModel createdDevice = null;

        String deviceToCreateJson = JSON.serialize(deviceModel, true);

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

        system.debug('getAllDevicesByxMattersUserId(): Attempting to call ' + deviceEndpoint);

        String jsonDevices = wrapper.performCallOut(deviceEndpoint, 'GET', null);

        /* Returning this into a map because Owner when it comes back is an
            object and doesn't deserialize correctly. It was easier to just pick the properties out
         */

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

            device.id = String.valueOf(i.get('id'));

            system.debug('Found Deivce  ==> ' + device);

            userDevices.add(device);
        }


        return userDevices;
    }

    public void updateDeviceInformation(XMDeviceModel device){

        String serializedDevice;

        if( device instanceOf XMSmsDevice){
            serializedDevice = JSON.serialize((XMSmsDevice)device, true);
        } else if(device instanceOf XMSmsDevice) {
            serializedDevice = JSON.serialize((XMSmsDevice)device, true);
        } else{
            TypeException unknownDeviceTypeException = new  TypeException(); // TODO: Create a custom exception?
            unknownDeviceTypeException.setMessage('Unknown Device type');
            throw unknownDeviceTypeException;
        }

        XMRestWrapper wrapper = new XMRestWrapper();

        system.debug('updateDeviceInformation(): Attempting to call ' + XMDeviceEndpoint);

        String jsonDevice = wrapper.performCallOut(XMDeviceEndpoint, 'POST', serializedDevice);

        system.debug('updateDeviceInformation(): response ===> ' + jsonDevice);
    }
}
