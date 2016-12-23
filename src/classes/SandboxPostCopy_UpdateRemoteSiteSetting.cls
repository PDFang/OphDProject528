/**
 * Created by mohandaas.rangaswamy on 12/22/2016.
 */
public class SandboxPostCopy_UpdateRemoteSiteSetting extends SandboxPostCopyTask{

    public override String getClassName(){
        return 'SandboxPostCopy_UpdateRemoteSiteSetting';
    }

    public override void task(SandboxContext context){

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
        MetadataService.FileProperties[]  properties = port.listMetadata(queryList,version);
        system.debug('task(): Total no.of remote sites retrieved ' + properties.size());

        String[] remoteSites = new String[]{};
        for(MetadataService.FileProperties property :  properties){
            if(property.namespacePrefix != null){
                continue;
            }
            remoteSites.add(property.fullName);
        }
        system.debug('task(): remoteSites - ' + remoteSites);

        if(remoteSites.size() > 0) {
            MetadataService.IReadResult readResult = port.readMetadata('RemoteSiteSetting', remoteSites);
            MetadataService.RemoteSiteSetting[] remoteSiteList = (MetadataService.RemoteSiteSetting[])readResult.getRecords();
            for(MetadataService.RemoteSiteSetting remoteSite :remoteSiteList){
                remoteSite.isActive = false;
            }
            MetadataService.SaveResult[] resultList = port.updateMetadata(remoteSiteList);
            for (MetadataService.SaveResult result : resultList) {
                if (result.success != true) {
                    system.debug(result.errors);
                    system.debug('task(): Failed to update - ' + result.fullName);
                }
            }
        }

    } // end of task()
}