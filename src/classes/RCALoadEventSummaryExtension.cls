public class RCALoadEventSummaryExtension 
{
    private final RCA__c rca;
    public final Case event{public get;private set;}
    
    public RCALoadEventSummaryExtension(ApexPages.StandardController controller) 
    {
        this.rca = (RCA__c)controller.getRecord();
        event = [SELECT Id, CaseNumber, Subject, ProductImpacted__c, PlatformsImpacted__c, EventStartDateTime__c, EventEndDateTime__c, Description FROM Case WHERE ID = :rca.Event__c];
    }

    public PageReference Save()
    {
        
        
        rca.EventSummaryCompleted__c = true;
        rca.EventSummaryDateTime__c = system.now();
        rca.Status__c = 'Event Summary Completed';
        rca.OwnerId = rca.CustomerAdvocate__c;
        
        update rca;
        
        PageReference rcaPage = new PageReference('/' + rca.Id);
        rcaPage.setRedirect(true);
        
        return rcaPage;
    }

}