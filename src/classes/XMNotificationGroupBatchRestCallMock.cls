//this class specifically supports the calls that the XMNotificationGroupBatch makes to xMatters
@isTest
public with sharing class XMNotificationGroupBatchRestCallMock implements HttpCalloutMock {
    @TestVisible
    private List<String> devicesAddedToGroup;
    private Integer statusCode;
    private Integer deviceCounter;

    public XMNotificationGroupBatchRestCallMock(Integer code) {
        devicesAddedToGroup = new List<String>();
        statusCode = code;
        deviceCounter = 0;
    }

    public HttpResponse respond(HttpRequest param1) {
        String endpoint = param1.getEndPoint();

        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');

        response.setStatusCode(statusCode);

        system.debug('endpoint =====> ' + endpoint);
        if(endpoint.startsWith('callout:xMatters_REST_API//people') && endpoint.endsWith('/devices?embed=timeframes')) {
            response.setBody(buildGetDevicesResponseBody());
        }
        else {
            response.setBody(buildAddPersonToGroupResponseBody(param1));
        }

        return response;
    }

    private String buildGetDevicesResponseBody() {
        return '{"data":[{"id":"workemail_' + deviceCounter++ + '","name":"Work Email","deviceType":"EMAIL","emailAddress":"test@test.com"},{"id":"secondDeviceId_' + deviceCounter++ + '","name":"not Work Email","deviceType":"TEXT_PHONE","phoneNumber":"18015551111"}]}';
    }

    private string buildAddPersonToGroupResponseBody(HttpRequest request){
        String requestBody = request.getBody();
        system.debug('request body ===> ' + requestBody);
        Map<String, Object> root = (Map<String, Object>)JSON.deserializeUntyped(requestBody);

        Map<String,Object> recipient = (Map<String,Object>)root.get('recipient');
        String deviceId = String.valueOf(recipient.get('id'));
        //track which devices are added
        devicesAddedToGroup.add(deviceId);

        return '{"id":"' + deviceId + '","targetName":"test"}';
    }
}