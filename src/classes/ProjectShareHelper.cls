public class ProjectShareHelper {

    private static final Set<String> psSaaSProjectSet = new Set<String>{
            'PS Parent Project - SaaS',
            'PS Project Phase SaaS'
    };

    Set<Id> psSaasProjectIdSet = null;

    public class ProjectShareHelperException extends Exception{}

    public ProjectShareHelper(){
        Map<String, Schema.RecordTypeInfo> recordTypeNameMap = Schema.SObjectType.Project__c.getRecordTypeInfosByName();
        psSaasProjectIdSet = new Set<Id>();
        for(String psSaaSProject :  psSaaSProjectSet){
            psSaasProjectIdSet.add(recordTypeNameMap.get(psSaaSProject).recordTypeId);
        }
    }

    public void addShare(List<Project__c> newList, Map<Id, Project__c> oldMap){

        if(newList == null || newList.isEmpty()){
            return;
        }

        Set<Id> recordIdSet = new Set<Id>();
        for(Project__c record : newList){
            Project__c oldRecord = ( oldMap != null ) ? oldMap.get(record.Id) : null;
            if( ( record.Account__c != null && ( oldRecord == null || oldRecord.Account__c != record.Account__c ) && psSaasProjectIdSet.contains(record.RecordTypeId) )
            || (record.ImplementationPartner__c != null && ( oldRecord == null || oldRecord.ImplementationPartner__c != record.ImplementationPartner__c ) ) ){
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
            if(psSaaSProjectSet.contains(record.RecordType.Name) ){
                customerIdSet.add(record.Account__c);
            } else if(record.ImplementationPartner__c != null){
                partnerIdSet.add(record.ImplementationPartner__c);
            }
        }

        Set<Id> groupIdSet = new Set<Id>();
        Map<Id, List<Account_Partner__c>> lPartnerMap = PartnerShareHelper.findPartners(customerIdSet);
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

        Map<ID, List<User>> lAccountUserMap = PartnerShareHelper.findPartnerUsers(partnerIdSet);
        if(lAccountUserMap.isEmpty() && groupIdSet.isEmpty()){
            return;
        }
        List<Project__Share> shareList = new List<Project__Share>();

        // record iteration
        for(Project__c record : recordList){
            List<Account_Partner__c> partnerList = null;
            if(psSaaSProjectSet.contains(record.RecordType.Name) ){
                partnerList = lPartnerMap.get(record.Account__c);
            } else if(record.ImplementationPartner__c != null){
                partnerList = lPartnerMap.get(record.ImplementationPartner__c);
            }
            if(partnerList == null || partnerList.isEmpty()){
                continue;
            }
            // partner iteration
            for(Account_Partner__c partner : partnerList){
                if(partner.PublicGroupId__c != null)
                {
                    Project__Share share = new Project__Share();
                    share.ParentId = record.Id;
                    share.UserOrGroupId = partner.PublicGroupId__c;
                    share.AccessLevel = 'Edit';
                    shareList.add(share);
                }
                else if(partner.Partner__c != null)
                {
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

    public void deleteShare(List<Project__c> newList, Map<Id, Project__c> oldMap){

        if(newList == null || newList.isEmpty()){
            return;
        }

        Set<Id> recordIdSet = new Set<Id>();
        Set<Id> customerIdSet = new Set<Id>();
        Set<Id> partnerIdSet = new Set<Id>();
        for(Project__c record : newList){
            Project__c oldRecord = ( oldMap != null ) ? oldMap.get(record.Id) : null;
            if( oldRecord != null && oldRecord.Account__c != null && oldRecord.Account__c != record.Account__c && psSaasProjectIdSet.contains(record.RecordTypeId)){
                recordIdSet.add(record.Id);
                customerIdSet.add(record.Account__c);
            }
            if( oldRecord != null && oldRecord.ImplementationPartner__c != null && oldRecord.ImplementationPartner__c != record.ImplementationPartner__c ){
                partnerIdSet.add(record.ImplementationPartner__c);
            }
        }
        system.debug(' **** deleteShare() : recordIdSet - '+recordIdSet);

        if(recordIdSet.isEmpty()){
            return;
        }


        set<Id> groupIdSet = new set<Id>();
        Map<Id, List<Account_Partner__c>> lPartnerMap = PartnerShareHelper.findPartners(customerIdSet);
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

        Map<ID, List<User>> lAccountUserMap = PartnerShareHelper.findPartnerUsers(partnerIdSet);
        if(lAccountUserMap.isEmpty()){
            return;
        }

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

}