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
            system.debug('XMRestDeviceServiceMock() ==> called endpoint: ' + endPoint);
            res.setBody(buildCreateUpdateDeviceResponseBody());
        }
        if(method == 'GET')
        {
            system.debug('XMRestDeviceServiceMock() ==> called endpoint: ' + endPoint);
            res.setBody(buildGetDevicesResponseBody());
        }
        if(method == 'DELETE'){
            system.debug('XMRestDeviceServiceMock() ==> called endpoint: ' + endPoint);
        }

        return res;
    }


    private string buildGetDevicesResponseBody(){
        string body = '{"count":3,"total":3,"data":[{"id":"e63dd359-94f5-4d2e-84ff-da15e4bc27f0","name":"Work Email","emailAddress":"basant.pathak@incontact.com","targetName":"BPathak|Work Email","deviceType":"EMAIL","description":"basant.pathak@incontact.com","testStatus":"UNTESTED","externallyOwned":false,"defaultDevice":false,"priorityThreshold":"LOW","sequence":1,"delay":0,"timeframes":{"count":1,"total":1,"data":[{"name":"24x7","startTime":"00:00","timezone":"US/Mountain","durationInMinutes":1440,"excludeHolidays":false,"days":["MO","TU","WE","TH","FR","SA","SU"]}],"links":{"self":"/api/xm/1/devices/e63dd359-94f5-4d2e-84ff-da15e4bc27f0/timeframes?offset=0&limit=100"}},"owner":{"id":"76c696bc-d9b2-423f-bf99-6120714eb8bb","targetName":"BPathak","firstName":"Basant","lastName":"Pathak","links":{"self":"/api/xm/1/people/76c696bc-d9b2-423f-bf99-6120714eb8bb"}},"links":{"self":"/api/xm/1/devices/e63dd359-94f5-4d2e-84ff-da15e4bc27f0"},"recipientType":"DEVICE","status":"ACTIVE","provider":{"id":"(x)Matters Email Gateway"}},{"id":"madeUpId","name":"Primry SMS","phoneNumber":"801-888-9999","targetName":"BPathak|Primary SMS","deviceType":"TEXT_PHONE","description":"My phone","testStatus":"UNTESTED","externallyOwned":false,"defaultDevice":false,"priorityThreshold":"LOW","sequence":1,"delay":0,"timeframes":{"count":1,"total":1,"data":[{"name":"24x7","startTime":"00:00","timezone":"US/Mountain","durationInMinutes":1440,"excludeHolidays":false,"days":["MO","TU","WE","TH","FR","SA","SU"]}],"links":{"self":"/api/xm/1/devices/e63dd359-94f5-4d2e-84ff-da15e4bc27f0/timeframes?offset=0&limit=100"}},"owner":{"id":"76c696bc-d9b2-423f-bf99-6120714eb8bb","targetName":"BPathak","firstName":"Basant","lastName":"Pathak","links":{"self":"/api/xm/1/people/76c696bc-d9b2-423f-bf99-6120714eb8bb"}},"links":{"self":"/api/xm/1/devices/e63dd359-94f5-4d2e-84ff-da15e4bc27f0"},"recipientType":"DEVICE","status":"ACTIVE","provider":{"id":"(x)Matters Email Gateway"}},{"id":"madeUpId","name":"MadeUp SMS","phoneNumber":"801-888-9999","targetName":"BPathak|Primary SMS","deviceType":"TEXT_MadUp","description":"My phone","testStatus":"UNTESTED","externallyOwned":false,"defaultDevice":false,"priorityThreshold":"LOW","sequence":1,"delay":0}],"links":{"self":"/api/xm/1/people/BPathak/devices?embed=timeframes&offset=0&limit=100"}}';
        return body;
    }

    private string buildCreateUpdateDeviceResponseBody(){
        string body = '{"id":"59ac4f15-a7d0-44b0-9be4-007be83ebc18","name":"Secondary Email","emailAddress":"testcontact@incontact.com","targetName":"0033C0000055F5gQAE|Secondary Email","deviceType":"EMAIL","description":"test","testStatus":"TESTED","externallyOwned":true,"defaultDevice":false,"priorityThreshold":"MEDIUM","sequence":2,"delay":0,"owner":{"id":"cd874706-1b8e-49e6-aad4-2c9b38f12e3e","targetName":"0033C0000055F5gQAE","firstName":"Test","lastName":"User","links":{"self":"/api/xm/1/people/cd874706-1b8e-49e6-aad4-2c9b38f12e3e"}},"links":{"self":"/api/xm/1/devices/59ac4f15-a7d0-44b0-9be4-007be83ebc18"},"recipientType":"DEVICE","status":"ACTIVE","provider":{"id":"(x)Matters Email Gateway"}}';
        return body;
    }
}