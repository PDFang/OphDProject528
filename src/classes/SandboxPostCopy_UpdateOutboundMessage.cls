/**
 * Created by mohandaas.rangaswamy on 12/22/2016.
 */
// Update outbound message endpoint URL
public class SandboxPostCopy_UpdateOutboundMessage extends SandboxPostCopyTask{

    public override String getClassName(){
        return 'SandboxPostCopy_UpdateOutboundMessage';
    }

    public override string task(SandboxContext context) {

        MetadataService.MetadataPort port = new MetadataService.MetadataPort();
        MetadataService.SessionHeader_element SessionHeader = new MetadataService.SessionHeader_element();
        SessionHeader.sessionId = userinfo.getSessionId();
        port.SessionHeader = SessionHeader;

        MetadataService.ListMetadataQuery queryElement = new MetadataService.ListMetadataQuery();
        queryElement.type_x = 'WorkflowOutboundMessage';
        MetadataService.ListMetadataQuery[] queryList = new MetadataService.ListMetadataQuery[]{
                queryElement
        };
        Double version = 38.0;
        if(allowCallout()) {
            MetadataService.FileProperties[] properties = port.listMetadata(queryList, version);
            system.debug('task(): Total no.of outbound message retrieved ' + properties.size());

            String[] outboundMessages = new String[]{
            };
            for (MetadataService.FileProperties property : properties) {
                if (property.namespacePrefix != null) {
                    continue;
                }
                outboundMessages.add(property.fullName);
            }
            system.debug('task(): outboundMessages - ' + outboundMessages);

            if (outboundMessages.size() > 0 && allowFutureCall() && allowCallout()) {
                String proxyUrl = (context != null && context.sandboxName() == 'QA') ? System.LABEL.QA_Proxy : System.LABEL.LAB_Proxy;
                readAndUpdateOutboundMessages(outboundMessages, proxyURL, SessionHeader.sessionId);
                List<AsyncApexJob> jobList = [
                        Select Id, Status
                        from AsyncApexJob
                        where ApexClass.Name = :getClassName() and Status IN ('Queued', 'Pending') and JobType = 'Future'
                        order by createddate desc
                        LIMIT 1
                ];
                if (jobList.size() > 0) {
                    return jobList[0].Id;
                }
            }
        }
        return null;

    } // end of task()

    @Future(callout = true)
    private static void readAndUpdateOutboundMessages(String[] outboundMessages, String proxyURL, String sessionId){

        MetadataService.MetadataPort port = new MetadataService.MetadataPort();
        MetadataService.SessionHeader_element SessionHeader = new MetadataService.SessionHeader_element();
        SessionHeader.sessionId = sessionId;
        port.SessionHeader = SessionHeader;

        MetadataService.WorkflowOutboundMessage[] messageUpdateList = new MetadataService.WorkflowOutboundMessage[]{};
        // read metadata in batches of 10
        Integer index = 0;
        String[] readMessageList;
        do {
            readMessageList = new String[]{};
            for(Integer i=0; i < SandboxPostCopyTask.METADATA_RECORD_LIMIT && index < outboundMessages.size(); i++){
                readMessageList.add(outboundMessages[index]);
                index++;
            }
            system.debug('readAndUpdateOutboundMessages(): readMessageList - ' + readMessageList);
            MetadataService.IReadResult readResult = port.readMetadata('WorkflowOutboundMessage', readMessageList);
            MetadataService.WorkflowOutboundMessage[] messageList = (MetadataService.WorkflowOutboundMessage[]) readResult.getRecords();
            for (MetadataService.WorkflowOutboundMessage message :messageList) {
                message.endpointUrl = message.endpointUrl.replace(System.LABEL.Corp_Proxy, proxyURL);
                messageUpdateList.add(message);
            }
        }while (index < outboundMessages.size());

        system.debug('readAndUpdateOutboundMessages(): messageUpdateList size - ' + messageUpdateList.size());
        if (messageUpdateList.size() == 0) {
            return;
        }

        // update metadata in batches of 10
        Integer updateCount = 0;
        MetadataService.WorkflowOutboundMessage[] updateMetadataList;
        do {
            updateMetadataList = new MetadataService.WorkflowOutboundMessage[]{};
            for(Integer i=0; i < SandboxPostCopyTask.METADATA_RECORD_LIMIT && updateCount < messageUpdateList.size(); i++){
                updateMetadataList.add(messageUpdateList[updateCount]);
                updateCount++;
            }
            system.debug('readAndUpdateOutboundMessages(): updateMetadataList - ' + updateMetadataList);
            MetadataService.SaveResult[] resultList = port.updateMetadata(updateMetadataList);
            for (MetadataService.SaveResult result : resultList) {
                if (result.success != true) {
                    system.debug(result.errors);
                    system.debug('readAndUpdateOutboundMessages(): Failed to update - ' + result.fullName);
                }
            }
        }while (updateCount < messageUpdateList.size());



    } // end of readAndUpdateOutboundMessages()
}