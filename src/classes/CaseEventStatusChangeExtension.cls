public with sharing class CaseEventStatusChangeExtension
{

    private final Case c;
    private String comment { get; set; }
    private List<CaseComment> comments;
    private Case[] childCases;
    private Map<String, EventStatus__c> statuses;
    private final List<RecordType> recordTypes;
    private ID selRecordTypeId;
    private String standText;
    public boolean noText { get; set; }
    public boolean publish { get; set; }
    public Id selectedStandardTextId { get; set; }
    private List<Standard_Text__c> standardTexts;
    private Set<string> eventResolutionNotificationPriorities;
    private SiteConfiguration__c siteConfig = new SiteConfiguration__c();
    public Boolean success { get; set; }

    public CaseEventStatusChangeExtension(ApexPages.StandardController controller)
    {
        this.c = (Case) controller.getRecord();
        comments = new List<CaseComment> ();

        if (c.Id != NULL)
        {
            childCases = [SELECT ID, CaseNumber, Subject, Account.Name, Account.CostGuard_Acct__c, Status, KnownIssue__c FROM Case WHERE ParentId = :c.Id];

            //get all Standard Text record types for dropdown
            recordTypes = new List<RecordType> ([SELECT Name FROM RecordType WHERE sObjectType = 'Standard_Text__c' ORDER BY Name]);

            statuses = EventStatus__c.getAll();
            noText = false;
            publish = false;
            success = false;
        }
        
        GetSiteConfig();
        GetEventResolutionPriorities();
        
    }
    
    private void GetSiteConfig()
    {    
        siteConfig = SiteConfiguration__c.getInstance(inContactBaseClass.OrgId15Digit);
    }
    
    private void GetEventResolutionPriorities()
    {
        eventResolutionNotificationPriorities= new Set<string>();
        if(!string.isBlank(siteConfig.EventResolvedPriorities__c))
        {
            eventResolutionNotificationPriorities = new Set<string>(siteConfig.EventResolvedPriorities__c.split('\\;'));
        }
    }

    private void MergeFieldUpdate()
    {


        comment = comment.replace('{Product Impacted}', c.ProductImpacted__c);
        comment = comment.replace('{Platform Impacted}', c.PlatformsImpacted__c.replace(' - inContact', ''));
        comment = comment.replace('{Case Number}', c.CaseNumber);
        comment = comment.replace('{Subject}', c.Subject);
        comment = comment.replace('{Description}', c.Description);
    }

    public void Save()
    {
        if (comment == null || comment == '')
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Public Comment cannot be blank.'));
            return;
        }

        // Ensure that if "other" is selected for the Release then we have a justification filled out
        if (c.Status == 'Resolved' && 
            ((c.Releases__c == 'Other (enter details below)' && c.OtherJustification__c == '') || 
                (c.Releases__c == 'Other (enter details below)' && c.OtherJustification__c == null)))
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must fill in a justification if "Other" is selected for Reason Detail'));
            return;
        }

        MergeFieldUpdate();

        CaseComment cc = new CaseComment();
        cc.ParentId = c.Id;
        cc.CommentBody = comment;
        cc.IsPublished = publish;

        comments.add(cc);

        c.IgnoreEventStatusLock__c = true;

        try
        {
            update c;
            insert comments;
        }
        catch(DmlException ex)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getDmlMessage(0)));
            return;
        }
        System.Debug('*******childcase**********' + childCases);

        if (!childCases.isEmpty())
        {
            //CaseEventClass.SyncChildCases(c.Id);

            ID jobID = System.enqueueJob(new CaseEventUpdateChildCasesQueueable(c.Id, new Set<Id>()));
        }

        success = true;
    }

    public PageReference Cancel()
    {
        //return to case page
        PageReference casePage = new PageReference('/' + c.Id);
        casePage.setRedirect(true);

        return casePage;
    }


    public Case[] ChildCaseList
    {
        get { return childCases; }
    }


    public List<selectOption> EventStatus
    {
        get
        {
            //new list for holding all of the picklist options
            List<SelectOption> options = new List<SelectOption> ();

            //add closed status if already closed
            if (c.Status == 'Closed')
            {
                options.add(new selectOption('Closed', 'Closed'));
            }

            for (String s : statuses.keySet())
            {
                //for all records found - add them to the picklist options
                options.add(new selectOption(s, s));
            }

            options.sort();

            //return the picklist options
            return options;
        }
    }

    public List<selectOption> RecordTypeOptions
    {
        get
        {
            //new list for holding all of the picklist options
            List<SelectOption> options = new List<SelectOption> ();
            //Add the first option of '- Select Record Type -' in case no values are returned from query below
            options.add(new selectOption('', '- Select Record Type -'));
            //Create an Option for each of the Record Types
            for (RecordType rt : recordTypes)
            {
                options.add(new selectOption(rt.Id, rt.Name));
            }
            return options;
        }
    }

    public string SelectedStandardText
    {
        get
        {
            if (noText)
            {
                //loop though standard text to display the selected results
                for (Standard_Text__c st : standardTexts)
                {
                    if (st.Id == selectedStandardTextId)
                    {
                        //in the display replace '\n' with '<br>' to add line breaks
                        comment = st.StandardText__c;
                        return st.StandardText__c; //st.StandardText__c.replace('\n','<br>') ;
                    }
                }
            }

            return comment;

        }
        set
        {
            comment = value;
        }
    }

    public Id SelectedRecordTypeId
    {
        get
        {
            return selRecordTypeId;
        }
        set
        {
            standText = '';
            selRecordTypeId = value;
        }
    }

    public List<selectOption> StandardTextOptions
    {
        get
        {
            standardTexts = new List<Standard_Text__c> ([Select Name, StandardText__c From Standard_Text__c WHERE RecordTypeId = :selRecordTypeId ORDER BY Name]);
            List<SelectOption> options = new List<SelectOption> ();
            //Add the first option of '- Select Standard Text -' in case no values are returned from query below
            options.add(new selectOption('', '- Select Standard Text -'));
            //Get Standard Text records for Record Type
            for (Standard_Text__c s : standardTexts)
            {
                options.add(new selectOption(s.Id, s.Name));
            }
            return options;
        }


    }


    public PageReference RefreshPage()
    {
        PageReference currPage = Page.CaseEventStatusChange;
        currPage.getParameters().put('id', c.id);
        currPage.setRedirect(true);
        return currPage;
    }

    public void clearCasePicklists()
    {
        system.debug('c.Reason__c before==>' + c.Reason__c);
        if(c.Status != 'Resolved')
        {
            c.Reason__c = '';   
        }
        
        
    }
    
    public boolean ShowSendEventResolvedEmail
    {
        get
        {
            if(c.Status == 'Resolved' && !c.EventResolvedEmailRequested__c && !c.InternalEvent__c && (eventResolutionNotificationPriorities == null || !eventResolutionNotificationPriorities.contains(c.Priority)))
            {
                return true;
            }
            else
            {
                return false;
            }
        }
    }
    
    public boolean SetSendEventResovledEmail
    {
        get
        {
            return c.SendNotificationEmail__c;
        }
        set
        {
            c.SendNotificationEmail__c = value;
        }
    }


}