public class XMRestWrapper {

     public String performCallOut(String url, String verbType, String body) {

          HttpRequest request = new HttpRequest();

          if (body != null) {
               request.setBody(body);
          }

          request.setEndpoint('callout:xMatters_NP/' + url);
          request.setHeader('Authorization', '{!$Credential.AuthorizationMethod} {!$Credential.AuthorizationHeaderValue}');

          request.setMethod(verbType);
          request.setHeader('Content-Type', 'application/json');

          Http h = new Http();

          if (!Test.isRunningTest()) {
               HttpResponse response = h.send(request);
               system.debug(response.getBody());

               if (response.getStatusCode() == 200 || response.getStatusCode() == 201 || response.getStatusCode() == 204) {
                    return response.getBody();
               } else {

                    String jsonResposne = response.getBody();

                    Integer xMattersResponseCode = Integer.valueOf(parseErrorValues(jsonResposne, 'code'));
                    String xMattersReason = parseErrorValues(jsonResposne, 'reason');
                    String xMattersInnerMessage = parseErrorValues(jsonResposne, 'message');

                    XMCalloutException xmCalloutException = new XMCalloutException(xMattersInnerMessage);
                    xmCalloutException.HttpStatusCode = xMattersResponseCode;
                    xmCalloutException.Message = xMattersInnerMessage;
                    xmCalloutException.Reason = xMattersReason;

                    throw xmCalloutException;
               }
          }

          return null;
     }

     // Pass the full Json response and the field you want to extract (Used to get XMatter error responses)
     private String parseErrorValues(String jsonResponse, String fieldName) {
          JSONParser parser = JSON.createParser(jsonResponse);
          while (parser.nextToken() != null) {
               if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == fieldName)) {
                    parser.nextToken();
                    return  parser.getText();
               }
          }

          return null;
     }
}
