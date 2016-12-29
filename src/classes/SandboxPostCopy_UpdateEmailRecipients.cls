/**
 * Created by mohandaas.rangaswamy on 12/22/2016.
 */
public class SandboxPostCopy_UpdateEmailRecipients extends SandboxPostCopyTask{

    static final Integer METADATA_RECORD_LIMIT = 10;

    public override String getClassName(){
        return 'SandboxPostCopy_UpdateEmailRecipients';
    }

    public override string task(SandboxContext context) {

        MetadataService.MetadataPort port = new MetadataService.MetadataPort();
        MetadataService.SessionHeader_element SessionHeader = new MetadataService.SessionHeader_element();
        SessionHeader.sessionId = userinfo.getSessionId();
        port.SessionHeader = SessionHeader;

        MetadataService.ListMetadataQuery queryElement = new MetadataService.ListMetadataQuery();
        queryElement.type_x = 'WorkflowAlert';
        MetadataService.ListMetadataQuery[] queryList = new MetadataService.ListMetadataQuery[]{
                queryElement
        };
        Double version = 38.0;
        MetadataService.FileProperties[] properties = port.listMetadata(queryList, version);
        system.debug('task(): Total no.of email alerts retrieved ' + properties.size());

        String[] emailAlerts = new String[]{
        };
        for (MetadataService.FileProperties property : properties) {
            if (property.namespacePrefix != null) {
                continue;
            }
            emailAlerts.add(property.fullName);
        }
        system.debug('task(): emailAlerts - ' + emailAlerts);

        if (emailAlerts.size() > 0) {
            readAndUpdateEmailAlert(emailAlerts, SessionHeader.sessionId);
            List<AsyncApexJob> jobList = [
                    Select Id, Status from AsyncApexJob
                    where ApexClass.Name = :getClassName() and Status IN ('Queued', 'Pending') and JobType = 'Future'
                    order by createddate desc LIMIT 1
            ];
            if(jobList.size() > 0){
                return jobList[0].Id;
            }
        }
        return null;

    } // end of task()

    @Future(callout = true)
    private static void readAndUpdateEmailAlert(String[] emailAlerts, String sessionId){

        MetadataService.MetadataPort port = new MetadataService.MetadataPort();
        MetadataService.SessionHeader_element SessionHeader = new MetadataService.SessionHeader_element();
        SessionHeader.sessionId = sessionId;
        port.SessionHeader = SessionHeader;

        MetadataService.WorkflowAlert[] emailUpdateList = new MetadataService.WorkflowAlert[]{};
        // read metadata in batches of 10
        Integer index = 0;
        String[] readAlertList;
        do {
            readAlertList = new String[]{};
            for(Integer i=0; i < METADATA_RECORD_LIMIT && index < emailAlerts.size(); i++){
                readAlertList.add(emailAlerts[index]);
                index++;
            }
            system.debug('readAndUpdateEmailAlert(): readAlertList - ' + readAlertList);
            MetadataService.IReadResult readResult = port.readMetadata('WorkflowAlert', readAlertList);
            MetadataService.WorkflowAlert[] emailALertList = (MetadataService.WorkflowAlert[]) readResult.getRecords();
            for (MetadataService.WorkflowAlert emailAlert :emailALertList) {
                if (emailAlert.ccEmails != null && emailAlert.ccEmails.size() > 0) {
                    emailAlert.ccEmails = new String[]{
                            'itdevelopers@example.com'
                    };
                    emailUpdateList.add(emailAlert);
                }
            }
        }while (index < emailAlerts.size());

        system.debug('readAndUpdateEmailAlert(): emailUpdateList size - ' + emailUpdateList.size());
        if (emailUpdateList.size() == 0) {
            return;
        }

        // update metadata in batches of 10
        Integer updateCount = 0;
        MetadataService.WorkflowAlert[] updateMetadataList;
        do {
            updateMetadataList = new MetadataService.WorkflowAlert[]{};
            for(Integer i=0; i < METADATA_RECORD_LIMIT && updateCount < emailUpdateList.size(); i++){
                updateMetadataList.add(emailUpdateList[updateCount]);
                updateCount++;
            }
            system.debug('readAndUpdateEmailAlert(): updateMetadataList - ' + updateMetadataList);
            MetadataService.SaveResult[] resultList = port.updateMetadata(updateMetadataList);
            for (MetadataService.SaveResult result : resultList) {
                if (result.success != true) {
                    system.debug(result.errors);
                    system.debug('readAndUpdateEmailAlert(): Failed to update - ' + result.fullName);
                }
            }
        }while (updateCount < emailUpdateList.size());



    } // end of readAndUpdateEmailAlert()
}