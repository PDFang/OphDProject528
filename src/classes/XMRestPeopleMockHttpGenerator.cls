/*
    Use for testing the XMPeopleService. This code will create a mock xm callout
 */
@isTest
public class XMRestPeopleMockHttpGenerator implements HttpCalloutMock {

    public XMRestPeopleMockHttpGenerator(Integer code, String status, String body,
            Map<String, String> responseHeaders){}


    public HTTPResponse respond(HTTPRequest req) {

        system.debug('calling response');
        string endPoint = req.getEndpoint();
        string method =  req.getMethod();
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        system.debug(endPoint);

        res.setStatusCode(200);
        //Updates or deletions of groups
        if (method == 'POST')
        {
            system.debug('post');
            res.setBody(buildCreatePersonResponseBody());
        }
        else {
            system.debug('group membership');
            res.setBody(buildGetPersonResponseBody());
        }

        return res;
        //
    }
    private string buildGetPersonResponseBody(){
        string body = '{"count":1,"total":1,"data":[{"group":{"id":"6245e1bb-8e52-4445-bdee-6f6a03a06f8d","targetName":"IP_InContact_Screen-Recording_C3","links":{"self":"/api/xm/1/groups/6245e1bb-8e52-4445-bdee-6f6a03a06f8d"}},"member":{"id":"1371db93-bd8c-4819-9861-ed24ac806e22","targetName":"Test01","recipientType":"PERSON","links":{"self":"/api/xm/1/people/1371db93-bd8c-4819-9861-ed24ac806e22"}}}],"links":{"self":"/api/xm/1/people/595136/group-memberships?offset=0&limit=100"}}';
        return body;
    }
    private string buildCreatePersonResponseBody(){
        string body = '{"id":"1451a630-4d44-46e6-84ba-6b966dbfa715","targetName":"shartkeExternallyOwned3","recipientType":"PERSON","externallyOwned":true,"externalKey":"externallyOwned3","links":{"self":"/api/xm/1/people/1451a630-4d44-46e6-84ba-6b966dbfa715"},"firstName":"Bob","lastName":"Marly","language":"en","timezone":"US/Mountain","webLogin":"shartkeExternallyOwned3","site":{"id":"c8bf79e5-dab2-419d-ab8e-685516ae9a74","name":"Default Site","links":{"self":"/api/xm/1/sites/c8bf79e5-dab2-419d-ab8e-685516ae9a74"}},"status":"ACTIVE"}';
        return body;
    }
}