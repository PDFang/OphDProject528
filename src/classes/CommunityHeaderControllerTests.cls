@IsTest
private class CommunityHeaderControllerTests {
    static testMethod void CommunityHeaderController_getCommunityLinks() {
        //Act
        Test.startTest();
        List<Community_Permission_Sets__c> links = CommunityHeaderController.getCommunityLinks();
        Test.stopTest();

        //Assert
        system.assert(links.size() > 0);
    }
}