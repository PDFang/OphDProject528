@isTest
public class CommunityPermissionSetServiceTest {
/*
    static testmethod void getCommunitiesTest(){

        List<User> adminUser = [Select Id from User where isActive = true and Profile.Name = 'System Administrator'];
        PermissionSet ps;
        User testUser;
        // aviod mixed DML
        system.runAs(adminUser[0]) {
            ps = new PermissionSet();
            ps.Name = 'Test_Permission';
            ps.Label = 'Test Permission';
            insert ps;

            Profile profile = [SELECT Id from Profile where Name = 'System Administrator-CRM'];

            testUser = new User(
                    FirstName = 'test',
                    LastName = 'User',
                    Email = 'test@incontact.com',
                    Username = 'test@incontact.com',
                    Alias = 'test',
                    profileId = profile.Id,
                    EmailEncodingKey = 'UTF-8',
                    TimeZoneSidKey = 'America/Los_Angeles',
                    LocaleSidKey = 'en_US',
                    LanguageLocaleKey = 'en_US',
                    FederationIdentifier = 'testuser'
            );
            insert testUser;
        }
        Community_Configuration__c newConfig = new Community_Configuration__c();
        newConfig.Name = 'Test Community';
        newConfig.Permission_Set__c = ps.Name;
        newConfig.Tab_name__c = 'Test Community';
        newConfig.Community_URL__c = '/TestCommunity';
        insert newConfig;

        test.startTest();
        System.RestContext.request = new RestRequest();
        RestContext.request.requestURI = '/CommunityAccess/' + testuser.FederationIdentifier;
        CommunityAccessService.HttpGetResponse response = CommunityAccessService.getCommunities();
        test.stopTest();

        system.assertEquals('Success', response.status);
        system.assertEquals('SUCCESS', response.message);
    }

    static testmethod void noUserGetCommunitiesTest(){

        test.startTest();
        System.RestContext.request = new RestRequest();
        RestContext.request.requestURI = '/CommunityAccess/testuser';
        CommunityAccessService.HttpGetResponse response = CommunityAccessService.getCommunities();
        test.stopTest();

        system.assertEquals('Failed', response.status);
        system.assertEquals('NO_USER_FOUND', response.message);

    }

    static testmethod void noDataGetCommunitiesTest(){

        Profile profile = [SELECT Id from Profile where Name = 'System Administrator-CRM'];

        user testUser = new User(
            FirstName = 'test',
            LastName = 'User',
            Email = 'test@incontact.com',
            Username = 'test@incontact.com',
            Alias = 'test',
            profileId = profile.Id,
            EmailEncodingKey = 'UTF-8',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            FederationIdentifier = 'testuser'
        );
        insert testUser;

        test.startTest();
        System.RestContext.request = new RestRequest();
        RestContext.request.requestURI = '/CommunityAccess/' + testuser.FederationIdentifier;
        CommunityAccessService.HttpGetResponse response = CommunityAccessService.getCommunities();
        test.stopTest();

        system.assertEquals('Failed', response.status);
        system.assertEquals('NO_DATA_FOUND', response.message);
    }
*/

}