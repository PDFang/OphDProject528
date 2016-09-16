public with sharing class CaseIncidentPage 
{
    public Case c {get;set;}
    public List<Schema.FieldSetMember> ActiveSet {public get; private set;}
    public Case[] events{public get;private set;}
    public List<KnowledgeControlsClass.KnowledgeSelection> knowledgeResults{public get;private set;}
    public boolean renderEvents{public get; private set;}
    public Map<String, KnowledgeControlsClass.KnowledgeSelection> selectedArticles{public get;private set;}
    public boolean isVip {public get; private set;}
    
    public CaseIncidentPage(ApexPages.StandardController controller) 
    {
        this.c = (Case)controller.getRecord();
        c.RecordTypeId = '01270000000LuEp';
        AddLinkedInfo();
        SetActiveSet();
        renderEvents = false;
        if(c.Id != null)
        {
            SetCase();
        }
        else
        {
            
            events = [SELECT Subject, Description, Status, InternalEvent__c, CaseNumber, AccountId FROM Case WHERE RecordType.Name = 'Event' AND IsClosed = False AND NonEvent__c = FALSE];
            if(!events.isEmpty())
            {
                renderEvents = true;
            }
        }
        
        knowledgeResults = new List<KnowledgeControlsClass.KnowledgeSelection>();
        selectedArticles = new Map<String, KnowledgeControlsClass.KnowledgeSelection>();
        
        SetIsVip();
    }
    
    
    public void UploadArticles()
    {
    
        //try
        //{
            knowledgeResults = KnowledgeControlsClass.SearchSaasArticles(c.Subject);
            
        //}
        //catch(Exception ex)
        //{
        //    knowledgeResults = new List<KnowledgeControlsClass.KnowledgeSelection>();
        //}
        
    }
    
    private void SetCase() {
        String query = 'SELECT ';
        for(Schema.FieldSetMember f : ActiveSet) {
            query += f.getFieldPath() + ', ';
        }
        query += 'Id, AccountId FROM Case WHERE Id = \'' + c.Id + '\'';
        c =  Database.query(query);
    }
    
    
    
    public void AddLinkedInfo()
    {
        string acctId = ApexPages.currentPage().getParameters().get('def_account_id');
        string contactId = ApexPages.currentPage().getParameters().get('def_contact_id');

        if(acctId != null)
        {
            c.AccountId = acctId;
        }
        
        if(contactId != null)
        {
            c.ContactId = contactId;
        }
    }
    
    public void SetActiveSet()
    {
        
       ActiveSet = SObjectType.Case.FieldSets.Other.getFields();

    
        if(c.Request_Type__c != null)
        {
            string abbr = c.Request_Type__c.Replace(' ','').Replace('/','');
            if(Schema.SObjectType.Case.fieldSets.getMap().get(abbr) != null)
            {
                ActiveSet = Schema.SObjectType.Case.fieldSets.getMap().get(abbr).getFields();
            }
        }
    }
    
    public void SaveRecord()
    {
        
        //set default assignment rule       
        database.DMLOptions dmo = new database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        
        c.setOptions(dmo);
        
        try
        {
            insert c;
            
            if(c.KnownIssue__c != null)
            {
                c.Status = 'Assigned To Known Issue';
                update c;
            }
        }
        catch(DmlException ex)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getDmlMessage(0)));
            return;
        }
        
        try
        {
            KnowledgeControlsClass.AttachArticleSelectionsToCase(selectedArticles.values(), c.Id);
        }
        catch(DmlException ex)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getDmlMessage(0)));
            return;
        }   
    
    }
    
    public PageReference Save()
    {
        
        SaveRecord();
        
        if(ApexPages.hasMessages())
        {
            return null;
        }
        
        //return to case page
        PageReference casePage = new PageReference('/' + c.Id);
        casePage.setRedirect(true);
        
        return casePage;
    }
    
    public PageReference SaveAndTrackTime()
    {
    
        SaveRecord();
        
        if(ApexPages.hasMessages())
        {
            return null;
        }
        
        //return to case page
        PageReference casePage = new PageReference('/apex/StandardTextEntry?id=' + c.Id);
        casePage.setRedirect(true);
        
        return casePage;
    }
    
    public PageReference SaveAndClose()
    {
    
        SaveRecord();
        
        if(ApexPages.hasMessages())
        {
            return null;
        }
        
        //return to case page
        PageReference casePage = new PageReference('/' + c.Id + '/s?retURL=' + c.Id);
        casePage.setRedirect(true);
        
        return casePage;
    }
    
    public List<SelectOption> ActiveEvents 
    {
        get
        {
            List<SelectOption> options = new List<SelectOption>(); 
            options.add(new SelectOption('','None')); 
            
            for(Case e:events)
            {
                options.add(new SelectOption(e.Id, '(' + e.CaseNumber + ') ' + e.Subject));
            }
            return options; 
        }
    }
    
    public PageReference SaveInline()
    {
        update c;
        //return to case page
        PageReference casePage = Page.CaseStandardTextDisplay;
        casePage.getParameters().put('id',c.id);
        casePage.setRedirect(true);
        
        return casePage;
    }
    
    public PageReference CancelInline()
    {
        //return to case page
        PageReference casePage = Page.CaseStandardTextDisplay;
        casePage.getParameters().put('id',c.id);
        casePage.setRedirect(true);
        
        return casePage;
    }
    
    
    public void RemoveSelectedArticle()
    {
        string articleNumber = Apexpages.currentpage().getParameters().get('kbNumber');
        selectedArticles.remove(articleNumber);
    }
    
    public List<KnowledgeControlsClass.KnowledgeSelection> RetrieveSelectedArticles
    {
        get
        {
            return selectedArticles.values();
        }
    }
    
    public void ArticlesSelected()
    {
        for(KnowledgeControlsClass.KnowledgeSelection kb:knowledgeResults)
        {
            if(kb.Selected && !selectedArticles.containsKey(kb.article.Id))
            {
                selectedArticles.put(kb.article.Id,kb);
            }
        }
    }
    
    public void SetIsVip()
    {
        if(c.AccountId != null)
        {
            string segment = [SELECT CustomerSegment__c FROM Account WHERE Id = :c.AccountId].CustomerSegment__c;
            if(segment == 'Top 10' || segment == 'VIP')
            {
                isVip = true;
                return;
            }
        }
        
        isVip = false;
        
    }
    
    public void ClearKnownIssue()
    {
        c.KnownIssue__c = null;
    }
    
   

}