public class ProjectShareHelper {

    // constants
    private static final String SAAS_IMPLEMENTATION_PARTNER = AccountPartnerTriggerHandler.SAAS_IMPLEMENTATION_PARTNER;
    public static final Set<String> psSaaSProjectSet = new Set<String>{
            'PS Parent Project - SaaS',
            'PS Project Phase SaaS'
    };
    public static final Set<String> readOnlyRecordTypesSet = new Set<String>{
            'Connectivity Design',
            'Dedicated Provisioning'
    };
    public static final Set<String> psPremiseProjectSet = new Set<String>{
            'PS Parent Project - Premise',
            'PS Project Phase Premise WFO'
    };

    static Map<ID, List<User>> accountUserMap = null; // key account Id
    static Map<Id, List<Account_Partner__c>> partnerMap = null; // key customer Id

    Set<Id> psSaasProjectIdSet = null;
    Set<Id> readOnlyRecordTypeIdSet = null;
    Set<Id> psPremiseProjectIdSet = null;

    public class ProjectShareHelperException extends Exception{}

    // constructor
    public ProjectShareHelper(){
        Map<String, Schema.RecordTypeInfo> recordTypeNameMap = Schema.SObjectType.Project__c.getRecordTypeInfosByName();
        psSaasProjectIdSet = new Set<Id>();
        readOnlyRecordTypeIdSet = new Set<Id>();
        psPremiseProjectIdSet = new Set<Id>();
        for(String psSaaSProject :  psSaaSProjectSet){
            psSaasProjectIdSet.add(recordTypeNameMap.get(psSaaSProject).recordTypeId);
        }
        for(String readOnlyReordType: readOnlyRecordTypesSet){
            readOnlyRecordTypeIdSet.add(recordTypeNameMap.get(readOnlyReordType).recordTypeId);
        }
        for(String psPremiseProject :  psPremiseProjectSet){
            psPremiseProjectIdSet.add(recordTypeNameMap.get(psPremiseProject).recordTypeId);
        }
    }

    // Share SaaS projects with SaaS partner portal users and Premise Projects with implementation partner portal users
    public void addShare(List<Project__c> newList, Map<Id, Project__c> oldMap){

        if(newList == null || newList.isEmpty()){
            return;
        }

        Set<Id> recordIdSet = new Set<Id>();
        for(Project__c record : newList){
            Project__c oldRecord = ( oldMap != null ) ? oldMap.get(record.Id) : null;
            if(
                // PS SaaS Project - new or account updated
                ( record.Account__c != null && ( oldRecord == null || oldRecord.Account__c != record.Account__c ) && (psSaasProjectIdSet.contains(record.RecordTypeId) || readOnlyRecordTypeIdSet.contains(record.RecordTypeId)) )
                // PS Premise Project - new or implementation partner updated
                || (record.ImplementationPartner__c != null && ( oldRecord == null || oldRecord.ImplementationPartner__c != record.ImplementationPartner__c ) && psPremiseProjectIdSet.contains(record.RecordTypeId) )
                // Record type changed to PS SaaS Project and previous record type other than PS SaaS Project
                || (oldRecord != null && !psSaasProjectIdSet.contains(oldRecord.RecordTypeId) && psSaasProjectIdSet.contains(record.RecordTypeId) && record.Account__c != null)
                // Record type changed to PS Premise Project and previous record type other than PS Premise Project
                || (oldRecord != null && !psPremiseProjectIdSet.contains(oldRecord.RecordTypeId) && psPremiseProjectIdSet.contains(record.RecordTypeId) && record.ImplementationPartner__c != null)
                // Reord type changed to “Connectivity Design” and “Dedicated Provisioning”
                || (oldRecord != null && !readOnlyRecordTypeIdSet.contains(oldRecord.RecordTypeId) && readOnlyRecordTypeIdSet.contains(record.RecordTypeId) && record.Account__c != null)
            ){
                recordIdSet.add(record.Id);
            }
        }
        system.debug(' **** addShare() : recordIdSet - '+recordIdSet);

        if(recordIdSet.isEmpty() == false){
            addShareFuture(recordIdSet);
        }

    } // end of addShare()

