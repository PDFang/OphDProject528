@RestResource(urlMapping = '/CommunityPermissionSet/*')
global with sharing class CommunityPermissionSetService {

    public class CommunityPermissionSetException extends exception{}

    public class CommunityPermissionSet{
        public boolean isAssigned;
        public String permissionSetLabel;
        public String permissionSetName;
        public CommunityPermissionSet(String name, String Label){
            this.permissionSetName = name;
            this.permissionSetLabel = label;
            this.isAssigned = false;
        }
    }

    global class HttpGetResponse{
        public String message;
        public String status;
        public List<CommunityPermissionSet> permissionSets;
    }

    public class HttpPostRequest{
        public String federationId;
        public List<CommunityPermissionSet> assignmentList;
    }

    global class HttpPostResponse{
        public String message;
        public String status;
    }

    @HttpGet
    global static HttpGetResponse getPermissionSets(){

        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        HttpGetResponse response = new HttpGetResponse();
        try {
            String federationId = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);
            system.debug('getPermissionSets(): federationId - ' +federationId);

            List<User> userList = [Select Id, Profile.UserLicenseId, Profile.UserLicense.Name from User where FederationIdentifier = :federationId];
            if (userList.isEmpty()) {
                response.status = 'Failed';
                response.message = 'USER_NOT_FOUND';
                return response;
            }
            system.debug('getPermissionSets(): userinfo - ' + userList[0]);

            Map<String, Community_Permission_Sets__c> settingsMap = Community_Permission_Sets__c.getAll();
            if (settingsMap.isEmpty()) {
                response.status = 'Failed';
                response.message = 'NO_DATA_FOUND';
                return response;
            }

            Set<String> permissionSet = new Set<String>();
            for(Community_Permission_Sets__c setting : settingsMap.values()){
                permissionSet.add(setting.Permission_Set__c);
            }
            system.debug('getPermissionSets(): permissionSet - ' + permissionSet);
            Map<String, PermissionSet> permissionSetMap = getPermissionSetDetail(permissionSet, userList[0].Profile.UserLicenseId);
            system.debug('getPermissionSets(): permissionSetMap - ' +permissionSetMap);
            if (settingsMap.isEmpty()) {
                response.status = 'Success';
                response.message = 'SUCCESS';
                response.permissionSets = new List<CommunityPermissionSet>();
                return response;
            }

            Map<Id, PermissionSetAssignment> permissionAssignmentMap = getPermissionSetAssignment(userList[0].Id, permissionSetMap.keySet());
            system.debug('getPermissionSets(): permissionAssignmentMap - ' +permissionAssignmentMap);

            List<CommunityPermissionSet> permissionSetList = new List<CommunityPermissionSet>();
            for (PermissionSet ps : permissionSetMap.values()) {
                CommunityPermissionSet communityPermission = new CommunityPermissionSet(ps.Name, ps.Label);
                communityPermission.isAssigned = permissionAssignmentMap.containsKey(ps.Id);
                permissionSetList.add(communityPermission);
            }
            system.debug('getPermissionSets(): permissionSetList - ' +permissionSetList);

            response.status = 'Success';
            response.message = 'SUCCESS';
            response.permissionSets = permissionSetList;
        } catch(System.Exception ex){
            response.status = 'Failed';
            response.message = ex.getMessage();
        }
        return response;

    }

