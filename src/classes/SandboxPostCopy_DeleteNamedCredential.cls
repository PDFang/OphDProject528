/**
 * Created by mohandaas.rangaswamy on 12/27/2016.
 */
// Delete named credentials
public with sharing class SandboxPostCopy_DeleteNamedCredential extends SandboxPostCopyTask{

    public override String getClassName(){
        return 'SandboxPostCopy_DeleteNamedCredential';
    }

    public override string task(SandboxContext context) {

        String[] credentials = new String[]{};
        for(NamedCredential c : [SELECT DeveloperName FROM NamedCredential where NamespacePrefix = null]){
            credentials.add(c.DeveloperName);
        }
        if (credentials.size() > 0 && allowFutureCall() && allowCallout()) {
            deleteNamedCredentials(credentials, userinfo.getSessionId());
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
    private static void deleteNamedCredentials(String[] credentials, String sessionId){

        MetadataService.MetadataPort port = new MetadataService.MetadataPort();
        MetadataService.SessionHeader_element SessionHeader = new MetadataService.SessionHeader_element();
        SessionHeader.sessionId = sessionId;
        port.SessionHeader = SessionHeader;

        // update metadata in batches of 10
        Integer count = 0;
        String[] deleteMetadataList;
        do {
            deleteMetadataList = new String[]{};
            for(Integer i=0; i < SandboxPostCopyTask.METADATA_RECORD_LIMIT && count < credentials.size(); i++){
                deleteMetadataList.add(credentials[count]);
                count++;
            }
            system.debug('deleteNamedCredentials(): deleteMetadataList - ' + deleteMetadataList);
            MetadataService.DeleteResult[] resultList = port.deleteMetadata('NamedCredential', deleteMetadataList);
            for (MetadataService.DeleteResult result : resultList) {
                if (result.success != true) {
                    system.debug(result.errors);
                    system.debug('deleteNamedCredentials(): Failed to update - ' + result.fullName);
                }
            }
        }while (count < credentials.size());

    } // end of deleteNamedCredentials()

}