@isTest
public with sharing class CommunityProfileServiceTest {
    static testmethod void failedExceptionGetgetProfilesTest(){

        test.startTest();
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/CommunityProfile/';
        req.httpMethod = 'GET';

        CommunityProfileService.HttpGetResponse response = CommunityProfileService.getProfiles();
        test.stopTest();

        system.assertEquals('Failed', response.status);
        Boolean hasException = response.message.contains('Exception');
        system.assert(hasException);
    }

    static testmethod void noResultGetProfilesTest(){

        test.startTest();
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/CommunityProfile/';
        request.addParameter('licenseName', 'Impossible License Name');
        request.addParameter('isCustom', 'TRUE');
        request.httpMethod = 'GET';
        RestContext.request = request;

        CommunityProfileService.HttpGetResponse response = CommunityProfileService.getProfiles();
        test.stopTest();

        system.assertEquals('Failed', response.status);
        system.assertEquals('Profile_NOT_FOUND', response.message);
    }
}