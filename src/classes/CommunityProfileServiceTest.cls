@isTest
public with sharing class CommunityProfileServiceTest {
    static final string restApi = '/services/apexrest/CommunityProfile/';

    static testmethod void TestGetProfiles_HasResult(){

        Id userLicenseId = [SELECT Profile.UserLicenseId FROM PermissionSet WHERE IsCustom = : true AND IsOwnedByProfile = true AND Profile.UserLicenseId != '' LIMIT 1].Profile.UserLicenseId;
        string licenseName = [SELECT Name FROM UserLicense WHERE Id = : userLicenseId LIMIT 1].Name;

        test.startTest();
        RestRequest req = new RestRequest();
        req.requestURI = restApi;
        req.addParameter('licenseName', licenseName);
        req.addParameter('isCustom', 'TRUE');
        req.httpMethod = 'GET';
        RestContext.request = req;

        CommunityProfileService.HttpGetResponse res = CommunityProfileService.getProfiles();
        test.stopTest();

        system.assertEquals('Success', res.status);
    }

    static testmethod void TestGetProfiles_NoResult(){

        test.startTest();
        RestRequest req = new RestRequest();
        req.requestURI = restApi;
        req.addParameter('licenseName', 'Impossible License Name');
        req.addParameter('isCustom', 'TRUE');
        req.httpMethod = 'GET';
        RestContext.request = req;

        CommunityProfileService.HttpGetResponse res = CommunityProfileService.getProfiles();
        test.stopTest();

        system.assertEquals('Failed', res.status);
        system.assertEquals('Profile_NOT_FOUND', res.message);
    }

    static testmethod void TestGetProfiles_FailedException(){

        test.startTest();
        RestRequest req = new RestRequest();
        req.requestURI = restApi;
        req.httpMethod = 'GET';

        CommunityProfileService.HttpGetResponse res = CommunityProfileService.getProfiles();
        test.stopTest();

        system.assertEquals('Failed', res.status);
        Boolean hasException = res.message.contains('Exception');
        system.assert(hasException);
    }
}