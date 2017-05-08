/**
 * Created by mohandaas.rangaswamy on 5/4/2017.
 */

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

    public Contact getContactById(String contactId){

        return [
                select FirstName, LastName, Email, Phone, Id, AccountId,
                        Account.Name, xmPerson__c, xmPerson__r.PrimaryContact__c, xmPerson__r.xmPersonUID__c
                from Contact where Id =: contactId
        ];
    }

    public Map<Id, Contact> getContactsByEmail(String email){

        return new Map<Id, Contact>([
                select FirstName, LastName, Email, Phone, Id, AccountId,
                        Account.Name, xmPerson__c, xmPerson__r.PrimaryContact__c, xmPerson__r.xmPersonUID__c
                from Contact where Email =: email
        ]);
    }

    public string createXmPerson(Contact cont){

        XMPersonModel newPerson = new XMPersonModel();
        newPerson.targetName = cont.Id;
        newPerson.firstName = cont.FirstName;
        newPerson.lastName = cont.LastName;
        newPerson.externalKey = cont.Id;

        XMRestPerson restService = new XMRestPerson();
        XMPersonModel response = restService.createPerson(newPerson);
        return response != null ? response.id : null;

    }

//    public List<XMDeviceModel> getAllDevicesByxMattersUserId(String userGuid){
////        XMRestDeviceService service = new XMRestDeviceService();
////        List<XMDeviceModel> response = service.getAllDevicesByxMattersUserId();
//    }

}