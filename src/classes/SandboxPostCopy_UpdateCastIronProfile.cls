/**
 * Created by mohandaas.rangaswamy on 12/27/2016.
 */
// Disable Api Only User permission in Cast Iron profile
public with sharing class SandboxPostCopy_UpdateCastIronProfile extends SandboxPostCopyTask{

    public override String getClassName(){
        return 'SandboxPostCopy_UpdateCastIronProfile';
    }

    public override string task(SandboxContext context) {

        String[] profiles = new String[]{};
        for(Profile p : [SELECT Id, Name FROM Profile where Name = '_castiron Profile']){
            profiles.add(p.Name);
        }
        if (profiles.size() > 0 && allowFutureCall() && allowCallout()) {
            disableApiOnlyUserPermission(profiles, userinfo.getSessionId());
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
    private static void disableApiOnlyUserPermission(String[] profiles, String sessionId){

        MetadataService.MetadataPort port = new MetadataService.MetadataPort();
        MetadataService.SessionHeader_element SessionHeader = new MetadataService.SessionHeader_element();
        SessionHeader.sessionId = sessionId;
        port.SessionHeader = SessionHeader;
        port.timeout_x = 80000;
        MetadataService.Profile[] updateMetadataList = new MetadataService.Profile[]{};
        MetadataService.Profile newProfile = new MetadataService.Profile();
        newProfile.fullName = profiles[0];
        MetadataService.ProfileUserPermission apiUserPermission = new MetadataService.ProfileUserPermission();
        apiUserPermission.name = 'ApiUserOnly';
        apiUserPermission.enabled = false;
        newProfile.userPermissions = new MetadataService.ProfileUserPermission[]{apiUserPermission};
        updateMetadataList.add(newProfile);

        MetadataService.SaveResult[] resultList = port.updateMetadata(updateMetadataList);
        for (MetadataService.SaveResult result : resultList) {
            if (result.success != true) {
                system.debug(result.errors);
                system.debug('disableApiOnlyUserPermission(): Failed to update - ' + result.fullName);
            }
        }

    } // end of deleteNamedCredentials()

}