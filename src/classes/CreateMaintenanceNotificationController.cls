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
    public string contactUsString{get;set;}
    public boolean emergency{get;set;}
    public CreateMaintenanceNotificationController(ApexPages.StandardController controller){
        this.ccr = (BMCServiceDesk__Change_Request__c)controller.getRecord();
        maintenanceCases = new list<Case>();
        impactedClusters = new list<string>();
        maintenanceCases = getExistingCases();
        loadCaseDetails();

    }

    public list<SelectOption> getContactInfo(){
        list<SelectOption> contactinfoStrings = new list<SelectOption>();
        for(ContactUsInfo__mdt info : [select ContactInfoText__c from ContactUsInfo__mdt]){

            contactinfoStrings.add(new SelectOption(info.ContactInfoText__c,info.ContactInfoText__c));

        }

        return contactinfoStrings;
    }

    private list<case> getExistingCases(){
       return [Select Id, CaseNumber, ProductImpacted__c,PlatformsImpacted__c, EmergencyMaintenance__c, Priority, Assigned_To__r.Name, Status, CreatedDate
                            From Case where RF_Change_Request__c =: ccr.Id order by CaseNumber desc];

    }
    // go back to CCR details
    public pagereference goBack(){
        return new ApexPages.StandardController(ccr).view();
    }

    private void loadCaseDetails(){
        newCase = new Case();
        contactUsString = '';
        Schema.DescribeSObjectResult d = Schema.SObjectType.Case;
        Map<String,Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();
        string maintenanceRecordType = rtMapByName.get('Maintenance Notification').getRecordTypeId();

        ccr = [select RF_Summary__c,Name, RF_Cluster_s__c, BMCServiceDesk__Change_Description__c, RF_Maint_Window_Start_Time__c, RF_Maint_Window_End_Time__c,
                BMCServiceDesk__Change_Type__c, RF_Customer_Impact_Analysis__c
        from  BMCServiceDesk__Change_Request__c where Id =:ccr.id ];

        if(ccr.RF_Cluster_s__c != null)
            impactedClusters = ccr.RF_Cluster_s__c.split(';');

        newCase = new Case(
                Subject = ccr.RF_Summary__c,
                RecordTypeId = maintenanceRecordType,
                Description = ccr.BMCServiceDesk__Change_Description__c,
                RF_Change_Request__c = ccr.Id,
                ProductImpacted__c = null,
                PlatformsImpacted__c = null,
                CustomerAnalysis__c = ccr.RF_Customer_Impact_Analysis__c,
                EventType__c = 'Platform/Software Updates'
        );

        endTime = ccr.RF_Maint_Window_End_Time__c;
        startTime = ccr.RF_Maint_Window_Start_Time__c;
        emergency = ccr.BMCServiceDesk__Change_Type__c == 'Emergency' ? true : false;
        //system.debug('newCase =>' + newCase);
    }


    public PageReference createMaintenanceRecord(){
        if(newCase.ProductImpacted__c == '' || newCase.ProductImpacted__c == null || newCase.PlatformsImpacted__c == '' || newCase.PlatformsImpacted__c == null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Product & Platforms Impacted are required fields. Please make a selection'));
        }else if(contactUsString == '' || contactUsString == null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Please choose a contact Info radio checkbox.'));
        }else{
            newCase.EventStartDateTime__c = startTime;
            newCase.EventEndDateTime__c = endTime;
            newCase.ContactInfoText__c = contactUsString.replace('<br/>', '');
            newCase.EmergencyMaintenance__c = emergency;
            system.debug('new case =>' + newCase);
            try{
                insert newCase;
                loadCaseDetails();
                maintenanceCases = getExistingCases();
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Successfully created a maintenance record. You may close this window now.'));

            }catch (Exception ex){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, ex.getMessage()));
            }
        }

        return null;

    }

}