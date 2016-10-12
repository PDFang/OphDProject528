public class CommunityAccountRoleViewController {
    
    public string accountId{get;set;}
    public string adfsGuid{get;set;}
    
    public List<SelectOption> accountList{get; private set;}
    private Map<Id, List<String>> accountRoles = null;
    
    public List<String> rolesList{get; private set;}
    
    public String getFullName(){
        return UserInfo.getFirstName() + ' ' + userInfo.getLastName();
    }
    
    public CommunityAccountRoleViewController(){        
        init();        
    }
    
    public pagereference submit(){
        init();
        return null;
    }
    
    private void init(){
        accountList = new List<SelectOption>();
        accountList.add(new SelectOption('', '- Select an Account -'));
        rolesList = new List<String>();

        List<User> currentUser = [
            Select Id, ContactId, Contact.ADFSGuid__c 
            from User
            where Id = :userInfo.getUserId()
        ];
        system.debug('init(): currentUser - '+currentUser);
        
        if(currentUser.isEmpty()){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 'User does not exist in Salesforce.'));
            return;
        } else if(currentUser[0].ContactId == null){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 'No Contact record found.'));
            return;
        } else if(currentUser[0].Contact.ADFSGuid__c == null){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 'Contact ADFS Guid is blank.'));
            return;
        }
        adfsGuid = currentUser[0].Contact.ADFSGuid__c;
        system.debug('init(): adfsGuid - '+adfsGuid);
        
        fetchAccounts(adfsGuid);
        fetchRoles(adfsGuid);
    }
    
    public pagereference selectAccount(){
        
        rolesList = new List<String>();
        system.debug('selectAccount(): accountId - ' + accountId);
        
        if(String.isBlank(this.accountId) || accountRoles == null 
        || !accountRoles.containsKey(this.accountId) || accountRoles.get(this.accountId).size() == 0){
            rolesList.add('None');
            return null;
        }
        for(String role : accountRoles.get(this.accountId)){
            rolesList.add(role);
        }
        system.debug('selectAccount(): rolesList - ' + rolesList);
        
        return null;
    }
    
    private void fetchAccounts(String adfsGuid){
        
        List<CommunityDataAccess.AccountWrapper> wrapperList = CommunityDataAccess.getAccounts(adfsGuid);
        if(wrapperList.size() > 0){
            for(CommunityDataAccess.AccountWrapper wrapper : wrapperList){
                accountList.add(new SelectOption(wrapper.Parent.Id, wrapper.Parent.Name));
                for(Account child : wrapper.children){
                    accountList.add(new SelectOption(child.Id, child.Name));
                }
            }
        }
    }
    
    private void fetchRoles(String adfsGuid){        
        accountRoles = CommunityDataAccess.getAccountRoles(adfsGuid);
    }
}