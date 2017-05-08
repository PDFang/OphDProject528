public class XMRestService {

    private final String GroupUrl = 'groups/';

    private String performCallOut(String url, String verbType, String body) {

        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:xMatters_NP/' + url);
        request.setHeader('Authorization', '{!$Credential.AuthorizationMethod} {!$Credential.AuthorizationHeaderValue}');

        request.setMethod(verbType);

        Http h = new Http();

        HttpResponse response = h.send(request);

        system.debug(response.getBody());

        return response.getBody();
    }

    public List<XMGroupModel> GetAllGroups() {
        string jsonList = performCallOut(this.GroupUrl, 'GET', null);

        List<XMGroupModel> groupList = new List<XMGroupModel>();

        JSONParser parser = JSON.createParser(jsonList);
        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                while (parser.nextToken() != null) {
                    if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                        groupList.Add((XMGroupModel) parser.readValueAs(XMGroupModel.class));
                        system.debug('GetAllGroups(): groupList - ' + groupList);
                    }

                }
            }
        }

        return groupList;
    }
}