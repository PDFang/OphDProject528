@IsTest
private class CommunityHeaderControllerTests {

    static testMethod void CommunityHeaderController_getCommunityLinks() {

        Id currentUserId = userInfo.getUserId();

        List<User> adminUsers = [Select Id from User where Profile.Name = 'System Administrator' and isActive = true];
        PermissionSet[] permissionSets = new PermissionSet[]{};
        // avoid MIXED_DML
        system.runAs(adminUsers[0]) {
            // Create permission sets
            PermissionSet partnerPermissionSet = new PermissionSet();
            partnerPermissionSet.Label = 'Partner Community User Test';
            partnerPermissionSet.Name = 'Partner_Community_User_Test';
            permissionSets.add(partnerPermissionSet);

            PermissionSet customerPermissionSet = new PermissionSet();
            customerPermissionSet.Label = 'Customer Community User Test';
            customerPermissionSet.Name = 'Customer_Community_User_Test';
            permissionSets.add(customerPermissionSet);
            insert permissionSets;

            // Assign one permission set to current user
            PermissionSetAssignment partnerAssignment = new PermissionSetAssignment();
            partnerAssignment.PermissionSetId = permissionSets[0].Id;
            partnerAssignment.AssigneeId = currentUserId;
            insert partnerAssignment;
        }

        // create community permission sets
        List<Community_Permission_Sets__c> communityPermissionSets = new List<Community_Permission_Sets__c>();

        Community_Permission_Sets__c set1 = new Community_Permission_Sets__c();
        set1.Name = 'Support Site';
        set1.Community_Name__c = 'Support Site';
        set1.Community_Tab_Name__c = 'Support Site';
        set1.Community_URL__c = 'incontact.com/support';
        set1.IsActive__c = true;
        set1.Permission_Set__c = null;
        communityPermissionSets.add(set1);

        Community_Permission_Sets__c set2 = new Community_Permission_Sets__c();
        set2.Name = 'Partner Community';
        set2.Community_Name__c = 'Partner Community';
        set2.Community_Tab_Name__c = 'Partner Community';
        set2.Community_URL__c = 'incontact.com/partner';
        set2.IsActive__c = true;
        set2.Permission_Set__c = permissionSets[0].Name;
        communityPermissionSets.add(set2);

        Community_Permission_Sets__c set3 = new Community_Permission_Sets__c();
        set3.Name = 'Customer Community';
        set3.Community_Name__c = 'Customer Community';
        set3.Community_Tab_Name__c = 'Customer Community';
        set3.Community_URL__c = 'incontact.com/customer';
        set3.IsActive__c = true;
        set3.Permission_Set__c = permissionSets[1].Name;
        communityPermissionSets.add(set3);

        insert communityPermissionSets;

        Test.startTest();
        List<Community_Permission_Sets__c> links = CommunityHeaderController.getCommunityLinks();
        Test.stopTest();

        //Assert
        system.assertEquals(2, links.size(), 'User should only see the Support Site and Partner Community.');

    } // end of CommunityHeaderController_getCommunityLinks()
}