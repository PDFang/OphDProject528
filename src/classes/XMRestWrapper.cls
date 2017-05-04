public class XMRestWrapper {

   public String performCallOut(String url, String verbType, String body) {

        HttpRequest request = new HttpRequest();

        request.setBody(body);

        request.setEndpoint('callout:xMatters_NP/' + url);
        request.setHeader('Authorization', '{!$Credential.AuthorizationMethod} {!$Credential.AuthorizationHeaderValue}');

        request.setMethod(verbType);
        request.setHeader('Content-Type', 'application/json');

        Http h = new Http();

        HttpResponse response = h.send(request);

        system.debug(response.getBody());

        return response.getBody();
    }

}