/*
    @HttpPost
    global static HttpPostResponse addRemoveAccess(){
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        system.debug('addRemoveAccess(): header - ' + req.headers);
        system.debug('addRemoveAccess(): requestBody - ' + req.requestBody);

        HttpPostResponse response = new HttpPostResponse();

        HttpPostRequest request = null;
        try {
            request = (HttpPostRequest) JSON.deserialize(req.requestBody.toString(), HttpPostRequest.class);
            system.debug('addRemoveAccess(): request - ' +request);
        } catch(system.JSONException ex){
            system.debug('addRemoveAccess(): JSONException - ' +ex);
            response.status = 'Failed';
            response.message = 'BAD_REQUEST';
            return response;
        }

        Savepoint beforeDML = null;
        try {
            String federationId = request.federationId;
            system.debug('addRemoveAccess(): federationId - ' +federationId);
            List<CommunityAssignment> assignmentList = request.assignmentList;
            system.debug('addRemoveAccess(): assignmentList - ' +assignmentList);

            List<User> userList = [Select Id, Profile.UserLicense.Name from User where FederationIdentifier = :federationId];
            if (userList.isEmpty()) {
                response.status = 'Failed';
                response.message = 'USER_NOT_FOUND';
                return response;
            }

            Map<String, Community_Permission_Sets__c> communityConfigMap = Community_Permission_Sets__c.getAll();
            if (communityConfigMap.isEmpty()) {
                response.status = 'Failed';
                response.message = 'NO_DATA_FOUND';
                return response;
            }

            Map<String, PermissionSet> permissionSetMap = getPermissionSet(communityConfigMap.values());
            system.debug('addRemoveAccess(): permissionSetMap - ' +permissionSetMap);
            Map<String, PermissionSetAssignment> permissionAssignmentMap = getPermissionSetAssignment(userList[0].Id, permissionSetMap.keySet());
            system.debug('addRemoveAccess(): permissionAssignmentMap - ' +permissionAssignmentMap);

            List<PermissionSetAssignment> addList = new List<PermissionSetAssignment>();
            List<PermissionSetAssignment> removeList = new List<PermissionSetAssignment>();
            for(CommunityAssignment assignment : assignmentList){
                Community_Permission_Sets__c communityConfig = communityConfigMap.get(assignment.communityName);
                if(communityConfig == null){
                    throw new CommunityPermissionSetException('INVALID_COMMUNITY  -  ' + assignment.communityName);
                }
                if(assignment.isAssigned && !permissionAssignmentMap.containsKey(communityConfig.Permission_Set__c)
                        && permissionSetMap.containsKey(communityConfig.Permission_Set__c)){
                    PermissionSetAssignment psa = new PermissionSetAssignment();
                    psa.AssigneeId = userList[0].Id;
                    psa.PermissionSetId = permissionSetMap.get(communityConfig.Permission_Set__c).Id;
                    addList.add(psa);
                }
                else if(!assignment.isAssigned && permissionAssignmentMap.containsKey(communityConfig.Permission_Set__c)){
                    PermissionSetAssignment psa =permissionAssignmentMap.get(communityConfig.Permission_Set__c);
                    removeList.add(psa);
                } else{

                }

            }
            system.debug('addRemoveAccess(): addList - ' +addList);
            system.debug('addRemoveAccess(): removeList - ' +removeList);

            beforeDML = Database.setSavepoint();
            if(addList.isEmpty() == false){
                insert addList;
            }

            if(removeList.isEmpty() == false){
                delete removeList;
            }
            response.status = 'Success';
            response.message = 'SUCCESS';

        } catch(System.DMLException ex){
            system.debug('addRemoveAccess(): DMLException - ' +ex);
            Database.Rollback(beforeDML);
            response.status = 'Failed';
            response.message = ex.getMessage();
        } catch(System.Exception ex){
            system.debug('addRemoveAccess(): exception - ' +ex);
            response.status = 'Failed';
            response.message = ex.getMessage();
        }
        return response;
    }
*/
    private static Map<String, PermissionSet> getPermissionSetDetail(Set<String> permissionSet, Id licenseId){
        Map<String, PermissionSet> permissionSetMap = new Map<String, PermissionSet>();
        for (PermissionSet ps: [
                Select Id, Label, Name, UserLicense.Name from PermissionSet
                where Name IN :permissionSet and UserLicenseId = :licenseId
        ]) {
            permissionSetMap.put(ps.Name, ps);
        }
        return permissionSetMap;
    }

    private static  Map<Id, PermissionSetAssignment> getPermissionSetAssignment(Id assigneeId, Set<String> permissionSet) {
        Map<Id, PermissionSetAssignment> permissionAssignmentMap = new Map<Id, PermissionSetAssignment>();
        for (PermissionSetAssignment psa : [
                Select PermissionSetId, PermissionSet.Name, AssigneeId
                from PermissionSetAssignment
                where AssigneeId = :assigneeId and PermissionSet.Name IN :permissionSet
        ]) {
            permissionAssignmentMap.put(psa.PermissionSetId, psa);
        }
        return permissionAssignmentMap;
    }

}