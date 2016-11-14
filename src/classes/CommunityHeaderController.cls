public without sharing class CommunityHeaderController {

    @AuraEnabled
    public static List<Community_Permission_Sets__c> getPermissionSets()
    {
        PermissionSetAssignment[] userPermissions = [SELECT PermissionSet.Name
									    			 FROM PermissionSetAssignment
									    			 WHERE AssigneeId =: Userinfo.getUserId()];
        
        Community_Permission_Sets__c[] communityLinks = [SELECT Community_Name__c, Community_URL__c, Permission_Set__c
                                                         FROM Community_Permission_Sets__c 
                                                         WHERE Permission_Set__c = null OR
                                                         	   Permission_Set__c IN ('Partner_Community_Implementation_Premise',
                                                                                     'Partner_Community_Implementation_SaaS', 
                                                                                     'Customer_Success_Access')
                                                         ORDER BY Community_Name__c];
        
        List<Community_Permission_Sets__c> userLinks = new List<Community_Permission_Sets__c>();
        for(Community_Permission_Sets__c commLink : communityLinks)
        {
           for(PermissionSetAssignment userPerm : userPermissions)
           {
               if(commLink.Permission_Set__c == null || commLink.Permission_Set__c == userPerm.PermissionSet.Name)
               {
                   userLinks.add(commLink);
               }
           }
        }
        
        /*CommunityHeaderMapping__mdt[] allMappings = [SELECT Label, CommunityName__c, CommunityURL__c
                                                     FROM CommunityHeaderMapping__mdt
                                                     WHERE PermissionSetName__c = null OR
                                                           PermissionSetName__c IN ('Partner_Community_Implementation_Premise',
                                                                                    'Partner_Community_Implementation_SaaS')];*/
        return userLinks;
    }
}