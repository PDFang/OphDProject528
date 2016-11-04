@RestResource(urlMapping = '/CommunityAccess/*')
global with sharing class CommunityAccessService {

    public class CommunityAccessException extends exception{}

    public class CommunityInfo{
        public boolean isActive;
        public boolean isAssigned;
        public String communityName;
        public CommunityInfo(Community_Configuration__c config){
            this.isActive = config.IsActive__c;
            this.communityName = config.Name;
        }
    }

    global class HttpGetResponse{
        public String message;
        public String status;
        public List<CommunityInfo> communities;

    }

    public class CommunityAssignment{
        public boolean isAssigned;
        public String communityName;
    }

    public class HttpPostRequest{
        public String federationId;
        public List<CommunityAssignment> assignmentList;
    }

    global class HttpPostResponse{
        public String message;
        public String status;
    }

    @HttpGet
    global static HttpGetResponse getCommunities(){

        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        HttpGetResponse response = new HttpGetResponse();
        try {
            String federationId = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);
            system.debug('getCommunities(): federationId - ' +federationId);

            List<User> userList = [Select Id, Profile.UserLicense.Name from User where FederationIdentifier = :federationId];
            if (userList.isEmpty()) {
                response.status = 'Failed';
                response.message = 'USER_NOT_FOUND';
                return response;
            }

            String licenseType = userList[0].Profile.UserLicense.Name;
            Boolean isCustomer = licenseType.contains('Customer');
            Map<String, Community_Configuration__c> communityConfigMap = Community_Configuration__c.getAll();
            if (communityConfigMap.isEmpty()) {
                response.status = 'Failed';
                response.message = 'NO_DATA_FOUND';
                return response;
            }

            Map<String, PermissionSet> permissionSetMap = getPermissionSet(communityConfigMap.values());
            system.debug('getCommunities(): permissionSetMap - ' +permissionSetMap);
            Map<String, PermissionSetAssignment> permissionAssignmentMap = getPermissionSetAssignment(userList[0].Id, permissionSetMap.keySet());
            system.debug('getCommunities(): permissionAssignmentMap - ' +permissionAssignmentMap);

            List<CommunityInfo> communityList = new List<CommunityInfo>();
            for (Community_Configuration__c config : communityConfigMap.values()) {
                PermissionSet ps = permissionSetMap.get(config.Permission_Set__c);
                String userLicense = ps.UserLicense.Name;
                if (isCustomer && String.isNotBlank(userLicense) && !userLicense.Contains('Customer')) {
                    continue;
                }
                CommunityInfo community = new CommunityInfo(config);
                community.isAssigned = permissionAssignmentMap.containsKey(ps.Name);
                communityList.add(community);
            }
            system.debug('getCommunities(): communityList - ' +communityList);

            response.status = 'Success';
            response.message = 'SUCCESS';
            response.communities = communityList;
        } catch(System.Exception ex){
            response.status = 'Failed';
            response.message = ex.getMessage();
        }
        return response;

    }

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

            Map<String, Community_Configuration__c> communityConfigMap = Community_Configuration__c.getAll();
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
                Community_Configuration__c communityConfig = communityConfigMap.get(assignment.communityName);
                if(communityConfig == null){
                    throw new CommunityAccessException('INVALID_COMMUNITY  -  ' + assignment.communityName);
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

    private static Map<String, PermissionSet> getPermissionSet(List<Community_Configuration__c> configList){
        Set<String> permissionSet = new Set<String>();
        for (Community_Configuration__c config : configList) {
            permissionSet.add(config.Permission_Set__c);
        }
        Map<String, PermissionSet> permissionSetMap = new Map<String, PermissionSet>();
        for (PermissionSet ps: [Select Id, Name, UserLicense.Name from PermissionSet where Name IN :permissionSet]) {
            permissionSetMap.put(ps.Name, ps);
        }
        return permissionSetMap;
    }

    private static  Map<String, PermissionSetAssignment> getPermissionSetAssignment(Id assigneeId, Set<String> permissionSet) {
        Map<String, PermissionSetAssignment> permissionAssignmentMap = new Map<String, PermissionSetAssignment>();
        for (PermissionSetAssignment psa : [
                Select PermissionSet.Name, AssigneeId
                from PermissionSetAssignment
                where AssigneeId = :assigneeId and PermissionSet.Name IN :permissionSet
        ]) {
            permissionAssignmentMap.put(psa.PermissionSet.Name, psa);
        }
        return permissionAssignmentMap;
    }

}