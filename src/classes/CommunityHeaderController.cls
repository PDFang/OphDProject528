/**
 * Created by arnab.karsarkar on 10/17/2016.
 */

public without sharing class CommunityHeaderController {

    @AuraEnabled
    public static list<CommunityHeaderMapping__mdt> getPermissionSets()
    {
        CommunityHeaderMapping__mdt[] mappings = [select CommunityURL__c From CommunityHeaderMapping__mdt ];
        return mappings;
    }
}