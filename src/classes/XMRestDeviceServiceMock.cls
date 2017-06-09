public class XMRestDeviceServiceMock implements HttpCalloutMock{
    // Used for asserts to determine what was passed to the callout
    public String requestBodyPassed {get;set;}

    public XMRestDeviceServiceMock(Integer code, String status, String body, Map<String, String> responseHeaders){}

    public HTTPResponse respond(HTTPRequest req) {
        system.debug('calling response');
        string endPoint = req.getEndpoint();
        string method =  req.getMethod();
        this.requestBodyPassed = req.getBody();

        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');

        res.setStatusCode(200);

        if (method == 'POST')
        {
            system.debug('post');
            res.setBody(requestBodyPassed);
        }

        return res;
    }

    private string buildCreatePersonResponseBody(){
        string body = '{"requestId":"1451a630-4d44-46e6-84ba-6b966dbfa715"}';
        return body;
    }
}