public class XMPersonManagementHelper {

    public static final Set<String> xmDeviceTypes = new Set<String>{
        'EMAIL',
        'TEXT_PHONE'
    };

    public static final Set<String> deviceTypes = new Set<String>{
        'Work Email',
        'Secondary Email',
        'SMS Phone'
        //'Secondary SMS Phone'
    };

    public static List<SelectOption> getTimezones(){
        List<SelectOption> options = new List<SelectOption>();
        //options.add(new SelectOption( '', '- Select - '));
        XmTimezones__c[] values = XmTimezones__c.getAll().values();

        for(XmTimezones__c entry : values){
            options.add(new SelectOption( entry.Name, entry.Name));
        }

        return options;
    }

    public Contact getCurrentContact(){
        return currentContact;
    }

    private Contact currentContact;

    // constructor
    public XMPersonManagementHelper(String contactId){
        this.currentContact = getContactById(contactId);
    }

    public Contact getContactById(String contactId){

        Contact[] contactList = [
                select Name, FirstName, LastName, Email, Phone, Id, AccountId, Account.CadebillAccountNoText__c,
                        Account.Name, xmPerson__c, XmattersUid__c, xmPerson__r.PrimaryContact__c, xmPerson__r.xmPersonUID__c
                from Contact where Id =: contactId
        ];
        if(contactList.isEmpty()){
            throw new QueryException('Failed to retrieve Contact information.');
        }
        return contactList[0];
    }

    public Map<Id, Contact> getContactsByEmail(String email){

        return new Map<Id, Contact>([
                select FirstName, LastName, Email,Phone, Id, AccountId, Account.CadebillAccountNoText__c,
                        Account.Name, xmPerson__c, xmPerson__r.PrimaryContact__c, xmPerson__r.xmPersonUID__c
                from Contact where Email =: email //and xmPerson__c != null
        ]);
    }

    public void associateContact(String contactId, String xmPersonId){

        if(string.isNotBlank(contactId)){
            update new Contact(
                    Id = contactId,
                    xmPerson__c = xmPersonId,
                    XmattersUid__c = ''
            );
        } else{
            currentContact.xmPerson__c = xmPersonId;
            currentContact.XmattersUid__c = '';
            update currentContact;
        }

    }

    public void removeContactAssociation(String contactId, string xmPersonGuid){

        if(string.isNotBlank(contactId)){
            update new Contact(
                    Id = contactId,
                    xmPerson__c = null,
                    XmattersUid__c = xmPersonGuid
            );
        }

    }



    public static XMPersonWrapper getXmPersonByGuid(String xmPersonGuid){

        XMRestPerson restService = new XMRestPerson();
        if(xmPersonGuid != null){
            XMPersonModel response = restService.getXmPersonModelByXmattersId(xmPersonGuid);

            XMPersonWrapper personWrapper = new XMPersonWrapper(response);

            return personWrapper;
        }
       return null;

    }

    public static String getXmPersonGuid(String contactId){

        List<Contact> contactList = [
                Select xmPerson__c, xmPerson__r.xmPersonUID__c
                from Contact where Id = :contactId
        ];
        system.debug('addNewDevice(): contactList - '+ contactList);

        if(contactList.isEmpty()){
            throw new QueryException('Person does not exist in xMatters.');
        }
        String xmPersonGuid = contactList[0].xmPerson__r.xmPersonUID__c;
        return xmPersonGuid;

    }

    // calls out xMatters to create a Person and then inserts a record in Notification Profile object
    public string createXmPerson(XMPersonWrapper person){

        XMPersonModel newPerson = new XMPersonModel();
        newPerson.targetName = person.contactId;
        newPerson.firstName = person.FirstName;
        newPerson.lastName = person.LastName;
        newPerson.externalKey = person.contactId;
        newPerson.timezone = person.timezone;
        XMRestPerson restService = new XMRestPerson();
        XMPersonModel response = restService.createPerson(newPerson);

        String xmGuid = response.Id;
        xmPerson__c profile;
        if(xmGuid != null){
            profile = new xmPerson__c(
                    PrimaryContact__c = currentContact.Id,
                    xmPersonUID__c = xmGuid
            );
            insert profile;

            currentContact.xmPerson__c = profile.Id;
            update currentContact;

        }

        return profile != null ? profile.Id : null;

    }

