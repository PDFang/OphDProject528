@isTest
public class CommunityPermissionSetServiceTest {

    static testmethod void getPermissionSetsTest(){

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
        Community_Permission_Sets__c newConfig = new Community_Permission_Sets__c();
        newConfig.Name = 'Test Community';
        newConfig.Community_Name__c = 'Test Community';
        newConfig.Permission_Set__c = ps.Name;
        newConfig.Community_Tab_Name__c = 'Test Community';
        newConfig.Community_URL__c = '/TestCommunity';
        insert newConfig;

        test.startTest();
        System.RestContext.request = new RestRequest();
        RestContext.request.requestURI = '/CommunityPermissionSet/' + testuser.FederationIdentifier;
        CommunityPermissionSetService.HttpGetResponse response = CommunityPermissionSetService.getPermissionSets();
        test.stopTest();

        system.assertEquals('Success', response.status);
        system.assertEquals('SUCCESS', response.message);
    }

    static testmethod void noUserGetPermissionSetsTest(){

        test.startTest();
        System.RestContext.request = new RestRequest();
        RestContext.request.requestURI = '/CommunityPermissionSet/testuser';
        CommunityPermissionSetService.HttpGetResponse response = CommunityPermissionSetService.getPermissionSets();
        test.stopTest();

        system.assertEquals('Failed', response.status);
        system.assertEquals('USER_NOT_FOUND', response.message);

    }

    static testmethod void noDataGetPermissionSetsTest(){

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
        RestContext.request.requestURI = '/CommunityPermissionSet/' + testuser.FederationIdentifier;
        CommunityPermissionSetService.HttpGetResponse response = CommunityPermissionSetService.getPermissionSets();
        test.stopTest();

        system.assertEquals('Failed', response.status);
        system.assertEquals('NO_DATA_FOUND', response.message);
    }


}