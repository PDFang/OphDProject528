/**
 * Created by arnab.karsarkar on 10/17/2016.
 */

public without sharing class CommunityHeaderController {

    @AuraEnabled
    public static list<CommunityHeaderMapping__mdt> getPermissionSets()
    {
        UserInfo.getUserId();
        CommunityHeaderMapping__mdt[] allMappings = [SELECT Label, CommunityName__c, CommunityURL__c
                                                     FROM CommunityHeaderMapping__mdt
                                                     WHERE PermissionSetName__c = null OR
                                                           PermissionSetName__c IN ('Partner_Community_Implementation_Premise',
                                                                                    'Partner_Community_Implementation_SaaS')];
        return allMappings;
    }
}