    @Future
    private static void addShareFuture(Set<Id> recordIdSet){

        List<Project__c> recordList = new List<Project__c>();
        for(Project__c p : [
                Select Id, Account__c, RecordType.Name, ImplementationPartner__c from Project__c
                where Id IN :recordIdSet
        ]){
            recordList.add(p);
        }
        system.debug(' **** addShareFuture() : recordList - '+recordList);
        if(recordList.isEmpty()){
            return;
        }

        Set<Id> customerIdSet = new Set<Id>();
        Set<Id> partnerIdSet = new Set<Id>();
        for(Project__c record : recordList){
            if(psSaaSProjectSet.contains(record.RecordType.Name) && record.Account__c != null){
                customerIdSet.add(record.Account__c);
            } else if(readOnlyRecordTypesSet.contains(record.RecordType.Name) && record.Account__c != null){
                customerIdSet.add(record.Account__c);
            } else if(psPremiseProjectSet.contains(record.RecordType.Name) && record.ImplementationPartner__c != null){
                partnerIdSet.add(record.ImplementationPartner__c);
            }
        }
        system.debug(' **** addShareFuture() : customerIdSet - '+customerIdSet);
        system.debug(' **** addShareFuture() : partnerIdSet - '+partnerIdSet);
        if(customerIdSet.isEmpty() && partnerIdSet.isEmpty()){
            return;
        }

        Set<Id> groupIdSet = new Set<Id>();
        // Get account partner info
        Map<Id, List<Account_Partner__c>> lPartnerMap = findPartners(customerIdSet);
        for(List<Account_Partner__c> partnerList : lPartnerMap.values()) {
            for (Account_Partner__c partner : partnerList) {
                if(partner.Partner__c != null) {
                    partnerIdSet.add(partner.Partner__c);
                } else if(partner.PublicGroupId__c != null){
                    groupIdSet.add(partner.PublicGroupId__c);
                }
            }
        }
        system.debug(' **** addShareFuture() : lPartnerMap - '+lPartnerMap);
        // Get partner user info
        Map<ID, List<User>> lAccountUserMap = findPartnerUsers(partnerIdSet);
        if(lAccountUserMap.isEmpty() && groupIdSet.isEmpty()){
            return;
        }
        List<Project__Share> shareList = new List<Project__Share>();

        // record iteration
        for(Project__c record : recordList) {
            system.debug(' **** addShareFuture() : record - '+record);
            // Share PS SaaS Project with SaaS partner users
            if (psSaaSProjectSet.contains(record.RecordType.Name)) {
                List<Account_Partner__c> partnerList = lPartnerMap.get(record.Account__c);
                system.debug(' **** addShareFuture() : partnerList - '+partnerList);
                if (partnerList == null || partnerList.isEmpty()) {
                    continue;
                }
                // partner iteration
                for (Account_Partner__c partner : partnerList) {
                    if (partner.PublicGroupId__c != null) {
                        Project__Share share = new Project__Share();
                        share.ParentId = record.Id;
                        share.UserOrGroupId = partner.PublicGroupId__c;
                        share.AccessLevel = 'Edit';
                        shareList.add(share);
                    } else if (partner.Partner__c != null) {
                        List<User> userList = lAccountUserMap.get(partner.Partner__c);
                        if (userList == null || userList.isEmpty()) {
                            continue;
                        }
                        // user iteration
                        for (User partnerUser :userList) {
                            Project__Share share = new Project__Share();
                            share.ParentId = record.Id;
                            share.UserOrGroupId = partnerUser.Id;
                            share.AccessLevel = 'Edit';
                            shareList.add(share);
                        } // end user iteration
                    }
                } // end partner iteration
            }
            else if (readOnlyRecordTypesSet.contains(record.RecordType.Name)) {
                List<Account_Partner__c> partnerList = lPartnerMap.get(record.Account__c);
                system.debug(' **** addShareFuture() : partnerList - '+partnerList);
                if (partnerList == null || partnerList.isEmpty()) {
                    continue;
                }
                // partner iteration
                for (Account_Partner__c partner : partnerList) {
                    if (partner.PublicGroupId__c != null) {
                        Project__Share share = new Project__Share();
                        share.ParentId = record.Id;
                        share.UserOrGroupId = partner.PublicGroupId__c;
                        share.AccessLevel = 'Read';
                        shareList.add(share);
                    } else if (partner.Partner__c != null) {
                        List<User> userList = lAccountUserMap.get(partner.Partner__c);
                        if (userList == null || userList.isEmpty()) {
                            continue;
                        }
                        // user iteration
                        for (User partnerUser :userList) {
                            Project__Share share = new Project__Share();
                            share.ParentId = record.Id;
                            share.UserOrGroupId = partnerUser.Id;
                            share.AccessLevel = 'Read';
                            shareList.add(share);
                        } // end user iteration
                    }
                } // end partner iteration
            }
            // Share PS Premise projects with implementation partner users
            else if(psPremiseProjectSet.contains(record.RecordType.Name)){
                List<User> userList = lAccountUserMap.get(record.ImplementationPartner__c);
                system.debug(' **** addShareFuture() : userList - '+userList);
                if (userList == null || userList.isEmpty()) {
                    continue;
                }
                // user iteration
                for (User partnerUser :userList) {
                    Project__Share share = new Project__Share();
                    share.ParentId = record.Id;
                    share.UserOrGroupId = partnerUser.Id;
                    share.AccessLevel = 'Edit';
                    shareList.add(share);
                } // end user iteration
            }
        } // end record iteration

        system.debug(' **** addShareFuture() : shareList - '+shareList);
        if(shareList.isEmpty() == false){
            Database.saveResult[] resultList=  Database.insert(shareList, false);
            for(Database.saveResult result : resultList){
                if(result.isSuccess() == false){
                    system.debug('**** addShareFuture() : error - '+ result.getErrors()[0]);
                    throw new ProjectShareHelperException(result.getErrors()[0].getMessage());
                }
            }
        }

    } // end of addShareFuture()

