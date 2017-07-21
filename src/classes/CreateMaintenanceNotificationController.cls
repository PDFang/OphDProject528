/**
 * Created by arnab.karsarkar on 7/20/2017.
 */

public class CreateMaintenanceNotificationController {

    public BMCServiceDesk__Change_Request__c ccr{get; set;}
    public list<Case> maintenanceCases{get; set;}
    public list<string> impactedClusters{get;set;}
    public Case newCase {get; set;}

    public CreateMaintenanceNotificationController(ApexPages.StandardController controller){
        this.ccr = (BMCServiceDesk__Change_Request__c)controller.getRecord();
        ccr = [select RF_Summary__c, RF_Cluster_s__c from  BMCServiceDesk__Change_Request__c where Id =:ccr.id ];
        maintenanceCases = new list<Case>();
        newCase = new Case();
        getCases();


        impactedClusters = new list<string>();
        /*if(ccr.RF_Cluster_s__c != null)
            impactedClusters = ccr.RF_Cluster_s__c.split(';');*/

    }

    public list<string> getContactInfo(){
        list<string> contactinfoStrings = new list<string>();
        for(ContactUsInfo__mdt info : [select ContactInfoText__c from ContactUsInfo__mdt]){
            contactinfoStrings.add(info.ContactInfoText__c);
        }

        return contactinfoStrings;
    }


    private void getCases(){
        maintenanceCases = [Select Id, CaseNumber, ProductImpacted__c,PlatformsImpacted__c, EmergencyMaintenance__c, Priority, Assigned_To__r.Name, Status, CreatedDate
                            From Case where RF_Change_Request__c =: ccr.Id order by CaseNumber desc];

    }


    // go back to contact details
    public pagereference goBack(){

        return new ApexPages.StandardController(ccr).view();

    }



}