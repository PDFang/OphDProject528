public without sharing class CommunityDataAccess {

    // inner class
    public class AccountWrapper{
        public Account parent{get;set;}
        public List<Account> children{get;set;}
        public integer getNoOfChildren(){
            return this.children != null ? this.children.size() : 0;
        }
        public AccountWrapper(Account parent){
            this.Parent = parent;
            this.children = new List<Account>();
        }
    }

    // Returns list of accounts accessible to a community user
    public static List<AccountWrapper> getAccounts(String adfsGuid){

        system.debug('getAccounts() : adfsGuid - '+adfsGuid);
        List<AccountWrapper> wrapperList = new List<AccountWrapper>();
        if(String.isBlank(adfsGuid)){
            return wrapperList;
        }
        Map<Id, AccountWrapper> wrapperMap = new Map<Id, AccountWrapper>();
        // Get all the contacts matching ADFSGuid
        for(Contact c :[
                Select Id, Account.Id, Account.Name, Account.CadebillAccountNo__c
                from Contact
                where ADFSGuid__c = :adfsGuid
        ]){
            AccountWrapper wrapper = new AccountWrapper(c.Account);
            wrapperList.add(wrapper);
            wrapperMap.put(c.Account.Id, wrapper);
        }
        system.debug('getAccounts() : wrapperMap - '+wrapperMap);

        if(wrapperMap.isEmpty()){
            return wrapperList;
        }
        // Get child accounts
        for(Account child : [
                Select Id, Name, CadebillAccountNo__c, ParentId
                from Account
                where ParentId IN :wrapperMap.keySet()
        ]){
            AccountWrapper wrapper = wrapperMap.get(child.ParentId);
            wrapper.children.add(child);
        }
        system.debug('getAccounts() : wrapperList - '+wrapperList);

        return wrapperList;

    } // end of getAccounts()

    public static Map<Id, List<String>> getAccountRoles(String adfsGuid) {
        system.debug('getAccountRoles() : adfsGuid - '+adfsGuid);
        Map<Id, List<String>> accountRoles = new Map<Id, List<String>>();

        if(String.isBlank(adfsGuid)){
            return accountRoles;
        }

        for(CommunityRoles__c communityRole : [Select Contact__r.AccountId, Roles__c
                                                From CommunityRoles__c
                                                Where Contact__r.ADFSGuid__c = :adfsGuid
                                                And Roles__c != NULL]) {
            List<String> roleList = communityRole.Roles__c.Split(';');
            accountRoles.put(communityRole.Contact__r.AccountId, roleList);
        }

        return accountRoles;
    }
}