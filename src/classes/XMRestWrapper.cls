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

             if(response.getStatusCode() == 200 || response.getStatusCode() == 201 || response.getStatusCode() == 204){
                  return response.getBody();
             } else {
                 CalloutException calloutException = new CalloutException(); // TODO: Poor mans error handling for now
                  calloutException.setMessage(response.getBody());

                  throw calloutException;
             }
        }

        return null;
    }
}
