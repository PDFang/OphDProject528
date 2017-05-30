public class XMRestEventServiceHttpMock implements HttpCalloutMock {

    // Used for asserts to determine what was passed to the callout
    public String requestBodyPassed {get;set;}

    public XMRestEventServiceHttpMock(Integer code, String status, String body, Map<String, String> responseHeaders){
        this.requestBodyPassed = body;
    }

    public HTTPResponse respond(HTTPRequest req) {
        system.debug('calling response');
        string endPoint = req.getEndpoint();
        string method =  req.getMethod();
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        system.debug(endPoint);

        res.setStatusCode(200);

        if (method == 'POST')
        {
            system.debug('post');
            res.setBody(buildCreatePersonResponseBody());
        }

        return res;
    }

    private string buildCreatePersonResponseBody(){
        // TODO: Set to the request id that gets returned from
        string body = '{"id":"1451a630-4d44-46e6-84ba-6b966dbfa715","targetName":"shartkeExternallyOwned3","recipientType":"PERSON","externallyOwned":true,"externalKey":"externallyOwned3","links":{"self":"/api/xm/1/people/1451a630-4d44-46e6-84ba-6b966dbfa715"},"firstName":"Bob","lastName":"Marly","language":"en","timezone":"US/Mountain","webLogin":"shartkeExternallyOwned3","site":{"id":"c8bf79e5-dab2-419d-ab8e-685516ae9a74","name":"Default Site","links":{"self":"/api/xm/1/sites/c8bf79e5-dab2-419d-ab8e-685516ae9a74"}},"status":"ACTIVE"}';
        return body;
    }
}