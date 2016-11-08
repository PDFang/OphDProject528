@IsTest
private class CommunityHeaderControllerTests {
    static testMethod void CommunityHeaderController_getPermissionSets() {
        //Act
        Test.startTest();
        List<CommunityHeaderMapping__mdt> mappings = CommunityHeaderController.getPermissionSets();
        Test.stopTest();

        //Assert
        system.assert(mappings.size() > 0);
    }
}