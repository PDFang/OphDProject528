@RestResource(urlMapping='/CommunityProfile/*')
global with sharing class CommunityProfileService {
    global class HttpGetResponse{
        public String status;
        public String message;
        public List<Profile> profileList;
    }

    @HttpGet
    global static HttpGetResponse getProfiles( ) {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        HttpGetResponse response = new HttpGetResponse();
        try {
            Map<String, String> params = RestContext.request.params;
            String inputLicenseName = params.get('licenseName');
            String inputIsCustom = params.get('isCustom');
            boolean isCustomValue = false;
            if (inputIsCustom == 'TRUE')
                isCustomValue = true;

            Set<Id> userLicenseIds = new Set<Id>();
            List<Profile> profileList = new List<Profile>();

            // Get list of UserLicenses Ids based on licenseName
            for (UserLicense userLicense : [SELECT Id FROM UserLicense WHERE Name = :inputLicenseName ]) {
                userLicenseIds.add(userLicense.Id);
            }

            // Get list of Profile Ids based on userLicenseIds
            for (PermissionSet permissionset : [SELECT Profile.Id, Profile.Name FROM PermissionSet WHERE IsCustom = : isCustomValue AND IsOwnedByProfile = true AND Profile.UserLicenseId IN : userLicenseIds ]) {
                profileList.add(permissionset.Profile);
            }

            // Failed response when Get no Profile
            if (profileList.isEmpty()) {
                response.status = 'Failed';
                response.message = 'Profile_NOT_FOUND';
                return response;
            }

            // Success response when Get some Profiles
            response.status = 'Success';
            response.message = 'Sucess';
            response.profileList = profileList;

        } catch(System.Exception ex){
            response.status = 'Failed';
            response.message = 'Exception: ' + ex.getMessage();
        }
        return response;
    }
}