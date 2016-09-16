public class RCARFEPageExtension {

    private final RCA__c rca;
    public final Case event{public get;private set;}

    public RCARFEPageExtension(ApexPages.StandardController controller) 
    {
        this.rca = (RCA__c)controller.getRecord();
        if(rca.RFECreator__c == null) rca.RFECreator__c = UserInfo.getUserId();
        
        event = [SELECT Id, CaseNumber, Subject, EventStartDateTime__c, EventEndDateTime__c FROM Case WHERE Id = :rca.Event__c];
    }
    
    public PageReference Save()
    {
        rca.RFEApproved__c = false;
        rca.RFEAPprovalDateTime__c = null;
        rca.RFEDraftCompleted__c = false;
        rca.RFEDraftCompletedDateTime__c = null;
        rca.RFEPublished__c = false;
        rca.RFEPublishedDateTime__c = null;
        rca.Status__c = 'Being Worked';
        rca.CloseDate__c = null;
        update rca;
        
        PageReference rcaPage = new PageReference('/' + rca.Id);
        rcaPage.setRedirect(true);
        
        return rcaPage;
    }

}