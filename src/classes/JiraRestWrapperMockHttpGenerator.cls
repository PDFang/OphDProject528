public class JiraRestWrapperMockHttpGenerator implements HttpCalloutMock{

    private Integer statusCode;

    public JiraRestWrapperMockHttpGenerator(Integer code, String status, String body,
            Map<String, String> responseHeaders){
        statusCode = code;
    }

    public HTTPResponse respond(HTTPRequest req) {

        system.debug('calling response');
        string endPoint = req.getEndpoint();
        string method =  req.getMethod();
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(statuscode);
        system.debug(endPoint);

        // Form Response Message
        if(statuscode == 200){
            res.setBody(buildSuccessResponseBody());
        }

        return res;
    }

    private String buildSuccessResponseBody(){
        string body = '{"issueKey": "testIssueKey"}';
        return body;
    }
}