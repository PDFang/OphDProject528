public without sharing class CommunityHeaderController {

    @AuraEnabled
    public static List<Community_Permission_Sets__c> getCommunityLinks()
    {
        //Retrieve all community header links
        Community_Permission_Sets__c[] communityLinks = [
                SELECT Id, Community_Name__c, Community_URL__c, Permission_Set__c
                FROM Community_Permission_Sets__c
                where IsActive__c = true
                ORDER BY Community_Name__c
        ];
        Set<string> permissionStrings = new Set<string>();
        for(Community_Permission_Sets__c commLink : communityLinks)
        {
            permissionStrings.add(commLink.Permission_Set__c);
        }

        //Retrieve user permissions associated to a link
        PermissionSetAssignment[] userPerms = [SELECT PermissionSet.Name
                                               FROM PermissionSetAssignment
                                               WHERE AssigneeId =: Userinfo.getUserId() AND
                                                     PermissionSet.Name IN :permissionStrings];
        Map<string, PermissionSetAssignment> permissionMap = new Map<string, PermissionSetAssignment>();
        for(PermissionSetAssignment userPermission : userPerms)
        {
            permissionMap.put(userPermission.PermissionSet.Name, userPermission);
        }

        //Add links that the user has permission
        List<Community_Permission_Sets__c> userLinks = new List<Community_Permission_Sets__c>();
        for(Community_Permission_Sets__c commLink : communityLinks)
        {
            if(commLink.Permission_Set__c == null || permissionMap.containsKey(commLink.Permission_Set__c))
            {
                userLinks.add(commLink);
            }
        }

        return userLinks;
    }
}