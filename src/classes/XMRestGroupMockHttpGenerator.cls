/**
 * Created by william.nelson on 5/8/2017.
 */
@IsTest
public class XMRestGroupMockHttpGenerator implements HttpCalloutMock {

    public HTTPResponse respond(HTTPRequest req) {

        system.debug('calling response');
        string endPoint = req.getEndpoint();
        string method =  req.getMethod();
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        system.debug(endPoint);

        res.setStatusCode(200);
         //Updates or deletions of groups
         if (method == 'POST' || method == 'DELETE')
         {
             system.debug('post or delete');
             res.setBody('');
         }
         else if (endPoint.contains('group-memberships')){
             system.debug('group membership');
             res.setBody(buildGroupMembershipResponseBody());
         }
         else{
             system.debug('group list');
             res.setBody(buildGroupMembershipResponseBody());
        }
        return res;
        //
        }
    private string buildGroupMembershipResponseBody(){
        string body = '{"count":1,"total":1,"data":[{"group":{"id":"6245e1bb-8e52-4445-bdee-6f6a03a06f8d","targetName":"IP_InContact_Screen-Recording_C3","links":{"self":"/api/xm/1/groups/6245e1bb-8e52-4445-bdee-6f6a03a06f8d"}},"member":{"id":"1371db93-bd8c-4819-9861-ed24ac806e22","targetName":"Test01","recipientType":"PERSON","links":{"self":"/api/xm/1/people/1371db93-bd8c-4819-9861-ed24ac806e22"}}}],"links":{"self":"/api/xm/1/people/595136/group-memberships?offset=0&limit=100"}}';
        return body;
    }
    private string buildGroupListResponseBody(){
        string body = '{"count":7,"total":7,"data":[{"id":"1eae4022-36bf-47c9-be3c-88c137e6557e","targetName":"IP_InContact_ACD_C1","recipientType":"GROUP","status":"ACTIVE","externallyOwned":false,"allowDuplicates":true,"useDefaultDevices":true,"observedByAll":true,"description":"","links":{"self":"/api/xm/1/groups/1eae4022-36bf-47c9-be3c-88c137e6557e"}},{"id":"92c1f87f-a70e-4276-be49-84c228568a6d","targetName":"IP_InContact_Dialer_C3","recipientType":"GROUP","status":"ACTIVE","externallyOwned":false,"allowDuplicates":true,"useDefaultDevices":true,"observedByAll":true,"description":"","links":{"self":"/api/xm/1/groups/92c1f87f-a70e-4276-be49-84c228568a6d"}},{"id":"6245e1bb-8e52-4445-bdee-6f6a03a06f8d","targetName":"IP_InContact_Screen-Recording_C3","recipientType":"GROUP","status":"ACTIVE","externallyOwned":false,"allowDuplicates":true,"useDefaultDevices":true,"observedByAll":true,"description":"","links":{"self":"/api/xm/1/groups/6245e1bb-8e52-4445-bdee-6f6a03a06f8d"}},{"id":"5d26c996-947c-48d9-a241-93959a6e9815","targetName":"Opt in Event 123456","recipientType":"GROUP","status":"ACTIVE","externallyOwned":false,"allowDuplicates":true,"useDefaultDevices":true,"observedByAll":true,"description":"Will receive progress updates","links":{"self":"/api/xm/1/groups/5d26c996-947c-48d9-a241-93959a6e9815"}},{"id":"c08e08a8-2796-4bd7-af53-8dcd5bcbd376","targetName":"Test Group","recipientType":"GROUP","status":"ACTIVE","externallyOwned":false,"allowDuplicates":false,"useDefaultDevices":true,"observedByAll":true,"description":"Test Group Description","links":{"self":"/api/xm/1/groups/c08e08a8-2796-4bd7-af53-8dcd5bcbd376"}},{"id":"aff5ab18-93d0-47e9-a0a3-4e0da98c1679","targetName":"Training Group Demo","recipientType":"GROUP","status":"ACTIVE","externallyOwned":false,"allowDuplicates":true,"useDefaultDevices":true,"observedByAll":true,"description":"","site":{"id":"c8bf79e5-dab2-419d-ab8e-685516ae9a74","name":"Default Site","links":{"self":"/api/xm/1/sites/c8bf79e5-dab2-419d-ab8e-685516ae9a74"}},"links":{"self":"/api/xm/1/groups/aff5ab18-93d0-47e9-a0a3-4e0da98c1679"}},{"id":"54b8cefe-f84a-4174-b420-5b02e3eee297","targetName":"xMatters Training Crew","recipientType":"GROUP","status":"ACTIVE","externallyOwned":false,"allowDuplicates":true,"useDefaultDevices":true,"observedByAll":true,"description":"","site":{"id":"c8bf79e5-dab2-419d-ab8e-685516ae9a74","name":"Default Site","links":{"self":"/api/xm/1/sites/c8bf79e5-dab2-419d-ab8e-685516ae9a74"}},"links":{"self":"/api/xm/1/groups/54b8cefe-f84a-4174-b420-5b02e3eee297"}}],"links":{"self":"/api/xm/1/groups?offset=0&limit=100"}}';
        return body;
    }
}