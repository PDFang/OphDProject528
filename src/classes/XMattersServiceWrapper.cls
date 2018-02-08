public with sharing class XMattersServiceWrapper {
    //this wraps calls to the XMatters Service that is part of the ProxyServices site

    public String performCallOut(String subPath, String verbType, String body) {

        HttpRequest request = new HttpRequest();

        if (body != null) {
            request.setBody(body);
        }

        request.setEndpoint('callout:XMatters_Service/' + subPath);

        request.setMethod(verbType);
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Content-Length', body != null ? string.valueOf(body.length()) : '0');
        request.setTimeout(60000);

        system.debug('request ==> : ' + request);
        Http h = new Http();

        HttpResponse response = h.send(request);
        system.debug('performCallOut() ==> response: ' + response.getBody());

        String returnResponse = getResponse(response);

        return returnResponse;
    }

    private String getResponse(HttpResponse response){
        if (response.getStatusCode() == 200 || response.getStatusCode() == 201 || response.getStatusCode() == 204 || response.getStatusCode() == 202) {
            return response.getBody();
        } else {

            String jsonResponse = response.getBody();

            Integer xMattersResponseCode = response.getStatusCode();
            String xMattersReason = response.getStatus();
            String xMattersInnerMessage = jsonResponse;

            XMCalloutException xmCalloutException = new XMCalloutException(xMattersInnerMessage);
            xmCalloutException.HttpStatusCode = xMattersResponseCode;
            xmCalloutException.Message = xMattersInnerMessage;
            xmCalloutException.Reason = xMattersReason;

            throw xmCalloutException;
        }

        return null;
    }

    private String parseErrorValues(String jsonResponse, String fieldName) {
        JSONParser parser = JSON.createParser(jsonResponse);
        while (parser.nextToken() != null) {
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == fieldName)) {
                parser.nextToken();
                return parser.getText();
            }
        }

        return null;
    }
}