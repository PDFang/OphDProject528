/**
 * Created by mohandaas.rangaswamy on 12/27/2016.
 */
// Disable Single Sign-On permission on all profiles
public with sharing class SandboxPostCopy_DisableSsoPermission extends SandboxPostCopyTask{

    static final Integer METADATA_RECORD_LIMIT = 10;

    public override String getClassName(){
        return 'SandboxPostCopy_DisableSsoPermission';
    }

    public override string task(SandboxContext context) {

        String[] profiles = new String[]{};
        for(Profile p : [SELECT Id, Name FROM Profile where IsSsoEnabled = true]){
            profiles.add(p.Name);
        }
        if (profiles.size() > 0 && allowFutureCall() && allowCallout()) {
            updateSsoPermission(profiles, userinfo.getSessionId());
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
    private static void updateSsoPermission(String[] profiles, String sessionId){

        MetadataService.MetadataPort port = new MetadataService.MetadataPort();
        MetadataService.SessionHeader_element SessionHeader = new MetadataService.SessionHeader_element();
        SessionHeader.sessionId = sessionId;
        port.SessionHeader = SessionHeader;
        port.timeout_x = 80000;
        // update metadata in batches of 10
        Integer profileCount = 0;
        MetadataService.Profile[] updateMetadataList;
        do {
            updateMetadataList = new MetadataService.Profile[]{};
            for(Integer i=0; i < METADATA_RECORD_LIMIT && profileCount < profiles.size(); i++){
                MetadataService.Profile newProfile = new MetadataService.Profile();
                newProfile.fullName = profiles[profileCount];
                MetadataService.ProfileUserPermission ssoPermission = new MetadataService.ProfileUserPermission();
                ssoPermission.name = 'IsSsoEnabled';
                ssoPermission.enabled = false;
                newProfile.userPermissions = new MetadataService.ProfileUserPermission[]{ssoPermission};
                updateMetadataList.add(newProfile);
                profileCount++;
            }
            system.debug('updateSsoPermission(): updateMetadataList - ' + updateMetadataList);
            MetadataService.SaveResult[] resultList = port.updateMetadata(updateMetadataList);
            for (MetadataService.SaveResult result : resultList) {
                if (result.success != true) {
                    system.debug(result.errors);
                    system.debug('updateSsoPermission(): Failed to update - ' + result.fullName);
                }
            }
        }while (profileCount < profiles.size());

    } // end of updateSsoPermission()

}