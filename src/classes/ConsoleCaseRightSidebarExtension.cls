global with sharing class ConsoleCaseRightSidebarExtension extends ConsoleRemoteActions
{
    private final Case c;
    public Case caseForFields {get;set;}
    public Attachment fileToUpload {get;set;}
    public Boolean isFileInternal {get;set;}
    private string selectedQueue;
    public string searchText{get;set;}
    public String activeTab{get;set;}

    public ConsoleCaseRightSidebarExtension(ApexPages.StandardController controller) 
    {
        if(!Test.isRunningTest())
            controller.addFields(new String[]{'Subject'});
        
        this.c = (Case)controller.getRecord();
        fileToUpload = new Attachment();
        fileToUpload.Body = null;
        isFileInternal = false;
        
        
        caseForFields = new Case();
        caseForFields.RecordTypeId = inContactBaseClass.SelectRecordTypeIDByName('Incident','Case');
        
        GetQueueCookie();
        searchText = c.Subject;
        
        if(activeTab == null)
        {
            activeTab = 'open-tab';
        }
        
    }
    
    public List<Case> SearchCases
    {
        get
        {
            Case[] cases = new Case[]{};
            
            if(string.isBlank(caseForFields.TechSupportSkill__c))
            {
                cases = [SELECT Id, CaseNumber, Subject, Priority, Status, Owner.Name, RecordType.Name, Account.Name, Account.CostGuard_Acct__c, Account.inContact_Cluster__c, Account.Billing_Group__c, Account.CustomerSegment__c, Account.SalesPartnerMasterAgent__r.PartnerLevel__c, (SELECT TargetDate, IsViolated, MilestoneType.Name FROM CaseMilestones WHERE IsCompleted = false AND MilestoneType.Name = 'SLA') FROM Case WHERE OwnerId = :selectedQueue AND IsClosed = false ORDER BY Priority ASC, CreatedDate DESC LIMIT 50];
            }
            else
            {
                cases = [SELECT Id, CaseNumber, Subject, Priority, Status, Owner.Name, RecordType.Name, Account.Name, Account.CostGuard_Acct__c, Account.inContact_Cluster__c, Account.Billing_Group__c, Account.CustomerSegment__c, Account.SalesPartnerMasterAgent__r.PartnerLevel__c, (SELECT TargetDate, IsViolated, MilestoneType.Name FROM CaseMilestones WHERE IsCompleted = false AND MilestoneType.Name = 'SLA') FROM Case WHERE OwnerId = :selectedQueue AND IsClosed = false AND TechSupportSkill__c = :caseForFields.TechSupportSkill__c ORDER BY Priority ASC, CreatedDate DESC LIMIT 50];
            }
            
            return cases;
        }
    }
    
    public List<CaseArticle__c> Articles
    {
        get
        {
            CaseArticle__c[] articles = new CaseArticle__c[]{};
            
            articles = [SELECT Id, ArticleNumber__c, Summary__c, ArticleUrl__c FROM CaseArticle__c WHERE Case__c = :c.Id];
            
            return articles;
        }
    }
    
    public void GetQueueCookie()
    {
        Cookie queue = ApexPages.currentPage().getCookies().get('queue');
        Cookie skill = ApexPages.currentPage().getCookies().get('skill');
        
        system.debug(queue);
    
        if (queue != null) 
        {
            selectedQueue = queue.getValue();
        }
        
        if(skill != null)
        {
            caseForFields.TechSupportSkill__c = skill.getValue();
        }
    }
    
    public void SetQueueCookie()
    {
        
            Cookie queue = new Cookie('queue', selectedQueue,null,-1,false);
            ApexPages.currentPage().setCookies(new Cookie[]{queue});
            Cookie skill = new Cookie('skill', caseForFields.TechSupportSkill__c ,null,-1,false);
            ApexPages.currentPage().setCookies(new Cookie[]{skill});
    }
    
    public PageReference CreateAttachment()
    {
                
        CaseAttachment attachmentToInsert = new CaseAttachment(fileToUpload , !isFileInternal , c.Id);
        attachmentToInsert.SaveAttachment();
        activeTab = 'attachment-tab';
        fileToUpload.clear();
        isFileInternal = false;
        fileToUpload = new Attachment();
        return null;
    }
    
    public integer CaseCount
    {
        get{return SearchCases.size();}
    }
    
    
    
    public List<CaseAttachment> SelectCaseAttachments
    {
        get
        {
            return CaseAttachment.SelectCaseAttachments(c.Id);
        }
    }
    
    
    
    public List<selectOption> caseQueues
    {
        get
        {
            List<Group> allCaseQueues = new List<Group>([SELECT Id, Name FROM Group WHERE ID IN(SELECT QueueId FROM QueueSobject WHERE SobjectType = 'Case') ORDER BY Name]);
            List<SelectOption> options = new List<SelectOption>(); 
                options.add(new SelectOption('','None')); 
       
        
            for(Group g: allCaseQueues)
            {
                options.add(new SelectOption(g.Id, g.Name));
            }
            
            
            return options;
        }
    }
    
    public string UpdateQueue
    {
        get
        {
            return selectedQueue;
        }
        set
        {
            selectedQueue = value;
        }
    }
    
}