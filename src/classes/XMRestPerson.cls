public class XMRestPerson {
    private final String PersonUrl = 'people/';

    public XMPersonModel createPerson(XMPersonModel person) {

        XMRestWrapper wrapper = new XMRestWrapper();

        String requestBody = JSON.serialize(person);

        system.debug('createPerson() ====> requestBody' + requestBody);

        String jsonString = wrapper.performCallOut(this.PersonUrl, 'POST', requestBody);

        XMPersonModel createdPerson = null;

        JSONParser parser = JSON.createParser(jsonString);

        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                while (parser.nextToken() != null) {
                    if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                        createdPerson = (XMPersonModel) parser.readValueAs(XMGroupModel.class);
                        system.debug('createPerson(): createdPerson - ' + createdPerson);
                    }

                }
            }
        }

        return createdPerson;
    }

    public XMPersonModel GetXmPersonModelByXmattersId(String personId){

        XMPersonModel personModel = null;

        XMRestWrapper wrapper = new XMRestWrapper();

        String urlWithParameters = this.PersonUrl + personId;

        system.debug('GetXmPersonModelByXmattersId() - Attempting to call xmatters Api ==> ' + urlWithParameters);

        String userJson =  wrapper.performCallOut(urlWithParameters, 'GET', null);

        return personModel;
    }
}