    public static XMDeviceWrapper[] getUserDevices(String xmPersonGuid){

        XMPersonWrapper person = getXmPersonByGuid(xmPersonGuid);

        XMDeviceWrapper[] newDeviceList = new XMDeviceWrapper[]{};

        if(string.isNotBlank(xmPersonGuid)) {
            XMRestDeviceService service = new XMRestDeviceService();
            List<XMDeviceModel> deviceList = service.getAllDevicesByxMattersUserId(xmPersonGuid);

            for (XMDeviceModel device: deviceList) {
                XMDeviceWrapper newDevice = new XMDeviceWrapper();
                newDevice.name = device.name;
                newDevice.deviceType = device.deviceType;
                if (device instanceof XMSmsDevice) {
                    newDevice.deviceValue = ((XMSmsDevice) device).phoneNumber;
                }
                if (device instanceof XMEmailDevice) {
                    newDevice.deviceValue = ((XMEmailDevice) device).emailAddress;
                }
                newDevice.deviceId = device.id;
                newDeviceList.add(newDevice);
                if(device.timeframes == null || device.timeframes.isEmpty()){
                    continue;
                }
                List<XMDeviceTimeframe> timeframeList = device.timeframes;
                for(XMDeviceTimeframe timeframe : timeframeList){
                    XMDeviceTimeframeWrapper wrapper = new XMDeviceTimeframeWrapper(timeframe, person.timezone);
                    newDevice.timeframes.add(wrapper);
                }
            }
        }

        system.debug('getUserDevices(): newDeviceList - ' + newDeviceList);

        return newDeviceList;

    }

    public static String addDevice(String xmPersonGuid, String deviceName, String deviceValue) {

        XMDeviceModel device;
        if(deviceName.contains('Email')){
            XMEmailDevice emailDevice = new XMEmailDevice();
            emailDevice.emailAddress = deviceValue;
            device = emailDevice;

        } else if(deviceName.contains('Phone')){
            XMSmsDevice smsDevice = new XMSmsDevice();
            smsDevice.phoneNumber = '+1' + deviceValue;
            device = smsDevice;
        }
        device.name = deviceName;
        device.owner = xmPersonGuid;

        XMRestDeviceService service = new XMRestDeviceService();
        XMDeviceModel response = service.createDeviceForPerson(device);

        system.debug('addDevice(): response - ' + response);
        return response != null ? response.id : null;

    }

    public static void updateDevice(XMDeviceWrapper deviceWrapper) {

        XMDeviceModel device = deviceWrapper.createModel();

        XMRestDeviceService service = new XMRestDeviceService();
        service.updateDeviceInformation(device);

    }

    public static void deleteDevice(String deviceId){

        XMRestDeviceService service = new XMRestDeviceService();
        service.deleteDevice(deviceId);

    }

    public static XMGroupProductCluster[] getProductGroups(String contactId){

        XMGroupProductCluster[] xmGroupList = new XMGroupProductCluster[]{};

        XMBusinessLayer groupLayer = new XMBusinessLayer(contactId);
        Map<String, XMGroupProductCluster> groupMap = groupLayer.GetGroupListByUserid();

        if(groupMap == null){
            return xmGroupList;
        }

        for(XMGroupProductCluster xmGroup : groupMap.values()){
            xmGroupList.add(xmGroup);
        }
        system.debug('getProductGroups(): xmGroupList - ' + xmGroupList);

        return xmGroupList;

    }

    public static void updateXmGroupSubscription(XMGroupProductCluster[] xmGroupList, string xmPersonGuid ){

        XMBusinessLayer groupLayer = new XMBusinessLayer();
        string message = groupLayer.UpdateXMUserToGroups(xmGroupList, xmPersonGuid);
        system.debug('updateXmGroupSubscription(): message - ' + message);

    }

}