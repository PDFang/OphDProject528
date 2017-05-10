public class XMRestDeviceService {
    private final String XMDeviceEndpoint = 'devices/';

    public XMDeviceModel createDeviceForPerson(XMDeviceModel deviceModel) {

        XMDeviceModel createdDevice = null;

        String deviceToCreateJson = JSON.serialize(deviceModel, true);

        system.debug('createDeviceForPerson(): Attempting to create device' + deviceToCreateJson);

        XMRestWrapper wrapper = new XMRestWrapper();

        String jsonDevice = wrapper.performCallOut(this.XMDeviceEndpoint, 'POST', deviceToCreateJson);

        system.debug('createDeviceForPerson(): Device Created ' + jsonDevice);

        createdDevice = parseSingleDeviceModel(jsonDevice);

        return createdDevice;
    }

    public List<XMDeviceModel> getAllDevicesByxMattersUserId(String userGuid) {

        List<XMDeviceModel> userDevices = new List<XMDeviceModel>();

        XMRestWrapper wrapper = new XMRestWrapper();

        String deviceEndpoint = '/people/' + userGUid + '/devices?embed=timeframes';

        system.debug('getAllDevicesByxMattersUserId(): Attempting to call ' + deviceEndpoint);

        String jsonDevices = wrapper.performCallOut(deviceEndpoint, 'GET', null);

        /* Returning this into a map because Owner when it comes back is an
            object and doesn't deserialize correctly. It was easier to just pick the properties out
         */
        userDevices = parseMultipleDeviceJson(jsonDevices);

        return userDevices;
    }

    public XMDeviceModel updateDeviceInformation(XMDeviceModel device){

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

        return parseSingleDeviceModel(jsonDevice);
    }

    public void deleteDevice(String xMattersDeviceId){
        XMRestWrapper wrapper = new XMRestWrapper();

        system.debug('deleteDevice(): Attempting to call Delete Endpoint for device id :  ' + xMattersDeviceId);

        String jsonDevice = wrapper.performCallOut(XMDeviceEndpoint + xMattersDeviceId, 'DELETE', null);

        system.debug('deleteDevice(): Succeeded! Response: ' + jsonDevice);
    }

    /*
        Split this into its own function so that it can be called from multiple places.
        Its job is to take a json string with devices and deserialize them into a list of xmdevicemodel
     */
    private List<XMDeviceModel> parseMultipleDeviceJson(String jsonRecord){

        List<XMDeviceModel> deviceList = new List<XMDeviceModel>();

        Map <String, Object> root = (Map <String, Object>)JSON.deserializeUntyped(jsonRecord);

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

            if(i.containsKey('timeframes')) { // If we have timeframes try and parse those as well
                Map<String, Object> timeframeMap = (Map<String, Object>) i.get('timeframes');

                device.timeframes = parseDeviceTimeframes(timeframeMap);
            }

            system.debug('Found Deivce  ==> ' + device);

            deviceList.add(device);
        }

        return deviceList;
    }

    /*
        This method will allow us to convert a map to a list of timeframe objects
     */
    private List<XMDeviceTimeframe> parseDeviceTimeframes(Map<String, Object> timeframeMap){
        List<XMDeviceTimeframe> timeframes = new List<XMDeviceTimeframe>();

        List<Object> timeFrameObjects = (List<Object>)timeframeMap.get('data');
        for(Object timeframeObject : timeFrameObjects){
            Map<String, Object> i = (Map<String, Object>)timeframeObject;

            XMDeviceTimeframe deviceTime = new XMDeviceTimeframe();
            deviceTime.name = String.valueOf(i.get('name'));
            deviceTime.startTime = String.valueOf(i.get('startTime'));
            deviceTime.durationInMinutes = Integer.valueOf(i.get('durationInMinutes'));
            deviceTime.excludeHolidays = Boolean.valueOf(i.get('excludeHolidays'));

            // Replace all the parenthesis in the days list and loop through and create a new list of string
            String daysFormatted  = String.valueOf(i.get('days')).replaceAll('[()]','');

            List<String> daysList = new List<String>();

            for(String day: daysFormatted.split(',')) {
                daysList.add(day);
            }

            deviceTime.days = daysList;

            timeframes.add(deviceTime);
        }

        return timeframes;
    }

    /*
        Parses a single object and returns that back to the user
     */
    private XMDeviceModel parseSingleDeviceModel(String jsonDevice){
        Map <String, Object> root = (Map <String, Object>)JSON.deserializeUntyped(jsonDevice);
        XMDeviceModel deviceModel = new XMDeviceModel();

        XMDeviceModel singleDevice = null;
        if(String.valueOf(root.get('deviceType')) == 'TEXT_PHONE'){
            deviceModel = new XMSmsDevice();
            ((XMSmsDevice)deviceModel).phoneNumber = String.valueOf(root.get('phoneNumber'));
        } else if(String.valueOf(root.get('deviceType')) == 'EMAIL') {
            deviceModel = new XMEmailDevice();
            ((XMEmailDevice)deviceModel).emailAddress = String.valueOf(root.get('emailAddress'));
        } else{
            return null; // TODO: Custom Exception
        }

        deviceModel.name = String.valueOf(root.get('name'));
        deviceModel.deviceType = String.valueOf(root.get('deviceType'));
        deviceModel.description = String.valueOf(root.get('description'));

        deviceModel.id = String.valueOf(root.get('id'));

        return deviceModel;
    }
}
