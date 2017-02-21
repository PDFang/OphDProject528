public class UserTriggerHandler extends TriggerHandler{

    // constants
    private static final String SAAS_IMPLEMENTATION_PARTNER = AccountPartnerTriggerHandler.SAAS_IMPLEMENTATION_PARTNER;
    private static final Set<String> psSaaSProjectSet = ProjectShareHelper.psSaaSProjectSet;
    private static final Set<String> psPremiseProjectSet = ProjectShareHelper.psPremiseProjectSet;

    public class UserTriggerHandlerException extends Exception{}
    
    public override void afterInsert()
    {
        addShare(trigger.new);
        assignPermissionSet(trigger.new);
    }

    public override void afterupdate()
    {
        addShare(trigger.new);
    }

    /* add share record whenever a partner portal user is enabled or partner portal user previously not active is activated */
    private static void addShare(List<User> userList){

        Map<Id, User> oldMap = (Map<Id, User>) trigger.oldMap;
        set<Id> userIdSet = new set<Id>();
        for(User newUser :userList){
            User oldUser = ( oldMap != null ) ? oldMap.get(newUser.Id) : null;
            if( newUser.IsPortalEnabled && newUser.AccountId != null && newUser.IsActive
					&& ( newUser.UserType == 'Partner' || newUser.UserType == 'PowerPartner')               		
                    && ( oldUser == null || oldUser.IsActive == false ) )
            {
                userIdSet.add(newUser.Id);
            }
        }
        system.debug(' **** addShare() : userIdSet - '+userIdSet);
        if(userIdSet.isEmpty())
        {
            return;
        }
        addShareFuture(userIdSet);

    } // end of addShare()

    @Future
    private static void addShareFuture(set<Id> userIdSet){
        // query user info
        List<User> partnerUserList = getPartnerUsers(userIdSet);
        system.debug(' **** addShareFuture() : partnerUserList - '+partnerUserList);
        if(partnerUserList.isEmpty())
        {
            return;
        }
        
        set<Id> partnerIdSet = new set<Id>();
        for(User partnerUser : partnerUserList){
            partnerIdSet.add(partnerUser.AccountId);
        }
        // query account partner info
        Map<Id, List<Account_Partner__c>> partnerMap = getAccountPartners(partnerIdSet);
		system.debug(' **** addShareFuture() : partnerMap - '+partnerMap);        
        if(partnerMap.isEmpty() == false)
        {
            addAccountShare(partnerUserList, partnerMap);
        }
        addProjectShare(partnerUserList, partnerMap);

    } // end of addShareFuture()

    /* Share customer account and related cases and opportunities with partner account portal users */
    private static void addAccountShare(List<User> partnerUserList, Map<Id, List<Account_Partner__c>> partnerMap)
    {

        List<AccountShare> shareList = new List<AccountShare>();
        for(User partnerUser :partnerUserList)
        {
            if( partnerMap.get(partnerUser.AccountId) == null ){
                continue;
            }
            List<Account_Partner__c> partnerList = partnerMap.get(partnerUser.AccountId);
            for(Account_Partner__c partner : partnerList){
                AccountShare share = new AccountShare(
                        AccountId = partner.Customer__c,
                        UserOrGroupId = partnerUser.Id,
                        AccountAccessLevel = 'Edit',
                        OpportunityAccessLevel = 'None',
                        CaseAccessLevel = 'Edit'
                );
                shareList.add(share);
            }

        }
        system.debug(' **** addAccountShare() : shareList - '+shareList);
        if(shareList.isEmpty() == false){
            Database.saveResult[] resultList=  Database.insert(shareList, false);
            for(Database.saveResult result : resultList){
                if(result.isSuccess() == false){
                    system.debug('**** addAccountShare() : error - '+ result.getErrors()[0]);
                    throw new UserTriggerHandlerException(result.getErrors()[0].getMessage());
                }
            }            
        }

    } // end of addAccountShare()

    // Share SaaS projects with SaaS partner portal users and Premise projects with implementation partner portal users
    private static void addProjectShare(List<User> partnerUserList, Map<Id, List<Account_Partner__c>> partnerMap){

        Set<Id> partnerIdSet = new Set<Id>();
        for( User partnerUser : partnerUserList ){
            partnerIdSet.add(partnerUser.AccountId);
        }
        system.debug(' **** addProjectShare() : partnerIdSet - '+partnerIdSet);

        Set<Id> customerIdSet = new Set<Id>();
        for( List<Account_Partner__c> partnerList : partnerMap.values() ){
            for( Account_Partner__c partner : partnerList ){
                if(partner.Partner_Type__c == SAAS_IMPLEMENTATION_PARTNER) {
                    customerIdSet.add(partner.Customer__c);
                }
            }
        }
        system.debug(' **** addProjectShare() : customerIdSet - '+customerIdSet);

        // Get PS SaaS projects
        Map<ID, List<Project__c>> accountProjectMap = new Map<ID, List<Project__c>>();
        if(customerIdSet.isEmpty() == false){
            for(Project__c project : [
                    Select Id, Account__c from Project__c
                    where Account__c IN :customerIdSet
                    and RecordType.Name IN :psSaaSProjectSet
            ]){
                List<Project__c> projectList = accountProjectMap.get(project.Account__c);
                if(projectList == null) {
                    projectList = new List<Project__c>();
                    accountProjectMap.put(project.Account__c, projectList);
                }
                projectList.add(project);
            }
        }
        // Get PS Premise projects
        Map<ID, List<Project__c>> impPartnerProjectMap = new Map<ID, List<Project__c>>();
        if(partnerIdSet.isEmpty() == false){
            for(Project__c project : [
                    Select Id, ImplementationPartner__c from Project__c
                    where ImplementationPartner__c IN :partnerIdSet
                    and RecordType.Name IN :psPremiseProjectSet
            ]){
                List<Project__c> projectList = impPartnerProjectMap.get(project.ImplementationPartner__c);
                if(projectList == null) {
                    projectList = new List<Project__c>();
                    impPartnerProjectMap.put(project.ImplementationPartner__c, projectList);
                }
                projectList.add(project);
            }
        }

        if(accountProjectMap.isEmpty() && impPartnerProjectMap.isEmpty()){
            return;
        }

        List<Project__Share> shareList = new List<Project__Share>();
        // user iteration
        for(User partnerUser :partnerUserList)
        {
            // Share PS Premise Projects with implementation partner users
            if( impPartnerProjectMap.containsKey(partnerUser.AccountId) ) {
                List<Project__c> projectList = impPartnerProjectMap.get(partnerUser.AccountId);
                system.debug(' **** addProjectShare() : Imp. Partner projectList - ' + projectList);
                // project iteration
                for (Project__c project : projectList) {
                    Project__Share share = new Project__Share(
                            ParentId = project.Id,
                            UserOrGroupId = partnerUser.Id,
                            AccessLevel = 'Edit'
                    );
                    shareList.add(share);
                }
            }
            // Share PS SaaS projects with account partners
            if( partnerMap.containsKey(partnerUser.AccountId) ) {
                List<Account_Partner__c> partnerList = partnerMap.get(partnerUser.AccountId);
                system.debug(' **** addProjectShare() : partnerList - ' + partnerList);
                // account partner iteration
                for (Account_Partner__c partner : partnerList) {
                    if (accountProjectMap.get(partner.Customer__c) == null || partner.Partner_Type__c != SAAS_IMPLEMENTATION_PARTNER) {
                        continue;
                    }
                    List<Project__c> projectList = accountProjectMap.get(partner.Customer__c);
                    system.debug(' **** addProjectShare() : customer projectList - ' + projectList);
                    // project iteration
                    for (Project__c project : projectList) {
                        Project__Share share = new Project__Share(
                                ParentId = project.Id,
                                UserOrGroupId = partnerUser.Id,
                                AccessLevel = 'Edit'
                        );
                        shareList.add(share);
                    } // end project iteration

                } // end account partner iteration
            }
        } // end user iteration

        system.debug(' **** addProjectShare() : shareList - '+shareList);
        if(shareList.isEmpty() == false){
            Database.saveResult[] resultList=  Database.insert(shareList, false);
            for(Database.saveResult result : resultList){
                if(result.isSuccess() == false){
                    system.debug('**** addProjectShare() : error - '+ result.getErrors()[0]);
                    throw new UserTriggerHandlerException(result.getErrors()[0].getMessage());
                }
            }
        }

    } // end of addProjectShare()

	/* assign permission set to partner users if any */
    private static void assignPermissionSet(List<User> userList){

        Map<Id, User> oldMap = (Map<Id, User>) trigger.oldMap;
        set<Id> userIdSet = new set<Id>();
        for(User newUser :userList){
            if( newUser.IsPortalEnabled && newUser.AccountId != null && newUser.IsActive
					&& ( newUser.UserType == 'Partner' || newUser.UserType == 'PowerPartner')               		
                    && oldMap == null )
            {
                userIdSet.add(newUser.Id);
            }
        }
        system.debug(' **** assignPermissionSet() : userIdSet - '+userIdSet);
        if(userIdSet.isEmpty())
        {
            return;
        }
        assignPermissionSetFuture(userIdSet);

    } // end of addShare()
    
    @Future
    private static void assignPermissionSetFuture(set<Id> userIdSet){
		
        List<User> partnerUserList = getPartnerUsers(userIdSet);
        system.debug(' **** assignPermissionSetFuture() : partnerUserList - '+partnerUserList);
        if(partnerUserList.isEmpty())
        {
            return;
        }

        set<Id> partnerIdSet = new set<Id>();
        for(User partnerUser : partnerUserList){
            if(partnerUser.Contact.Do_Not_Assign_Partner_Permission_Set__c == false)
                partnerIdSet.add(partnerUser.AccountId);
        }
        
        Map<Id, List<Account_Partner__c>> partnerMap = getAccountPartners(partnerIdSet);
		system.debug(' **** assignPermissionSetFuture() : partnerMap - '+partnerMap);        
        if(partnerMap.isEmpty())
        {
            return;
        }
        
        // Get permission set configured for each partner type
        Map<String, String> partnerPermissionMap = getMetaDataType();
        system.debug(' **** assignPermissionSetFuture() : partnerPermissionMap - '+partnerPermissionMap);
        if(partnerPermissionMap.isEmpty()){
            return;
        }
        
        // verify permission set exists
        Set<String> permissionSet = new Set<String>(partnerPermissionMap.values());
        Map<String, Id> permissionSetMap = getPermissionSet(permissionSet);
        system.debug(' **** assignPermissionSetFuture() : permissionSetMap - '+permissionSetMap);
        if(permissionSetMap.isEmpty()){
            return;
        }
        
        // get permission set assignees
        Map<Id, Set<Id>> assigneeMap = getAssignees(permissionSetMap.values());
        system.debug(' **** assignPermissionSetFuture() : assigneeMap - '+assigneeMap);
        
        // assign permission sets
        List<PermissionSetAssignment> psaList = new List<PermissionSetAssignment>();
        
        for(User partnerUser :partnerUserList){
            if(partnerUser.Contact.Do_Not_Assign_Partner_Permission_Set__c){
                system.debug(' **** assignPermissionSetFuture() : Contact has Do Not Assign Flag checked - '+ partnerUser);
                continue;
            }
            List<Account_Partner__c> partnerList = partnerMap.get(partnerUser.AccountId);
            if(partnerList == null){
                continue;
            }
            for(Account_Partner__c partner :partnerList){
                String permissionSetName = partnerPermissionMap.get(partner.Partner_Type__c);
                system.debug(' **** assignPermissionSetFuture() : permissionSetName - '+permissionSetName);
                if(permissionSetName == null || !permissionSetMap.containsKey(permissionSetName) ){
                    continue;
                }
            	Set<Id> assigneeIdSet = assigneeMap.get(permissionSetMap.get(permissionSetName));
                if(assigneeIdSet == null){
                    assigneeIdSet = new Set<Id>();
                    assigneeMap.put(permissionSetMap.get(permissionSetName), assigneeIdSet);
                }
                if(assigneeIdSet.contains(partnerUser.Id) ){
                    system.debug(' **** assignPermissionSetFuture() : Permission set already assigned to -'+ partnerUser.Id);
                    continue;
                }
                assigneeIdSet.add(partnerUser.Id);
                psaList.add(new PermissionSetAssignment(
                    PermissionSetId = permissionSetMap.get(permissionSetName),
                    AssigneeId = partnerUser.Id
                ));
            }            
        }
        system.debug(' **** assignPermissionSetFuture() : psaList - '+psaList);
        // save to database
        if(psaList.isEmpty() == false){
            Database.saveResult[] resultList=  Database.insert(psaList, false);
            for(Database.saveResult result : resultList){
                if(result.isSuccess() == false){
                    system.debug('**** assignPermissionSetFuture() : error - '+ result.getErrors()[0]);
                    throw new UserTriggerHandlerException(result.getErrors()[0].getMessage());
                }
            }            
        }
        
    } // end of assignPermissionSetFuture()
    
    private static List<User> getPartnerUsers(set<Id> userIdSet){
        
    	List<User> partnerUserList = new List<User>();
		if(userIdSet.size() > 0){
            for(User partnerUser : [
                    Select Id, ContactId, Contact.Do_Not_Assign_Partner_Permission_Set__c, AccountId from User
                    where IsActive = true and IsPortalEnabled = true
                	and UserType IN ('Partner', 'PowerPartner')
                    and Id IN :userIdSet and AccountId != null
            ]){
                partnerUserList.add(partnerUser);
            }
        }
        return partnerUserList;
        
    } // end of getPartnerUsers()
    
    private static Map<Id, List<Account_Partner__c>> getAccountPartners(set<Id> partnerIdSet){
        
    	Map<Id, List<Account_Partner__c>> partnerMap = new Map<Id, List<Account_Partner__c>>();
        if(partnerIdSet.size() > 0){
            for(Account_Partner__c partner : [
                    Select Id, Partner__c, Customer__c, Partner_Type__c from Account_Partner__c
                    where Partner__c != null and Partner__c IN :partnerIdSet
            ])
            {
                List<Account_Partner__c> partnerList = partnerMap.get(partner.Partner__c);
                if (partnerList == null) {
                    partnerList = new List<Account_Partner__c>();
                    partnerMap.put(partner.Partner__c, partnerList);
                }
                partnerList.add(partner);
            }
        }         
        return partnerMap;
        
    } // end of getAccountPartners()  
    
    // get Partner Permission Set custom settings
    private static Map<String, String> getMetaDataType(){        
    	Map<String, String> partnerPermissionMap = new Map<String, String>();
        for(Partner_Permission_Sets__c mdt : [
            Select Permission_Set__c, Partner_Type__c from Partner_Permission_Sets__c
        ])
        {
            partnerPermissionMap.put(mdt.Partner_Type__c, mdt.Permission_Set__c);
        }
        return partnerPermissionMap;
	}
    
    // get permission set info
    private static Map<String, String> getPermissionSet(Set<String> permissionSet){
    	Map<String, Id> permissionSetMap = new Map<String, Id>();
        if(permissionSet.size() > 0){
            for(PermissionSet ps: [Select Id, Name from PermissionSet where Name in :permissionSet ]){
                permissionSetMap.put(ps.Name, ps.Id);
            }
        }            
        return permissionSetMap;
    }

	// get permission set assignee info
    private static Map<Id, Set<Id>> getAssignees(List<Id> permissionSetIdList){
    	Map<Id, Set<Id>> assigneeMap = new Map<Id, Set<Id>>();
        if(permissionSetIdList.size() > 0){
            for(PermissionSetAssignment psa :[
                Select PermissionSetId, AssigneeId from PermissionSetAssignment where PermissionSetId IN :permissionSetIdList
            ]){
                Set<Id> assigneeIdSet = assigneeMap.get(psa.PermissionSetId);
                if(assigneeIdSet == null){
                    assigneeIdSet = new Set<Id>();
                    assigneeMap.put(psa.PermissionSetId, assigneeIdSet);
                }
                assigneeIdSet.add(psa.AssigneeId);
            }
        }
		return assigneeMap;
        
    } // end of getAssignees()

}