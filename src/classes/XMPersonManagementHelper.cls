/**
 * Created by mohandaas.rangaswamy on 5/4/2017.
 */

public class XMPersonManagementHelper {

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

}