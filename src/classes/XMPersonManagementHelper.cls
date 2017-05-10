public class XMPersonManagementHelper {

    public static final Set<String> xmDeviceTypes = new Set<String>{
        'EMAIL',
        'TEXT_PHONE'
    };

    public static final Set<String> deviceTypes = new Set<String>{
        'Work Email',
        'Secondary Email',
        'SMS Phone',
        'Secondary SMS Phone'
    };

    public static List<SelectOption> getTimezones(){
        List<SelectOption> options = new List<SelectOption>();
        //options.add(new SelectOption( '', '- Select - '));
        Schema.PickListEntry[] values = Schema.xmPerson__c.Timezone__c.getDescribe().getPicklistValues();
        for(Schema.PickListEntry entry : values){
            options.add(new SelectOption( entry.getValue(), entry.getLabel()));
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

        return [
                select FirstName, LastName, Email, Phone, Id, AccountId,
                        Account.Name, xmPerson__c, xmPerson__r.PrimaryContact__c, xmPerson__r.xmPersonUID__c, xmPerson__r.Timezone__c
                from Contact where Id =: contactId
        ];
    }

    public Map<Id, Contact> getContactsByXmPerson(String xmPersonId){

        return new Map<Id, Contact>([
                select FirstName, LastName, Email, Phone, Id, AccountId,
                        Account.Name, xmPerson__c, xmPerson__r.PrimaryContact__c, xmPerson__r.xmPersonUID__c, xmPerson__r.Timezone__c
                from Contact where xmPerson__c =: xmPersonId
        ]);

    }

    public Map<Id, Contact> getContactsByEmail(String email){

        return new Map<Id, Contact>([
                select FirstName, LastName, Email, Phone, Id, AccountId,
                        Account.Name, xmPerson__c, xmPerson__r.PrimaryContact__c, xmPerson__r.xmPersonUID__c, xmPerson__r.Timezone__c
                from Contact where Email =: email
        ]);
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
                    xmPersonUID__c = xmGuid,
                    Timezone__c = person.timezone
            );
            insert profile;

            currentContact.xmPerson__c = profile.Id;
            update currentContact;

        }

        return profile != null ? profile.Id : null;

    }

    public static XMDeviceWrapper[] getUserDevices(String xmPersionId){

        XMDeviceWrapper[] newDeviceList = new XMDeviceWrapper[]{};
        if(string.isNotBlank(xmPersionId)) {
            XMRestDeviceService service = new XMRestDeviceService();
            List<XMDeviceModel> deviceList = service.getAllDevicesByxMattersUserId(xmPersionId);

            for (XMDeviceModel device: deviceList) {
                XMDeviceWrapper newDevice = new XMDeviceWrapper();
                newDevice.deviceType = device.name;
                if (device instanceof XMSmsDevice) {
                    newDevice.deviceValue = ((XMSmsDevice) device).phoneNumber;
                }
                if (device instanceof XMEmailDevice) {
                    newDevice.deviceValue = ((XMEmailDevice) device).emailAddress;
                }
                newDevice.deviceId = device.id;
                newDeviceList.add(newDevice);
            }
        }
        return newDeviceList;

    }


}