/**
 * Created by ravish.chawla on 9/11/2017.
 */

public with sharing class ChangeCommunityPasswordController {

    String redirectURL = System.Label.Identity_Server;
    public String retURL {get; set;}

    public void changeCommunityPassword() {
        system.debug('userInfo.getUserId()' + UserInfo.getUserId());
        List<User> currentUser = [Select Id, ContactId, Contact.ADFSGuid__c from User where Id =: UserInfo.getUserId()];
        String prevURL = ApexPages.currentPage().getHeaders().get('Referer');
        retURL = redirectURL + 'guid=' + currentUser[0].Contact.ADFSGuid__c + '&redirectUrl=' + prevURL;
    }

    public ChangeCommunityPasswordController(){
        changeCommunityPassword();
    }
}