/**
 * Created by mohandaas.rangaswamy on 12/22/2016.
 */
public class SandboxPostCopy_UpdateRemoteSiteSetting extends SandboxPostCopyTask{

    static final Integer METADATA_RECORD_LIMIT = 10;

    public override String getClassName(){
        return 'SandboxPostCopy_UpdateRemoteSiteSetting';
    }

    public override string task(SandboxContext context) {

        MetadataService.MetadataPort port = new MetadataService.MetadataPort();
        MetadataService.SessionHeader_element SessionHeader = new MetadataService.SessionHeader_element();
        SessionHeader.sessionId = userinfo.getSessionId();
        port.SessionHeader = SessionHeader;

        MetadataService.ListMetadataQuery queryElement = new MetadataService.ListMetadataQuery();
        queryElement.type_x = 'RemoteSiteSetting';
        MetadataService.ListMetadataQuery[] queryList = new MetadataService.ListMetadataQuery[]{
                queryElement
        };
        Double version = 38.0;
        MetadataService.FileProperties[] properties = port.listMetadata(queryList, version);
        system.debug('task(): Total no.of remote sites retrieved ' + properties.size());

        String[] remoteSites = new String[]{
        };
        for (MetadataService.FileProperties property : properties) {
            if (property.namespacePrefix != null) {
                continue;
            }
            remoteSites.add(property.fullName);
        }
        system.debug('task(): remoteSites - ' + remoteSites);

        if (remoteSites.size() > 0) {
            readAndUpdateRemoteSite(remoteSites, SessionHeader.sessionId);
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
    private static void readAndUpdateRemoteSite(String[] remoteSites, String sessionId){

        MetadataService.MetadataPort port = new MetadataService.MetadataPort();
        MetadataService.SessionHeader_element SessionHeader = new MetadataService.SessionHeader_element();
        SessionHeader.sessionId = sessionId;
        port.SessionHeader = SessionHeader;

        MetadataService.RemoteSiteSetting[] remoteSiteUpdateList = new MetadataService.RemoteSiteSetting[]{};

        // read metadata in batches of 10
        Integer index = 0;
        String[] readMetadataList;
        do {
            readMetadataList = new String[]{};
            for(Integer i=0; i < METADATA_RECORD_LIMIT && index < remoteSites.size(); i++){
                readMetadataList.add(remoteSites[index]);
                index++;
            }
            system.debug('readAndUpdateRemoteSite(): readMetadataList - ' + readMetadataList);
            MetadataService.IReadResult readResult = port.readMetadata('RemoteSiteSetting', readMetadataList);
            MetadataService.RemoteSiteSetting[] remoteSiteList = (MetadataService.RemoteSiteSetting[])readResult.getRecords();
            for (MetadataService.RemoteSiteSetting remoteSite :remoteSiteList) {
                if (remoteSite.isActive) {
                    remoteSite.isActive = false;
                    remoteSiteUpdateList.add(remoteSite);
                }
            }
        }while (index < remoteSites.size());
        

        if (remoteSiteUpdateList.size() == 0) {
            return;
        }

        // update metadata in batches of 10
        Integer updateCount = 0;
        MetadataService.RemoteSiteSetting[] updateMetadataList;
        do {
            updateMetadataList = new MetadataService.RemoteSiteSetting[]{};
            for(Integer i=0; i < METADATA_RECORD_LIMIT && updateCount < remoteSiteUpdateList.size(); i++){
                updateMetadataList.add(remoteSiteUpdateList[updateCount]);
                updateCount++;
            }
            system.debug('readAndUpdateRemoteSite(): updateMetadataList - ' + updateMetadataList);
            MetadataService.SaveResult[] resultList = port.updateMetadata(updateMetadataList);
            for (MetadataService.SaveResult result : resultList) {
                if (result.success != true) {
                    system.debug(result.errors);
                    system.debug('readAndUpdateRemoteSite(): Failed to update - ' + result.fullName);
                }
            }
        }while (updateCount < remoteSiteUpdateList.size());
        

    } // end of readAndUpdateRemoteSite()
    
}