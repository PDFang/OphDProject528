/**
 * Created by mohandaas.rangaswamy on 11/28/2016.
 */
public without sharing class OpportunityPartnerSharingExtension {

    public Opportunity opp{get;set;}
    public string keyword{get;set;}
    public string searchBy{get;set;}
    public Integer currentPage{get;private set;}
    public Integer getTotalPages(){
        return (wrapperList != null && wrapperList.size() > 0 )
                ? ((Decimal) wrapperList.size()/ NO_OF_ROWS ).round(System.RoundingMode.CEILING).intValue() : 1;
    }

    public List<UserWrapper> getDisplayList(){
        List<UserWrapper> displayList = new List<UserWrapper>();
        for(Integer i = startIndex; i < (startIndex + NO_OF_ROWS) && wrapperList != null && i < wrapperList.size(); i++){
            displayList.add(wrapperList[i]);
        }
        return displayList;
    }

    private static final String PARTNEY_TYPE_ICE = 'iCE';

    private static final Integer NO_OF_ROWS = 10;

    private Integer startIndex = 0;
    private List<UserWrapper> wrapperList;

    public static List<SelectOption> getOptions() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('Name','Name'));
        options.add(new SelectOption('Account','Account'));
        return options;
    }

    public class UserWrapper{
        public boolean selected{get;set;}
        public User partner{get; private set;}

        public UserWrapper(User u){
            this.partner = u;
            this.selected = false;
        }
    }

    public OpportunityPartnerSharingExtension(ApexPages.StandardController controller){

        try {
            searchBy = 'Name';
            currentPage = 1;
            wrapperList = new List<UserWrapper>();
            List<Opportunity> oppList = [Select Id, Name, iCE_Partner_Status__c, iCE_Partner__c
                                            from Opportunity where Id = :controller.getId()];
            if(oppList.size() == 0){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Opportunity could not be retrieved.'));
                return;
            }
            opp = oppList[0];
            system.debug('**** search(): opp - ' + opp);
            if(opp.iCE_Partner__c != null){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning, 'Opportunity has already been accepted. Click cancel to go back to Opportunity.'));
                return;
            }

            doInit();
        } catch(system.Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, ex.getMessage()));
        }

    } // end of constructor

    private void doInit(){

        List<Partner_Permission_Set__mdt> mdt = [
                Select Permission_Set__c, Partner_Type__c
                from Partner_Permission_Set__mdt
                where Partner_Type__c = :PARTNEY_TYPE_ICE
        ];
        if(mdt.isEmpty()){
            return;
        }

        Set<Id> currentUserIds = new Set<Id>();
        for(Shared_Opportunity__c sharedOpp : [
                Select Partner_User__c
                from Shared_Opportunity__c
                where Opportunity__c = :opp.Id
        ]){
            currentUserIds.add(sharedOpp.Partner_User__c);
        }

        for(PermissionSetAssignment psa :[
                Select AssigneeId, Assignee.Name, Assignee.isActive, Assignee.AccountId, Assignee.Account.Name
                from PermissionSetAssignment
                where PermissionSet.Name = :mdt[0].Permission_Set__c
                and Assignee.isActive = true
                and AssigneeId NOT IN :currentUserIds
                order by Assignee.Name
        ]){
            UserWrapper wrapper = new UserWrapper(psa.Assignee);
            wrapperList.add(wrapper);
        }
        if(wrapperList.size() == 0){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'No partner user(s) found.'));
        }
    } // end of doInit()

    public pagereference previous(){

        if(currentPage > 1) {
            currentPage--;
            startIndex = (currentPage * NO_OF_ROWS) - NO_OF_ROWS;
        }
        return null;
    }

    public pagereference next(){

        if(currentPage < getTotalPages()) {
            currentPage++;
            startIndex = (currentPage * NO_OF_ROWS) - NO_OF_ROWS;
        }
        return null;
    }

    public pagereference first(){
        currentPage = 1;
        startIndex = 0;
        return null;
    }

    public pagereference last(){
        currentPage = getTotalPages();
        startIndex = (currentPage * NO_OF_ROWS) - NO_OF_ROWS;
        return null;
    }

    public pagereference search(){

        currentPage = 1;
        startIndex = 0;
        wrapperList = new List<UserWrapper>();

        system.debug('**** search(): keyword - ' + keyword);
        system.debug('**** search(): searchBy - ' + searchBy);
        try {
            List<Partner_Permission_Set__mdt> mdt = [
                    Select Permission_Set__c, Partner_Type__c
                    from Partner_Permission_Set__mdt
                    where Partner_Type__c = :PARTNEY_TYPE_ICE
            ];
            if (mdt.isEmpty() || string.isBlank(keyword) || string.isBlank(searchBy)) {
                return null;
            }

            string refinedKeyword = keyword.replaceAll('[*]', '%');
            refinedKeyword += refinedKeyword.endsWith('%') ? '' : '%';
            String soql = 'Select AssigneeId, Assignee.Name, Assignee.isActive, Assignee.AccountId, Assignee.Account.Name '
                    + 'from PermissionSetAssignment '
                    + 'where PermissionSet.Name = \'' + mdt[0].Permission_Set__c + '\' '
                    + 'and Assignee.isActive = true and ';

            soql = soql + ( (searchBy == 'Name') ? 'Assignee.Name ' : 'Assignee.Account.Name ' );
            soql = soql + 'like \'' + refinedKeyword + '\' order by Assignee.Name';

            system.debug('**** search(): soql - ' + soql);

            for (PermissionSetAssignment psa :Database.query(soql)) {
                UserWrapper wrapper = new UserWrapper(psa.Assignee);
                wrapperList.add(wrapper);
            }

            if(wrapperList.size() == 0){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'No results found.'));
            }
        }catch(Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, ex.getMessage()));
        }
        return null;
    }

    public pagereference shareOpportunity() {

        system.debug('**** shareOpportunity():  wrapperList - ' + wrapperList);

        List<Shared_Opportunity__c> sharedOppList = new List<Shared_Opportunity__c>();
        for (UserWrapper wrapper : wrapperList) {
            if (!wrapper.selected) {
                continue;
            }
            Shared_Opportunity__c sharedOpp = new Shared_Opportunity__c();
            sharedOpp.Opportunity__c = opp.Id;
            sharedOpp.Partner_User__c = wrapper.partner.Id;
            sharedOppList.add(sharedOpp);
        }

        if (sharedOppList.size() == 0){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Please select at least one User to Share this Opportunity.'));
            return null;
        }

        try{
            if(sharedOppList.size() > 0)
                insert sharedOppList;

            // share records with partner users
            List<Shared_Opportunity__Share> shareList = new List<Shared_Opportunity__Share>();
            for(Shared_Opportunity__c sharedOpp : sharedOppList){
                Shared_Opportunity__Share newShare = new Shared_Opportunity__Share();
                newShare.ParentId = sharedOpp.Id;
                newShare.UserOrGroupId = sharedOpp.Partner_User__c;
                newShare.AccessLevel = 'Edit';
                newShare.Rowcause = Schema.Shared_Opportunity__Share.RowCause.iCE_Partner__c;
                shareList.add(newShare);
            }
            insert shareList;

            // update opportunity status
            opp.iCE_Partner_Status__c = 'Pending';
            update opp;

        }catch(Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, ex.getMessage()));
            return null;
        }

        return new ApexPages.StandardController(opp).view();
    }

    public pagereference cancel(){
        return new ApexPages.StandardController(opp).view();
    }

}