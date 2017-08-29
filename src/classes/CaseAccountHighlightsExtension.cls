public with sharing class CaseAccountHighlightsExtension 
{
    private final Case c;
    public String target{get;set;}
    public string URLForPage{public get;private set;}

    public CaseAccountHighlightsExtension(ApexPages.StandardController controller) 
    {
        this.c = (Case)controller.getRecord();
        URLForPage = ApexPages.currentPage().getHeaders().get('Host');
    }
    
    public void CreateTfsItem()
    {
        
        TfsWorkItem__c workItem = new TfsWorkItem__c();
        workItem.Name = 'Processing...';
        workItem.Description__c = c.Summary__c;
        workItem.StepsToReproduce__c = c.Steps_to_Recreate__c;
        workItem.Title__c = c.Subject;
        workItem.FoundBy__c = c.FoundBy__c;
        workItem.ExistsIn__c = c.ExistsIn__c;
        insert workItem;
        
        try
        {
            TfsAccess.CreateTfsItem(workItem.Id, c.Summary__c, c.InternalNotes__c, c.Steps_to_Recreate__c,'inContact');
            c.TFSWorkItem__c = workItem.Id;
            update c;
        }
        catch(Exception ex)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            inContactBaseClass.SendErrorEmail(ex,c.Id);
        }
    }

    public void CreateJIRABug() {
        try {
            //call into some wrapper class to create the JIRA bug

            HttpRequest request = new HttpRequest();

            String body = '{"Project" : "{0}", "IssueType" : "{1}"}';
            String.format(body, new String[]{ 'IC', '10004'});
            request.setBody(body);

            request.setEndpoint('http://tlvjiratst02:8080/rest/customware/connector/1.0/1/Case/' + c.Id + '/issue/create.json');

            request.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf('salesforceuser' + ':' + '1qaz2wsx')));

            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');


            system.debug('CreateJIRABug(): request - ' + request);
            Http h = new Http();


            HttpResponse response = h.send(request);
            system.debug('CreateJIRABug(): response -  ' + response.getBody());

            String returnResponse = response.getBody();

            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, returnResponse));

        }
        catch(Exception ex) {
            system.debug('CreateJIRABug(): ex -  ' + ex);
        }
    }

    
    public PageReference Save()
    {
        
        //return to case page
        PageReference casePage = new PageReference('/' + c.Id);
        casePage.setRedirect(true);
        
        return casePage;
    
    }

}