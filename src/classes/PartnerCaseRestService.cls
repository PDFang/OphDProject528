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

        UpdateRequest request;
        Case incident = null;

        try{
            String requestBody = req.requestBody.toString();
            request = (UpdateRequest) JSON.deserialize(requestBody, UpdateRequest.Class);

            // retrieve incident
            if(String.isNotBlank(request.troubleReportId)){

                Case[] incidentList = [
                        Select Id, Status, ETMS_Trouble_Report_State__c, ETMS_Trouble_Report_Status__c, X3rdPartyVendorTicket__c
                        from Case Where X3rdPartyVendorTicket__c = :request.troubleReportId
                ];
                if(incidentList.size() > 0){
                    incident = incidentList[0];
                }

            }

            if(incident == null){
                response.statusCode = 400;
                response.responseBody = Blob.valueOf('INVALID_REPORT_ID');
                return;
            }

            // get status mapped to trouble report state and status
            if(String.isNotBlank(request.troubleReportState) && String.isNotBlank(request.troubleReportStatus)){

                Decimal troubleReportState = request.troubleReportState.isNumeric() ? Decimal.valueOf(request.troubleReportState) : null;
                Decimal troubleReportStatus = request.troubleReportStatus.isNumeric() ? Decimal.valueOf(request.troubleReportStatus) : null;

                ETMS_Trouble_Report_State_Status__mdt[] mdtList = [
                        Select Case_Status__c, Trouble_Report_State__c, Trouble_Report_Status__c
                        From ETMS_Trouble_Report_State_Status__mdt
                        where Trouble_Report_State__c = :troubleReportState
                        and Trouble_Report_Status__c = :troubleReportStatus
                        and SF_Inbound__c = true
                ];

                if(mdtList.size() == 0){
                    response.statusCode = 400;
                    response.responseBody = Blob.valueOf('INVALID_STATE_OR_STATUS');
                    return;
                }
                // change incident status
                if(incident.status != mdtList[0].Case_Status__c){
                    incident.status = mdtList[0].Case_Status__c;
                    CaseTriggerHandler.bypassProxyService = true;
                    update incident;
                }

            }

            // add case comment
            if(String.isNotBlank(request.comment)){
                CaseComment newCaseComment = new CaseComment(
                        CommentBody = request.comment,
                        IsPublished = false,
                        ParentId = incident.Id
                );
                CaseCommentTriggerHandler.bypassProxyService = true;
                insert newCaseComment;
            }

            response.statusCode = 200;
            response.responseBody = Blob.valueOf('SUCCESS');

        } catch(Exception ex){
            response.statusCode = 500;
            response.responseBody = Blob.valueOf(ex.getTypeName());
            String subject = (incident != null) ? incident.Id : 'NONE';
            subject += (request != null) ? ' Trouble Report Id: ' + request.troubleReportId : '';
            inContactBaseClass.SendErrorEmail( ex, subject);
        }

    }

}