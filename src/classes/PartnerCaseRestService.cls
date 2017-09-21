@RestResource(urlMapping = '/PartnerCase/*')
global class PartnerCaseRestService {

    public class UpdateRequest{
        public String troubleReportId;
        public String troubleReportState;
        public String troubleReportStatus;
        public String comment;
    }

    @HttpPost
    global static void updateIncident(){

        RestRequest req = RestContext.request;
        RestResponse response = RestContext.response;

        system.debug('updateIncident(): RestRequest - ' + req);

        try{
            String requestBody = req.requestBody.toString();
            UpdateRequest request = (UpdateRequest) JSON.deserialize(requestBody, UpdateRequest.Class);

            Decimal troubleReportState = String.isNotBlank(request.troubleReportState) && request.troubleReportState.isNumeric()
                    ? Decimal.valueOf(request.troubleReportState) : null;
            Decimal troubleReportStatus = String.isNotBlank(request.troubleReportStatus) && request.troubleReportStatus.isNumeric()
                    ? Decimal.valueOf(request.troubleReportStatus) : null;

            ETMS_Trouble_Report_State_Status__mdt[] mdtList = [
                    Select Case_Status__c, Trouble_Report_State__c, Trouble_Report_Status__c
                    From ETMS_Trouble_Report_State_Status__mdt
                    where Trouble_Report_State__c = :troubleReportState
                    and Trouble_Report_Status__c = :troubleReportStatus
            ];

            if(mdtList.size() == 0){
                response.statusCode = 400;
                response.responseBody = Blob.valueOf('Invalid troubleReportState and/or troubleReportStatus.');
                return;
            }

            response.statusCode = 200;
            response.responseBody = Blob.valueOf('Under development try again later.');
        } catch(Exception ex){
            response.statusCode = 500;
            response.responseBody = Blob.valueOf(ex.getMessage());
        }

    }

}