    // delete project share records
    public void deleteShare(List<Project__c> newList, Map<Id, Project__c> oldMap){

        if(newList == null || newList.isEmpty()){
            return;
        }

        Set<Id> recordIdSet = new Set<Id>();
        Set<Id> customerIdSet = new Set<Id>();
        Set<Id> partnerIdSet = new Set<Id>();
        for(Project__c record : newList){
            Project__c oldRecord = ( oldMap != null ) ? oldMap.get(record.Id) : null;
            // PS SaaS Project - account updated and previous value not blank
            if( oldRecord != null && oldRecord.Account__c != null && oldRecord.Account__c != record.Account__c && psSaasProjectIdSet.contains(oldRecord.RecordTypeId)){
                recordIdSet.add(record.Id);
                customerIdSet.add(oldRecord.Account__c);
            }
            // PS SaaS Project - account updated and previous value not blank
            if( oldRecord != null && oldRecord.Account__c != null && oldRecord.Account__c != record.Account__c && readOnlyRecordTypeIdSet.contains(oldRecord.RecordTypeId)){
                recordIdSet.add(record.Id);
                customerIdSet.add(oldRecord.Account__c);
            }
            // PS Premise Project - implementation partner updated and previous value not blank
            if( oldRecord != null && oldRecord.ImplementationPartner__c != null && oldRecord.ImplementationPartner__c != record.ImplementationPartner__c
            && psPremiseProjectIdSet.contains(oldRecord.RecordTypeId) ){
                recordIdSet.add(record.Id);
                partnerIdSet.add(oldRecord.ImplementationPartner__c);
            }
            // Record type changed from PS SaaS Project to record type other than PS SaaS Project
            if( oldRecord != null && psSaasProjectIdSet.contains(oldRecord.RecordTypeId) && !psSaasProjectIdSet.contains(record.RecordTypeId)
            && oldRecord.Account__c != null){
                recordIdSet.add(record.Id);
                customerIdSet.add(oldRecord.Account__c);
            }
            // Record type changed from PS SaaS Project to record type other than PS SaaS Project
            if( oldRecord != null && readOnlyRecordTypeIdSet.contains(oldRecord.RecordTypeId) && !readOnlyRecordTypeIdSet.contains(record.RecordTypeId)
                    && oldRecord.Account__c != null){
                recordIdSet.add(record.Id);
                customerIdSet.add(oldRecord.Account__c);
            }
            // Record type changed from PS Premise Project to record type other than PS Premise Project
            if( oldRecord != null && psPremiseProjectIdSet.contains(oldRecord.RecordTypeId) && !psPremiseProjectIdSet.contains(record.RecordTypeId)
            && oldRecord.ImplementationPartner__c != null){
                recordIdSet.add(record.Id);
                partnerIdSet.add(oldRecord.ImplementationPartner__c);
            }
        }
        system.debug(' **** deleteShare() : recordIdSet - '+recordIdSet);

        if(recordIdSet.isEmpty()){
            return;
        }

        set<Id> groupIdSet = new set<Id>();
        // Get account partner info
        Map<Id, List<Account_Partner__c>> lPartnerMap = findPartners(customerIdSet);
        for(List<Account_Partner__c> partnerList : lPartnerMap.values()) {
            for (Account_Partner__c partner : partnerList) {
                if(partner.PublicGroupId__c != null)
                {
                    groupIdSet.add(partner.PublicGroupId__c);
                }
                else if(partner.Partner__c != null) {
                    partnerIdSet.add(partner.Partner__c);
                }
            }
        }

        if(partnerIdSet.isEmpty() && groupIdSet.isEmpty()){
            return;
        }
        // Get partner user info
        Map<ID, List<User>> lAccountUserMap = findPartnerUsers(partnerIdSet);
        Set<Id> userIdSet = new Set<Id>();
        for(List<User> userList : lAccountUserMap.values()){
            for(User u : userList){
                userIdSet.add(u.Id);
            }
        }
        system.debug(' **** deleteShare() : userIdSet - '+userIdSet);

        if(userIdSet.isEmpty() && groupIdSet.isEmpty()){
            return;
        }

        set<Id> UserOrGroupIdSet = new set<Id>();
        UserOrGroupIdSet.addAll(groupIdSet); // Group ID's
        UserOrGroupIdSet.addAll(userIdSet); // User ID's

        List<Project__Share> shareList = [
                Select Id from Project__Share
                where RowCause = 'Manual' and ParentId IN :recordIdSet
                and UserOrGroupId IN :UserOrGroupIdSet
        ];
        system.debug(' **** deleteShare() : shareList - '+shareList);

        if(shareList.isEmpty() == false){
            Database.DeleteResult[] resultList=  Database.delete(shareList, false);
            for(Database.DeleteResult result : resultList){
                if(result.isSuccess() == false){
                    system.debug('**** deleteShare() : id - '+ result.getId());
                    system.debug('**** deleteShare() : error - '+ result.getErrors()[0]);
                    throw new ProjectShareHelperException(result.getErrors()[0].getMessage());
                }
            }
        }

    } // end of deleteShare()

