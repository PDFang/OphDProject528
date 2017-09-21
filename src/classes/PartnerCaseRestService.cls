@RestResource(urlMapping = '/PartnerCase/*')
global class PartnerCaseRestService {

    global class UpdateRequest{
        public String troubleReportId;
        public String troubleReportState;
        public String troubleReportStatus;
        public String comment;
    }

    global class UpdateResponse{
        public String status;
        public String message;
    }

    @HttpPost
    global static UpdateResponse updateIncident(UpdateRequest request){

        system.debug('request - ' + request);

        RestRequest req = RestContext.request;

        system.debug(req.requestBody.toString());
        return new UpdateResponse();
    }

}