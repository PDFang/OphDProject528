/**
 * Created by ravish.chawla on 11/1/2017.
 */

@IsTest
private class WebHookLeadManagementTest {
    static testMethod void createLeadTest() {


        String jsonRequest = '{\n' +
                ' "comment" :"Test App",\n' +
                '"customer":{' +
                    ' "company" : {"name":"New Company", ' +
                                 '"state":"CA", ' +
                                 '"size":"RANGE_10_24",' +
                                 '"country":"US"},\n' +
                    '"contact":{ ' +
                                 '"firstName":"TestRav",' +
                                 '"lastName":"RavTest",' +
                                 '"email":"r@test.com",' +
                                 '"phone":"+1 484-432-8338"' +
                                 '}' +
                '},\n' +
                ' "application" : ' +
                                '{ "id":1, ' +
                                '"name":"Hello Rav Test" }' +
                '}';


        test.startTest();
        RestRequest request = new RestRequest();
        request.requestURI = '/SFDCLead';
        System.debug('jsonRequest' + jsonRequest);
        request.requestBody = Blob.valueOf(jsonRequest);
        System.debug('request.requestBody' + request.requestBody);
        request.headers.put('Content-Type', 'application/json');
        request.httpMethod = 'POST';
        System.debug('request' + request);
        RestContext.request = request;


        RestResponse response = new RestResponse();
        RestContext.response = response;

        WebHookLeadManagement.CreateLead();
        System.debug('response' + response);
        test.stopTest();

        system.assertEquals(null, response.statusCode);
    }

    static testMethod void createLeadExceptionTest() {


        String jsonRequest = '{\n' +
                ' "comment" :"Test App",\n' +
                '"customer":{' +
                ' "compay : "name":"New Company", ' +
                '"state":"CA", ' +
                '"size":"RANGE_10_24",' +
                '"country":"US"},\n' +
                '"contact":{ ' +
                '"firstName":"TestRav",' +
                '"lastName":"RavTest",' +
                '"email":"r@test.com",' +
                '"phone":"+1 484-432-8338"' +
                '}' +
                '},\n' +
                ' "application" : ' +
                '{ "id":1, ' +
                '"name":"Hello Rav Test" }' +
                '}';


        test.startTest();
        RestRequest request = new RestRequest();
        request.requestURI = '/SFDCLead';
        System.debug('jsonRequest' + jsonRequest);
        request.requestBody = Blob.valueOf(jsonRequest);
        System.debug('request.requestBody' + request.requestBody);
        request.headers.put('Content-Type', 'application/json');
        request.httpMethod = 'POST';
        System.debug('request' + request);
        RestContext.request = request;


        RestResponse response = new RestResponse();
        RestContext.response = response;

        WebHookLeadManagement.CreateLead();
        System.debug('response' + response);
        test.stopTest();

    }
}