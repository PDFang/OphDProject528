public class AccountPartnerTriggerHandler extends TriggerHandler{

    private static Map<Id, List<User>> accountUserMap = null; // key partner account ID
    private static Map<Id, User> partnerUserMap = null; // key user ID
	
    public class AccountPartnerTriggerHandlerException extends Exception{}
    
    public override void beforeInsert()
    {
        updatePublicGroupId(trigger.new);
    }

    public override void afterInsert()
    {
        addAccountShare(trigger.new);
        addProjectShare(trigger.new);
        assignPermissionSet(trigger.new);
    }

    public override void afterDelete()
    {
        deleteAccountShare(trigger.old);
        deleteProjectShare(trigger.old);
        unassignPermissionSet(trigger.old);
    }

    /*  update public group ID */
    private void updatePublicGroupId(List<Account_Partner__c> partnerList){
        if(partnerList == null || partnerList.isEmpty())
        {
            return;
        }
        List<Account_Partner__c> newList = new List<Account_Partner__c>();
        set<String> groupNameSet = new set<String>();
        for(Account_Partner__c partner :partnerList){
            if( String.isBlank(partner.Public_Group__c) ){
                continue;
            }
            newList.add(partner);
            groupNameSet.add(partner.Public_Group__c);
        }
		system.debug(' **** updatePublicGroupId() : groupNameSet - '+groupNameSet);
        if(groupNameSet.isEmpty()){
            return;
        }

        Map<String, Group> groupMap = new Map<String, Group>();
        for(Group publicGroup :[Select Id, Name from Group where Name IN :groupNameSet]){
            groupMap.put(publicGroup.Name, publicGroup);
        }
		system.debug(' **** updatePublicGroupId() : groupMap - '+groupMap);
        
        for(Account_Partner__c partner :newList){
            if(groupMap.containsKey(partner.Public_Group__c)){
                partner.PublicGroupId__c = groupMap.get(partner.Public_Group__c).Id;
            } else{
                partner.Public_Group__c.addError('Not a valid Public Group.');
            }
        }
    } // end of updatePublicGroupId();


    /* Share customer account and related cases and opportunities with partner account portal users */
    private static void addAccountShare(List<Account_Partner__c> partnerList)
    {
        if(partnerList == null || partnerList.isEmpty())
        {
            return;
        }
        system.debug(' **** addAccountShare() : partnerList size - '+partnerList.size());
        List<Account_Partner__c> newList = new List<Account_Partner__c>();
        set<Id> partnerIdSet = new set<Id>();
        set<Id> groupIdSet = new set<Id>();
        for(Account_Partner__c partner :partnerList)
        {
            if( ( partner.Partner__c == null && partner.PublicGroupId__c == null ) || partner.Customer__c == null )
            {
                continue;
            }
            if( partner.Partner__c != null ) {
                partnerIdSet.add(partner.Partner__c);
            }
            else if( partner.PublicGroupId__c != null ){
                groupIdSet.add(partner.PublicGroupId__c);
            }
            newList.add(partner);
        }

        if(newList.isEmpty())
        {
            return;
        }
        system.debug(' **** addAccountShare() : newList size - '+newList.size());

        Map<ID, List<User>> lAccountUserMap = getAccountUserMap(partnerIdSet);
        if(groupIdSet.isEmpty() && ( lAccountUserMap == null || lAccountUserMap.isEmpty() )){
            return;
        }

        List<AccountShare> shareList = new List<AccountShare>();
        for(Account_Partner__c partner :newList)
        {
            if(partner.PublicGroupId__c != null)
            {
                AccountShare share = new AccountShare(
                        AccountId = partner.Customer__c,
                        UserOrGroupId = partner.PublicGroupId__c,
                        AccountAccessLevel = 'Edit',
                        OpportunityAccessLevel = 'Edit',
                        CaseAccessLevel = 'Edit'
                );
                shareList.add(share);
            }
            else if( partner.Partner__c != null && lAccountUserMap.get(partner.Partner__c) != null )
            {
                List<User> userList = lAccountUserMap.get(partner.Partner__c);
                for (User u : userList) {
                    AccountShare share = new AccountShare(
                            AccountId = partner.Customer__c,
                            UserOrGroupId = u.Id,
                            AccountAccessLevel = 'Edit',
                            OpportunityAccessLevel = 'Edit',
                            CaseAccessLevel = 'Edit'
                    );
                    shareList.add(share);
                }
            }
        }

        system.debug(' **** addAccountShare() : shareList - '+shareList);
        if(shareList.isEmpty() == false){
            Database.saveResult[] resultList=  Database.insert(shareList, false);
            for(Database.saveResult result : resultList){
                if(result.isSuccess() == false){
                    system.debug('**** addAccountShare() : error - '+ result.getErrors()[0]);
                    throw new AccountPartnerTriggerHandlerException(result.getErrors()[0].getMessage());
                }
            }            
        }

    } // end of addAccountShare()

    /* Share customer projects with partner account portal users */
    private static void addProjectShare(List<Account_Partner__c> partnerList)
    {
        if(partnerList == null || partnerList.isEmpty())
        {
            return;
        }
        system.debug(' **** addProjectShare() : partnerList size - '+partnerList.size());
        List<Account_Partner__c> newList = new List<Account_Partner__c>();
        set<Id> partnerIdSet = new set<Id>();
        Set<Id> customerIdSet = new set<Id>();
        set<Id> groupIdSet = new set<Id>();
        for(Account_Partner__c partner :partnerList)
        {
            if( ( partner.Partner__c == null && partner.PublicGroupId__c == null ) || partner.Customer__c == null)
            {
                continue;
            }
            if( partner.Partner__c != null ) {
                partnerIdSet.add(partner.Partner__c);
            }
            else if( partner.PublicGroupId__c != null ){
                groupIdSet.add(partner.PublicGroupId__c);
            }
            customerIdSet.add(partner.Customer__c);
            newList.add(partner);
        }

        if(newList.isEmpty())
        {
            return;
        }
        system.debug(' **** addProjectShare() : newList size - '+newList.size());

        Map<ID, List<Project__c>> accountProjectMap = new Map<ID, List<Project__c>>();
        for(Project__c project : [Select Id, Account__c from Project__c where Account__c IN :customerIdSet]){
            List<Project__c> projectList = accountProjectMap.get(project.Account__c);
            if(projectList == null) {
                projectList = new List<Project__c>();
                accountProjectMap.put(project.Account__c, projectList);
            }
            projectList.add(project);
        }

        if(accountProjectMap.isEmpty()){
            return;
        }

        Map<ID, List<User>> lAccountUserMap = getAccountUserMap(partnerIdSet);
        if(groupIdSet.isEmpty() && ( lAccountUserMap == null || lAccountUserMap.isEmpty() ) ){
            return;
        }

        List<Project__Share> shareList = new List<Project__Share>();
        for(Account_Partner__c partner :newList)
        {
            if( partner.Customer__c == null || accountProjectMap.get(partner.Customer__c) == null ){
                continue;
            }
            List<Project__c> projectList = accountProjectMap.get(partner.Customer__c);

            if(partner.PublicGroupId__c != null)
            {
                for(Project__c project : projectList) {
                    Project__Share share = new Project__Share(
                            ParentId = project.Id,
                            UserOrGroupId = partner.PublicGroupId__c,
                            AccessLevel  = 'Edit'
                    );
                    shareList.add(share);
                }
            }
            if( partner.Partner__c == null || lAccountUserMap.get(partner.Partner__c) == null ){
                continue;
            }
            List<User> userList = lAccountUserMap.get(partner.Partner__c);

            for(User u : userList) {
                for(Project__c project : projectList) {
                    Project__Share share = new Project__Share(
                            ParentId = project.Id,
                            UserOrGroupId = u.Id,
                            AccessLevel  = 'Edit'
                    );
                    shareList.add(share);
                }
            }

        }
        system.debug(' **** addProjectShare() : shareList - '+shareList);
        if(shareList.isEmpty() == false){
            Database.saveResult[] resultList=  Database.insert(shareList, false);
            for(Database.saveResult result : resultList){
                if(result.isSuccess() == false){
                    system.debug('**** addProjectShare() : error - '+ result.getErrors()[0]);
                    throw new AccountPartnerTriggerHandlerException(result.getErrors()[0].getMessage());
                }
            }            
        }

    } // end of addProjectShare()

    /* Revoke partner account portal users access to customer account and their related cases and opportunities */
    private static void deleteAccountShare(List<Account_Partner__c> partnerList)
    {
        if(partnerList == null || partnerList.isEmpty())
        {
            return;
        }
        system.debug(' **** deleteAccountShare() : partnerList.size() - '+partnerList);
        Map<Id, Set<Id>> customerPartnerGroupMap = new Map<Id, Set<Id>>();
        Set<Id> partnerIdSet = new set<Id>();
        set<Id> groupIdSet = new set<Id>();
        for(Account_Partner__c partner :partnerList)
        {
            if(partner.Partner__c == null && partner.PublicGroupId__c == null)
            {
                continue;
            }
            Set<Id> partnerSet = customerPartnerGroupMap.get(partner.Customer__c);
            if (partnerSet == null) {
                partnerSet = new Set<Id>();
                customerPartnerGroupMap.put(partner.Customer__c, partnerSet);
            }
            if(partner.PublicGroupId__c != null)
            {
                partnerSet.add(partner.PublicGroupId__c);
                groupIdSet.add(partner.PublicGroupId__c);
            }
            else if(partner.Partner__c != null) {
                partnerSet.add(partner.Partner__c);
                partnerIdSet.add(partner.Partner__c);
            }
        }

        if(customerPartnerGroupMap.isEmpty())
        {
            return;
        }
        Set<Id> customerIdSet = new set<Id>(customerPartnerGroupMap.keySet());
        system.debug(' **** deleteAccountShare() : customerIdSet - '+customerIdSet);

        Map<Id, User> lPartnerUserMap = getPartnerUserMap(partnerIdSet);
        if(groupIdSet.isEmpty() && ( lPartnerUserMap == null || lPartnerUserMap.isEmpty() ) ){
            return;
        }
        set<Id> UserOrGroupIdSet = new set<Id>();
        UserOrGroupIdSet.addAll(groupIdSet); // Group ID's
        UserOrGroupIdSet.addAll(lPartnerUserMap.keySet()); // User ID's

        List<AccountShare> shareList = new List<AccountShare>();
        for(AccountShare share : [Select Id, AccountId, UserOrGroupId from AccountShare
                                    where RowCause = 'Manual' and AccountId IN :customerIdSet
                                    and UserOrGroupId IN :UserOrGroupIdSet])
        {
            Set<Id> partnerGroupSet = customerPartnerGroupMap.get(share.AccountId);
            if(partnerGroupSet == null || partnerGroupSet.isEmpty()){
                continue;
            }
            if( String.valueOf(share.UserOrGroupId).startsWith('005') ){
                User partnerUser = lPartnerUserMap.get(share.UserOrGroupId);
                if( partnerUser != null && partnerGroupSet.contains(partnerUser.AccountId) ){
                    shareList.add(share);
                }
            }
            else if( partnerGroupSet.contains(share.UserOrGroupId) ) {
                shareList.add(share);
            }

        }
        system.debug(' **** deleteAccountShare() : shareList - '+shareList);
        if(shareList.isEmpty() == false){
            Database.DeleteResult[] resultList=  Database.delete(shareList, false);
            for(Database.DeleteResult result : resultList){
                if(result.isSuccess() == false){
					system.debug('**** deleteAccountShare() : id - '+ result.getId());
                    system.debug('**** deleteAccountShare() : error - '+ result.getErrors()[0]);
                    throw new AccountPartnerTriggerHandlerException(result.getErrors()[0].getMessage());
                }
            }            
        }

    } // deleteAccountShare()

    /* Revoke partner account portal users access to customer projects */
    private static void deleteProjectShare(List<Account_Partner__c> partnerList)
    {
        if(partnerList == null || partnerList.isEmpty())
        {
            return;
        }
        system.debug(' **** deleteProjectShare() : partnerList.size() - '+partnerList);
        Map<Id, Set<Id>> customerPartnerGroupMap = new Map<Id, Set<Id>>();
        Set<Id> partnerIdSet = new set<Id>();
        set<Id> groupIdSet = new set<Id>();
        for(Account_Partner__c partner :partnerList)
        {
            if(partner.Partner__c == null && partner.PublicGroupId__c == null)
            {
                continue;
            }
            Set<Id> partnerSet = customerPartnerGroupMap.get(partner.Customer__c);
            if (partnerSet == null) {
                partnerSet = new Set<Id>();
                customerPartnerGroupMap.put(partner.Customer__c, partnerSet);
            }
            if(partner.PublicGroupId__c != null)
            {
                partnerSet.add(partner.PublicGroupId__c);
                groupIdSet.add(partner.PublicGroupId__c);
            }
            else if(partner.Partner__c != null) {
                partnerSet.add(partner.Partner__c);
                partnerIdSet.add(partner.Partner__c);
            }
        }

        if(customerPartnerGroupMap.isEmpty())
        {
            return;
        }

        Set<Id> customerIdSet = new set<Id>(customerPartnerGroupMap.keySet());
        system.debug(' **** deleteProjectShare() : customerIdSet - '+customerIdSet);

        Map<Id, Project__c> projectMap = new Map<Id, Project__c>([
                Select Id, Account__c from Project__c where Account__c IN :customerIdSet
        ]);
        if(projectMap.isEmpty()){
            return;
        }
        system.debug(' **** deleteProjectShare() : projectMap - '+projectMap);

        Map<Id, User> lPartnerUserMap = getPartnerUserMap(partnerIdSet);
        if(groupIdSet.isEmpty() && (lPartnerUserMap == null || lPartnerUserMap.isEmpty()) ){
            return;
        }
        set<Id> UserOrGroupIdSet = new set<Id>();
        UserOrGroupIdSet.addAll(groupIdSet); // Group ID's
        UserOrGroupIdSet.addAll(lPartnerUserMap.keySet()); // User ID's

        List<Project__Share> shareList = new List<Project__Share>();
        for(Project__Share share : [Select Id, ParentId, UserOrGroupId from Project__Share
                                    where RowCause = 'Manual' and ParentId IN :projectMap.keyset()
                                    and UserOrGroupId IN :UserOrGroupIdSet])
        {
            Set<Id> partnerGroupSet = customerPartnerGroupMap.get(projectMap.get(share.ParentId).Account__c);
            if(partnerGroupSet == null || partnerGroupSet.isEmpty()){
                continue;
            }
            if( String.valueOf(share.UserOrGroupId).startsWith('005') ){
                User partnerUser = lPartnerUserMap.get(share.UserOrGroupId);
                if( partnerUser != null && partnerGroupSet.contains(partnerUser.AccountId) ){
                    shareList.add(share);
                }
            }
            else if( partnerGroupSet.contains(share.UserOrGroupId) ) {
                shareList.add(share);
            }
        }

        system.debug(' **** deleteProjectShare() : shareList - '+shareList);
        if(shareList.isEmpty() == false){
            Database.DeleteResult[] resultList=  Database.delete(shareList, false);
            for(Database.DeleteResult result : resultList){
                if(result.isSuccess() == false){
					system.debug('**** deleteAccountShare() : id - '+ result.getId());
                    system.debug('**** deleteAccountShare() : error - '+ result.getErrors()[0]);
                    throw new AccountPartnerTriggerHandlerException(result.getErrors()[0].getMessage());
                }
            }            
        }

    } // deleteAccountShare()
	
    /* Assign permission set to partner users based on partner type */
    private static void assignPermissionSet(List<Account_Partner__c> partnerList){
		if(partnerList == null || partnerList.isEmpty())
        {
            return;
        }
        Set<Id> recordIdSet = new set<Id>();
        for(Account_Partner__c partner :partnerList)
        {
            if( (partner.Partner__c == null && partner.PublicGroupId__c == null ) || string.isBlank(partner.Partner_Type__c) )
            {
                continue;
            }
            recordIdSet.add(partner.Id);
        }
        system.debug(' **** assignPermissionSet() : recordIdSet - '+recordIdSet);
        
        if(recordIdSet.size() > 0){
            assignPermissionSetFuture(recordIdSet);
        }
        
    } // end of assignPermissionSet();
    
    /* Assign permission set to partner users based on partner type */
    @Future
    private static void assignPermissionSetFuture(Set<Id> recordIdSet){
        
        Set<Id> partnerIdSet = new set<Id>();
        set<Id> groupIdSet = new set<Id>();
        set<String> partnerTypeSet = new set<String>();
        List<Account_Partner__c> processList = new List<Account_Partner__c>();
        for(Account_Partner__c partner : [
            Select Partner__c, PublicGroupId__c, Partner_Type__c from Account_Partner__c where Id IN :recordIdSet
        ])
        {
            if( (partner.Partner__c == null && partner.PublicGroupId__c == null ) || string.isBlank(partner.Partner_Type__c) )
            {
                continue;
            }
            processList.add(partner);
            partnerTypeSet.add(partner.Partner_Type__c);
            if(partner.PublicGroupId__c != null)
            {
                groupIdSet.add(partner.PublicGroupId__c);
            }
            else if(partner.Partner__c != null) 
            {
                partnerIdSet.add(partner.Partner__c);
            }
        }        
        system.debug(' **** assignPermissionSetFuture() : processList.size() - '+processList);        
        if(processList.isEmpty()){
            return;            
        }               
        
        // Get permission set configured for each partner type
        Map<String, String> partnerPermissionMap = getMetaDataType(partnerTypeSet);
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
        // get partner users
        Map<ID, List<User>> lAccountUserMap = getAccountUserMap(partnerIdSet);        
        Map<ID, List<GroupMember>> groupMemberMap = getGroupMembers(groupIdSet);
        system.debug(' **** assignPermissionSetFuture() : groupMemberMap - '+groupMemberMap);        
        if(lAccountUserMap.isEmpty() && groupMemberMap.isEmpty()){
            return;
        }
        // get permission set assignees
        Map<Id, Map<Id, PermissionSetAssignment>> permissionAssigneeMap = getPermissionAssignees(permissionSetMap.values());
        
        // assign permission sets
        List<PermissionSetAssignment> psaList = new List<PermissionSetAssignment>();
        for(Account_Partner__c partner :processList){
            String permissionSetName = partnerPermissionMap.get(partner.Partner_Type__c);
            system.debug(' **** assignPermissionSetFuture() : permissionSetName - '+permissionSetName);
            if(permissionSetName == null || !permissionSetMap.containsKey(permissionSetName) ){
                continue;
            }
            Map<Id, PermissionSetAssignment> assigneeMap = permissionAssigneeMap.get(permissionSetMap.get(permissionSetName));
            // assign permission set to public group members
            if(partner.PublicGroupId__c != null)
            {
                List<GroupMember> memberList = groupMemberMap.get(partner.PublicGroupId__c);
                system.debug(' **** assignPermissionSetFuture() : memberList - '+memberList);
                if(memberList == null){
                    continue;
                }
                for(GroupMember member : memberList){
                    if( (assigneeMap != null && assigneeMap.containsKey(member.UserOrGroupId)) || string.valueOf(member.UserOrGroupId).startsWith('00G') ){
                        continue;
                    }
                    psaList.add(new PermissionSetAssignment(
                    	PermissionSetId = permissionSetMap.get(permissionSetName),
                        AssigneeId = member.UserOrGroupId
                    ));
                    
                }                
            }
            // assign permission set to partner users
            else if(partner.Partner__c != null) 
            {
                List<User> userList = lAccountUserMap.get(partner.Partner__c);
                system.debug(' **** assignPermissionSetFuture() : userList - '+userList);
                if(userList == null){
                    continue;
                }
                for(User usr : userList){
                    if(assigneeMap != null && assigneeMap.containsKey(usr.Id) ){
                        system.debug(' **** assignPermissionSetFuture() : Permission set already assigned to -'+ usr.Id);
                        continue;
                    }
                    psaList.add(new PermissionSetAssignment(
                    	PermissionSetId = permissionSetMap.get(permissionSetName),
                        AssigneeId = usr.Id
                    ));
                    
                } 
            }            
        }
        system.debug(' **** assignPermissionSetFuture() : psaList - '+psaList);
        // save to database
        if(psaList.isEmpty() == false){
            Database.saveResult[] resultList=  Database.insert(psaList, false);
            for(Database.saveResult result : resultList){
                if(result.isSuccess() == false){
                    system.debug('**** assignPermissionSetFuture() : error - '+ result.getErrors()[0]);
                    throw new AccountPartnerTriggerHandlerException(result.getErrors()[0].getMessage());
                }
            }            
        }        

    } // end of assignPermissionSetFuture()
    
    /* Unassign permission set assigned to partner users whenever account partner record is deleted */
    private static void unassignPermissionSet(List<Account_Partner__c> partnerList){
        
		if(partnerList == null || partnerList.isEmpty())
        {
            return;
        }       
        
        Set<Id> accountIdSet = new set<Id>();
        set<Id> groupIdSet = new set<Id>();
        set<Id> recordIdSet = new set<Id>();
        Map<String, Map<Id, List<Account_Partner__c>>> typePartnerMap = new Map<String, Map<Id, List<Account_Partner__c>>>();
        
        for(Account_Partner__c partner : partnerList)
        {
            if( (partner.Partner__c == null && partner.PublicGroupId__c == null ) || string.isBlank(partner.Partner_Type__c) )
            {
                continue;
            }
            recordIdSet.add(partner.Id);
            if(partner.PublicGroupId__c != null)
            {
                groupIdSet.add(partner.PublicGroupId__c);
            }
            else if(partner.Partner__c != null) 
            {
                accountIdSet.add(partner.Partner__c);
            }
            
            Map<Id, List<Account_Partner__c>> innerMap = typePartnerMap.get(partner.Partner_Type__c);
            if(innerMap == null){
                innerMap = new Map<Id, List<Account_Partner__c>>();
                typePartnerMap.put(partner.Partner_Type__c, innerMap);
            }
            Id keyId = (partner.Partner__c != null) ? partner.Partner__c : partner.PublicGroupId__c;
            List<Account_Partner__c> apList = innerMap.get(keyId);
            if(apList == null){
                apList = new List<Account_Partner__c>();
                innerMap.put(keyId, apList);
            }
            apList.add(partner);
            
        }        
                       
        if(recordIdSet.isEmpty()){
            return;
        }
		
		// find other records where these partners or public groups are assigned as partners       
        for(Account_Partner__c partner : [
            Select Partner__c, PublicGroupId__c, Partner_Type__c from Account_Partner__c where Id NOT IN :recordIdSet and
            (Partner__c IN :accountIdSet or PublicGroupId__c IN :groupIdSet)
        ]){
            Id keyId = (partner.Partner__c != null) ? partner.Partner__c : partner.PublicGroupId__c;
    		Map<Id, List<Account_Partner__c>> innerMap = typePartnerMap.get(partner.Partner_Type__c);
            if(innerMap == null || !innerMap.containsKey(keyId)){
                continue;
            }
            innerMap.remove(keyId);
		}
               
        // Get permission set configured for each partner type
        Map<String, String> partnerPermissionMap = getMetaDataType(typePartnerMap.keySet());
        system.debug(' **** unassignPermissionSet() : partnerPermissionMap - '+partnerPermissionMap);
        if(partnerPermissionMap.isEmpty()){
            return;
        }                  
        
        // verify permission set exists
        Set<String> permissionSet = new Set<String>(partnerPermissionMap.values());
        Map<String, Id> permissionSetMap = getPermissionSet(permissionSet);
        system.debug(' **** unassignPermissionSet() : permissionSetMap - '+permissionSetMap);
        if(permissionSetMap.isEmpty()){
            return;
        }
                
        // verify each partner type has a permission set configured and the permission set really exists
        for(String  partnerType :typePartnerMap.keySet()){
            String permissionSetName = partnerPermissionMap.get(partnerType);
            if(permissionSetName == null || permissionSetMap.containsKey(permissionSetName) == false){
                typePartnerMap.remove(partnerType);
            }
        } 
        
        // filter accounts and public groups whose permission set assignments are to be removed 
        accountIdSet = new set<Id>();
        groupIdSet = new set<Id>();
        for(String  partnerType :typePartnerMap.keySet()){
			Map<Id, List<Account_Partner__c>> innerMap = typePartnerMap.get(partnerType);
            for(Id keyId : innerMap.keySet()){
                if(String.valueOf(keyId).startsWith('001')){
                    accountIdSet.add(keyId);
                } else if(String.valueOf(keyId).startsWith('00G')){
                    groupIdSet.add(keyId);
                }
            }            
        }
        
        if(accountIdSet.isEmpty() && groupIdSet.isEmpty()){
            return;
        }
        
        // get partner users
        Map<ID, List<User>> lAccountUserMap = getAccountUserMap(accountIdSet);
		// get group members        
        Map<ID, List<GroupMember>> groupMemberMap = getGroupMembers(groupIdSet);
        system.debug(' **** unassignPermissionSet() : groupMemberMap - '+groupMemberMap);        
        if(lAccountUserMap.isEmpty() && groupMemberMap.isEmpty()){
            return;
        }
        
        // get permission set assignees
        Map<Id, Map<Id, PermissionSetAssignment>> assigneeMap = getPermissionAssignees(permissionSetMap.values());
        
        Set<Id> psaIdSet = new Set<Id>();
        system.debug(' **** unassignPermissionSet() : Partner types - '+typePartnerMap.keySet());
        
        // unassign permission sets        
        for(String  partnerType :typePartnerMap.keySet()){
            Map<Id, List<Account_Partner__c>> partnerGroupMap = typePartnerMap.get(partnerType);
            if(partnerGroupMap.isEmpty()){
                continue;
            }
            String permissionSetName = partnerPermissionMap.get(partnerType);
            system.debug(' **** unassignPermissionSet() : permissionSetName - '+permissionSetName);
            if(permissionSetName == null || !permissionSetMap.containsKey(permissionSetName) ){
                continue;
            }
            Map<Id, PermissionSetAssignment> psaMap = assigneeMap.get(permissionSetMap.get(permissionSetName));
            if(psaMap == null || psaMap.isEmpty()){
                continue;
            }
            system.debug(' **** unassignPermissionSet() : Account / Group ID\'s - '+partnerGroupMap.keySet());
            
            for(Id keyId : partnerGroupMap.keySet()){
                if(String.valueOf(keyId).startsWith('001')){
                    List<User> userList = lAccountUserMap.get(keyId);
                    system.debug(' **** unassignPermissionSet() : userList - '+userList);
                    if(userList == null){
                        continue;
                    }
                    for(User usr : userList){
                        if(psaMap.containsKey(usr.Id)){
                            psaIdSet.add(psaMap.get(usr.Id).Id);
                        }
                        
                    } 
                } else if(String.valueOf(keyId).startsWith('00G')){
                    List<GroupMember> memberList = groupMemberMap.get(keyId);
                    system.debug(' **** unassignPermissionSet() : memberList - '+memberList);
                    if(memberList == null){
                        continue;
                    }
                    for(GroupMember member : memberList){
                        if(psaMap.containsKey(member.UserOrGroupId)){
                            psaIdSet.add(psaMap.get(member.UserOrGroupId).Id);
                        }                        
                    }
                }
            }
		} // end iteration
        
        // delete from database
        if(psaIdSet.size() > 0){
            unassignPermissionSetFuture(psaIdSet);
        }

    } // end of unassignPermissionSet()
    
    @Future
    private static void unassignPermissionSetFuture(Set<Id> psaIdSet){
        
        List<Sobject> psaList = new List<Sobject>();
        for(Id psaId : psaIdSet){
            Sobject psa = new PermissionSetAssignment();
            psa.put('Id', psaId);
            psaList.add(psa);
        }
        system.debug(' **** unassignPermissionSetFuture() : psaList - '+psaList);

        Database.DeleteResult[] resultList=  Database.delete(psaList, false);
        for(Database.DeleteResult result : resultList){
            if(result.isSuccess() == false){
                system.debug('**** unassignPermissionSetFuture() : id - '+ result.getId());
                system.debug('**** unassignPermissionSetFuture() : error - '+ result.getErrors()[0]);
                throw new AccountPartnerTriggerHandlerException(result.getErrors()[0].getMessage());
            }
        }                
        
    } // end of unassignPermissionSetFuture()
    
    // get Partner Permission Set custom metadata type
    private static Map<String, String> getMetaDataType(Set<String> partnerTypeSet){        
    	Map<String, String> partnerPermissionMap = new Map<String, String>();
        for(Partner_Permission_Set__mdt mdt : [
            Select Permission_Set__c, Partner_Type__c from Partner_Permission_Set__mdt where Partner_Type__c IN :partnerTypeSet
        ])
        {
            partnerPermissionMap.put(mdt.Partner_Type__c, mdt.Permission_Set__c);
        }
        return partnerPermissionMap;
	}
    
    // get permission set info
    private static Map<String, String> getPermissionSet(Set<String> permissionSet){
    	Map<String, Id> permissionSetMap = new Map<String, Id>();
        for(PermissionSet ps: [Select Id, Name from PermissionSet where Name in :permissionSet ]){
            permissionSetMap.put(ps.Name, ps.Id);
        }
        return permissionSetMap;
    }
	
    // get public group members
    private static Map<ID, List<GroupMember>> getGroupMembers(Set<Id> groupIdSet){
    	Map<ID, List<GroupMember>> groupMemberMap = new Map<ID, List<GroupMember>>();
        if(groupIdSet.isEmpty() == false){
            for(GroupMember member : [
                Select Id, GroupId, UserOrGroupId from GroupMember where GroupId IN :groupIdSet 
            ])
            {
                List<GroupMember> memberList = groupMemberMap.get(member.GroupId);
                if(memberList == null){
                    memberList = new List<GroupMember>();
                    groupMemberMap.put(member.GroupId, memberList);
                }
                memberList.add(member);
            }
        }
        return groupMemberMap;
    }    
    
    // get permission set assignee info
    private static Map<Id, Map<Id, PermissionSetAssignment>> getPermissionAssignees(List<Id> permissionSetIdList){
    	Map<Id, Map<Id, PermissionSetAssignment>> assigneeMap = new Map<Id, Map<Id, PermissionSetAssignment>>();
        for(PermissionSetAssignment psa :[
            Select PermissionSetId, AssigneeId from PermissionSetAssignment where PermissionSetId IN :permissionSetIdList
        ]){
            Map<Id, PermissionSetAssignment> innermap = assigneeMap.get(psa.PermissionSetId);
            if(innermap == null){
                innermap = new Map<Id, PermissionSetAssignment>();
                assigneeMap.put(psa.PermissionSetId, innermap);
            }
            innermap.put(psa.AssigneeId, psa);
        }
        return assigneeMap;
    }
    
    /* cache partner portal user info **/
    private static void findPartnerUsers(Set<Id> partnerIdSet)
    {
        system.debug(' **** findPartnerUsers() : partnerIdSet - '+partnerIdSet);
        accountUserMap = new Map<ID, List<User>>();
        partnerUserMap = new Map<Id, User>();
        if(partnerIdSet.isEmpty()){
            return;
        }
        Set<Id> newPartnerIds = new Set<Id>();
        newPartnerIds.addAll(partnerIdSet);
        newPartnerIds.addAll(accountUserMap.keyset());

        for (User partnerUser : [
                Select Id, ContactId, AccountId
                from User
                where IsPortalEnabled = true and IsActive = true
                and AccountId IN :newPartnerIds
            	and UserType IN ('Partner', 'PowerPartner')
        ]) {
            List<User> userList = accountUserMap.get(partnerUser.AccountId);
            if (userList == null) {
                userList = new List<User>();
                accountUserMap.put(partnerUser.AccountId, userList);
            }
            userList.add(partnerUser);
            partnerUserMap.put(partnerUser.Id, partnerUser);
        }

    } // end of findPartnerUsers()

    private static Map<Id, User> getPartnerUserMap(Set<Id> partnerIdSet){
        if(partnerUserMap == null || partnerUserMap.keyset().containsAll(partnerIdSet) == false){
            findPartnerUsers(partnerIdSet);
        }
        system.debug(' **** getPartnerUsers() : partnerUserMap - '+partnerUserMap);
        return partnerUserMap;
    }

    private static Map<ID, List<User>> getAccountUserMap(Set<Id> partnerIdSet){
        if(accountUserMap == null || accountUserMap.keyset().containsAll(partnerIdSet) == false){
            findPartnerUsers(partnerIdSet);
        }
        system.debug(' **** getPartnerUsers() : accountUserMap - '+accountUserMap);
        return accountUserMap;
    }

}