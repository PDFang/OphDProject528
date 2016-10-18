global class ISTFSINTEGRATIONCLASSMOCKTEST implements HttpCalloutMock {	    
    
    private Integer statusCode = 200;
    
    public ISTFSINTEGRATIONCLASSMOCKTEST(){
        
    }
    
    public ISTFSINTEGRATIONCLASSMOCKTEST(Integer statusCode){
        this.statusCode = (statusCode == null) ? 200 : statusCode;
    }
    
    global HTTPResponse respond(HTTPRequest req) {

        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
       	res.setBody(statusCode == 200 ? ISIntegrationHandlerClassTest.DEFAULT_TEST_TFS_ID : 'Integration Failed');                
        res.setStatusCode(statusCode);
        return res;
    }
}