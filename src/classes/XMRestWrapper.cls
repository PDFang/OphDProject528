public class XMRestWrapper {

   public String performCallOut(String url, String verbType, String body) {

        HttpRequest request = new HttpRequest();

        if(body != null)
        {
             request.setBody(body);
        }

        request.setEndpoint('callout:xMatters_NP/' + url);
        request.setHeader('Authorization', '{!$Credential.AuthorizationMethod} {!$Credential.AuthorizationHeaderValue}');

        request.setMethod(verbType);
        request.setHeader('Content-Type', 'application/json');

        Http h = new Http();

        if(!Test.isRunningTest()) {
             HttpResponse response = h.send(request);
             system.debug(response.getBody());
             return response.getBody();
        }

        // TODO: Add better error handling for 409 and 404.

        return null;
    }
}
