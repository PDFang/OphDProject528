/*
    Use for testing the XMPeopleService. This code will create a mock xm callout
 */
@isTest
public class XMRestPeopleMockHttpGenerator implements HttpCalloutMock {

    private Integer statusCode;
    private String statusName;

    public XMRestPeopleMockHttpGenerator(Integer code, String status, String body,
            Map<String, String> responseHeaders){
        statusCode = code;
        statusName = status;
    }


    public HTTPResponse respond(HTTPRequest req) {

        system.debug('calling response');
        string endPoint = req.getEndpoint();
        string method =  req.getMethod();
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        system.debug(endPoint);

        // For Testing error responses
        if(statuscode == 415){
            res.setStatusCode(415);
            res.setBody(buildFailureResponseBody());
        } else {
            res.setStatusCode(200);
            //Updates or deletions of groups
            if (method == 'POST') {
                system.debug('post');
                if (statusName.indexOf('Inactivate') > 0) {
                    res.setBody(buildInactivatePersonResponseBody());
                }
                else {
                    res.setBody(buildCreatePersonResponseBody());
                }
            }
            else {
                system.debug('group membership');
                res.setBody(buildCreatePersonResponseBody());
            }
        }

        return res;
    }

    private String buildCreatePersonResponseBody(){
        string body = '{"id":"1451a630-4d44-46e6-84ba-6b966dbfa715","targetName":"shartkeExternallyOwned3","recipientType":"PERSON","externallyOwned":true,"externalKey":"externallyOwned3","links":{"self":"/api/xm/1/people/1451a630-4d44-46e6-84ba-6b966dbfa715"},"firstName":"Bob","lastName":"Marly","language":"en","timezone":"US/Mountain","webLogin":"shartkeExternallyOwned3","site":{"id":"c8bf79e5-dab2-419d-ab8e-685516ae9a74","name":"Default Site","links":{"self":"/api/xm/1/sites/c8bf79e5-dab2-419d-ab8e-685516ae9a74"}},"status":"ACTIVE"}';
        return body;
    }

    private String buildInactivatePersonResponseBody(){
        string body = '{"id":"1451a630-4d44-46e6-84ba-6b966dbfa715","targetName":"shartkeExternallyOwned3","recipientType":"PERSON","externallyOwned":true,"externalKey":"externallyOwned3","links":{"self":"/api/xm/1/people/1451a630-4d44-46e6-84ba-6b966dbfa715"},"firstName":"Bob","lastName":"Marly","language":"en","timezone":"US/Mountain","webLogin":"shartkeExternallyOwned3","site":{"id":"c8bf79e5-dab2-419d-ab8e-685516ae9a74","name":"Default Site","links":{"self":"/api/xm/1/sites/c8bf79e5-dab2-419d-ab8e-685516ae9a74"}},"status":"INACTIVE"}';
        return body;
    }

    private String buildFailureResponseBody(){
        String body = '{"code":415,"reason":"Invalid JSON","message":"Could not process request."}';
        return body;
    }
}