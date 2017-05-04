public class XMRestPerson {
    private final String PersonUrl = 'people/';

    public XMPersonModel createPerson(XMPersonModel person) {

        XMRestWrapper wrapper = new XMRestWrapper();

        String requestBody = JSON.serialize(person, true);

        system.debug('createPerson() ====> requestBody' + requestBody);

        String jsonString = wrapper.performCallOut(this.PersonUrl, 'POST', requestBody);

        XMPersonModel createdPerson = null;

        createdPerson = (XMPersonModel) JSON.deserialize(jsonString, XMPersonModel.class);

        return createdPerson;
    }

    public XMPersonModel getXmPersonModelByXmattersId(String personId) {

        XMPersonModel personModel = null;

        XMRestWrapper wrapper = new XMRestWrapper();

        String urlWithParameters = this.PersonUrl + personId;

        system.debug('getXmPersonModelByXmattersId(): - Attempting to call xmatters Api ==> ' + urlWithParameters);

        String userJson = wrapper.performCallOut(urlWithParameters, 'GET', null);

        system.debug('getXmPersonModelByXmattersId(): - Found User data ===> ' + userJson);

        personModel = (XMPersonModel) JSON.deserialize(userJson, XMPersonModel.class);

        return personModel;
    }
}
