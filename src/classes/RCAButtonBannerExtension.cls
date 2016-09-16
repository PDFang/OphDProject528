public with sharing class RCAButtonBannerExtension 
{
    private final RCA__c rca;
    public final Case c;
    public boolean renderPublishButton{public get; private set;}
    public boolean renderSubmitButton{public get; private set;}
    public boolean renderEventSummaryButton{public get; private set;}
    public boolean renderCloseNonEvent{public get; private set;}
    public boolean renderForm{public get; private set;}
    public string closeButtonText{public get;private set;}
    public boolean closed{public get;private set;}
    private string objectID = '';
    public string URLForPage{public get;private set;}
    
    public RCAButtonBannerExtension(ApexPages.StandardController controller) 
    {
        this.rca = (RCA__c)controller.getRecord();
        
        closeButtonText = 'Close (Non-Event)';
        renderForm = inContactBaseClass.HasEditAccess(rca.Id,UserInfo.getUserId());
        
        boolean isP1P2;
        if(new Set<string>{'P1','P2'}.contains(rca.Event__r.Priority)) isP1P2 = true; else isP1P2 = false;
        
        if(renderForm)
        {
            c = [SELECT EventCommander__c, NonEvent__c, InternalEvent__c FROM Case WHERE ID = :rca.Event__c];
            URLForPage = ApexPages.currentPage().getHeaders().get('Host');
            objectID =  controller.getId();  
            
            if((c.NonEvent__c || c.InternalEvent__c || !isP1P2) && rca.CloseDate__c == null)
            {
                renderCloseNonEvent = true;
                
                if(c.InternalEvent__c)
                {
                    closeButtonText = 'Close (Internal Event)';
                }
                else if(!isP1P2)
                {
                    closeButtonText = 'Close (' + rca.Event__r.Priority + ')';
                }
            }
            else
            {
                renderCloseNonEvent = false;
            }
            
            if(rca.RFEApproved__c && !rca.RFEPublished__c && !c.NonEvent__c && !c.InternalEvent__c && isP1P2)
            {
                renderPublishButton = true;
            }
            else
            {
                renderPublishButton = false;
            }
            
            if(string.isNotBlank(rca.RFECreator__c) && !renderPublishButton && !rca.RFEDraftCompleted__c && !rca.RFEApproved__c && !c.NonEvent__c && !c.InternalEvent__c && isP1P2 && rca.OwnerId == UserInfo.getUserId()) 
            {renderSubmitButton = true;}
            else
            {renderSubmitButton = false;}
            
            
            closed = true;
            if(rca.CloseDate__c == null)
            {
                closed = false;
            }
            
            renderEventSummaryButton = !rca.EventSummaryCompleted__c;
            //renderSubmitButton = true;
        }
    }
    
    public void OpenRCA()
    {
         
        rca.RFEPublished__c = false;
        rca.RFEPublishedDateTime__c = null;
        rca.Status__c = 'Being Worked';
        rca.CloseDate__c = null;
        
        update rca;
        
        c.RFEPublished__c = false;
        update c;
        
    }
    
    public void Publish()
    {
        Account[] accounts = new Account[]{};
        Set<Id> csms = new Set<Id>();
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        accounts = [SELECT Id, CSM__c FROM Account WHERE Id IN(SELECT AccountId FROM Case WHERE ParentId = :c.Id)];
    
        if(!accounts.isEmpty())
        {
            for(Account a:accounts)
            {
                if(a.CSM__c != null)
                {
                    csms.add(a.CSM__c);
                }
            }
        }
    
        rca.RFEPublished__c = true;
        rca.RFEPublishedDateTime__c = system.now();
        rca.Status__c = 'RFE Posted (Closed)';
        rca.CloseDate__c = system.now();
        
        update rca;
        
        
        
        if(!csms.isEmpty())
        {
            Id templateId = [SELECT Id FROM EmailTemplate WHERE Name = 'RFE Published CSM Notification' Limit 1].Id;
            
            for(Id csm:csms)
            {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setTargetObjectId(csm);
                mail.setTemplateId(templateId);
                mail.setWhatId(c.Id);
                mail.setSaveAsActivity(false);
                
                emails.add(mail);
            }
            
            Messaging.sendEmail( emails );
        }
    }
    
    public void Submit()
    {
        // Create an approval request for the rca
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setObjectId(rca.id);
        
        // Submit the approval request for the rca
        Approval.ProcessResult result = Approval.process(req1);
    }
    
    public void Blank()
    {
    
    }
    
    public PageReference EditRFE()
    {
        PageReference rfe = new PageReference('/apex/RCARFEPage');
        rfe.SetRedirect(true);
        
        return rfe;
    }
    
    public void CloseNonEvent()
    {
    
        
        rca.Status__c = 'Non-Event (Closed)';
        rca.CloseDate__c = system.now();
        
        update rca;
    }
    
}