/**
 * Created by arnab.karsarkar on 7/20/2017.
 */

public class CreateMaintenanceNotificationController {

    public BMCServiceDesk__Change_Request__c ccr{get; set;}
    public list<Case> maintenanceCases{get; set;}
    public list<string> impactedClusters{get;set;}
    public Case newCase {get; set;}
    public datetime startTime{get;set;}
    public datetime endTime{get;set;}

    public CreateMaintenanceNotificationController(ApexPages.StandardController controller){
        this.ccr = (BMCServiceDesk__Change_Request__c)controller.getRecord();
        ccr = [select RF_Summary__c, RF_Cluster_s__c, BMCServiceDesk__Change_Description__c, RF_Maint_Window_Start_Time__c, RF_Maint_Window_End_Time__c,
                BMCServiceDesk__Change_Type__c, RF_Customer_Impact_Analysis__c
               from  BMCServiceDesk__Change_Request__c where Id =:ccr.id ];
        maintenanceCases = new list<Case>();
        newCase = new Case();
        getCases();
        impactedClusters = new list<string>();
        if(ccr.RF_Cluster_s__c != null)
            impactedClusters = ccr.RF_Cluster_s__c.split(';');

        loadCaseDetails();
        endTime = ccr.RF_Maint_Window_End_Time__c;
        startTime = ccr.RF_Maint_Window_Start_Time__c;
    }

    public list<SelectOption> getContactInfo(){
        list<SelectOption> contactinfoStrings = new list<SelectOption>();
        for(ContactUsInfo__mdt info : [select ContactInfoText__c from ContactUsInfo__mdt]){

            contactinfoStrings.add(new SelectOption(info.ContactInfoText__c,info.ContactInfoText__c));

        }

        return contactinfoStrings;
    }

    private void getCases(){
        maintenanceCases = [Select Id, CaseNumber, ProductImpacted__c,PlatformsImpacted__c, EmergencyMaintenance__c, Priority, Assigned_To__r.Name, Status, CreatedDate
                            From Case where RF_Change_Request__c =: ccr.Id order by CaseNumber desc];

    }
    // go back to CCR details
    public pagereference goBack(){
        return new ApexPages.StandardController(ccr).view();
    }

    public void loadCaseDetails(){
        Schema.DescribeSObjectResult d = Schema.SObjectType.Case;
        Map<String,Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();
        string maintenanceRecordType = rtMapByName.get('Maintenance Notification').getRecordTypeId();
        newCase = new Case(
                Subject = ccr.RF_Summary__c,
                RecordTypeId = maintenanceRecordType,
                Description = ccr.BMCServiceDesk__Change_Description__c,
                EventStartDateTime__c = ccr.RF_Maint_Window_Start_Time__c,
                EventEndDateTime__c = ccr.RF_Maint_Window_End_Time__c,
                EmergencyMaintenance__c = ccr.BMCServiceDesk__Change_Type__c == 'Emergency' ? true : false,
                CustomerAnalysis__c = ccr.RF_Customer_Impact_Analysis__c
        );

        system.debug('newCase =>' + newCase);
    }


}