    // retrieve account partner info
    public static Map<ID, List<Account_Partner__c>> findPartners(Set<Id> customerIdSet)
    {
        system.debug(' **** findPartners() : customerIdSet - '+customerIdSet);
        if(partnerMap != null && partnerMap.keySet().containsAll(customerIdSet)){
            return partnerMap;
        }

        partnerMap = new Map<Id, List<Account_Partner__c>>();
        if(customerIdSet.isEmpty() == false) {
            for (Account_Partner__c partner : [
                    SELECT Customer__c, Partner__c, PublicGroupId__c, Partner_Type__c
                    from Account_Partner__c
                    where Customer__c IN :customerIdSet
                    and Partner_Type__c = :SAAS_IMPLEMENTATION_PARTNER
            ]) {
                List<Account_Partner__c> partnerList = partnerMap.get(partner.Customer__c);
                if (partnerList == null) {
                    partnerList = new List<Account_Partner__c>();
                    partnerMap.put(partner.Customer__c, partnerList);
                }
                partnerList.add(partner);
            }
        }
        system.debug(' **** findPartners() : partnerMap - '+partnerMap);
        return partnerMap;

    } // end of findPartners()

    // retrieve partner portal user info
    public static Map<ID, List<User>> findPartnerUsers(Set<Id> partnerIdSet)
    {
        system.debug(' **** findPartnerUsers() : partnerIdSet - '+partnerIdSet);
        if(accountUserMap != null && accountUserMap.keySet().containsAll(partnerIdSet)){
            return accountUserMap;
        }
        accountUserMap = new Map<ID, List<User>>();
        if(partnerIdSet.isEmpty() == false) {
            for (User partnerUser : [
                    Select Id, ContactId, AccountId
                    from User
                    where IsPortalEnabled = true and IsActive = true
                    and UserType IN ('Partner', 'PowerPartner')
                    and AccountId IN :partnerIdSet
            ]) {
                List<User> userList = accountUserMap.get(partnerUser.AccountId);
                if (userList == null) {
                    userList = new List<User>();
                    accountUserMap.put(partnerUser.AccountId, userList);
                }
                userList.add(partnerUser);
            }
        }
        system.debug(' **** findPartnerUsers() : accountUserMap - '+accountUserMap);
        return accountUserMap;

    } // end of findPartnerUsers()

}