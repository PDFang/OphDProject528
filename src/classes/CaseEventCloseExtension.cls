public with sharing class CaseEventCloseExtension 
{
    private final Case c;
    private Case[] childCases;
    public RCA__C rca {get;set;}
    public boolean newRCARendered{public get;private set;}
    public boolean renderComment{get;set;}
    public boolean isPublicComment{get;set;}
    public String comment{get;set;}
    private List<CaseComment> comments;
    public integer numberOfRCAs {get;set;}
    private final List<RecordType> recordTypes;
    private ID selRecordTypeId;
    private String standText;
    public boolean noText{get;set;}
    public Id selectedStandardTextId{get;set;}
    private List<Standard_Text__c> standardTexts;
    private CaseEventClass cec;
    private CaseEventClass.AccountIncident[] acctIncidents;
    private boolean renderPage;

    public CaseEventCloseExtension(ApexPages.StandardController controller) 
    {
        this.c = (Case)controller.getRecord();
        
        if(c.Id == null)
        {
            renderPage = false;
        }
        else
        {
            renderPage = true;
            comments = new List<CaseComment>();
            childCases = [SELECT ID, Reason, Disposition__c, CaseNumber, Subject, Account.Name, Account.CostGuard_Acct__c, Status, KnownIssue__c FROM Case WHERE ParentId = :c.Id];
            numberOfRCAs = [SELECT COUNT() FROM RCA__c WHERE Event__c = :c.Id];
            
            cec = new CaseEventClass(c);
            acctIncidents = cec.AccountIncidentList();
            
            
            if( numberOfRCAs > 0)
            {
                newRCARendered = false;
            }
            else
            {
                newRCARendered = true;
            }
            
            rca = new RCA__c();
            
            //get all Standard Text record types for dropdown
            recordTypes = new List<RecordType>([SELECT Name FROM RecordType WHERE sObjectType = 'Standard_Text__c' ORDER BY Name]);
            
            noText = false;
            renderComment = false;
            isPublicComment = false;
        }
    }
    
    private void MergeFieldUpdate()
    {
        
        
        comment = comment.replace('{Product Impacted}', c.ProductImpacted__c);
        comment= comment.replace('{Platform Impacted}', c.PlatformsImpacted__c.replace(' - inContact',''));
        comment= comment.replace('{Case Number}', c.CaseNumber);
        comment= comment.replace('{Subject}', c.Subject);
        comment= comment.replace('{Description}', c.Description);
    }
    
    public void Save()
    {
        /*if(comment == null || comment == '')
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Public Comment cannot be blank.'));
            return null;
        }*/
    
        c.Status = 'Closed';
        c.NumberOfAccountsImpacted__c = cec.totalSize;
        
                
        if(renderComment && comment != null && comment != '')
        {
            MergeFieldUpdate();
        
            CaseComment cc = new CaseComment();
            cc.ParentId = c.Id;
            cc.CommentBody = comment;
            cc.IsPublished = isPublicComment;
            
            comments.add(cc);
        }
       
        c.IgnoreEventStatusLock__c = true;
        
        try
        {
            update c;
            
            if(!comments.isEmpty())
            {
                insert comments;
            }

            if(newRCARendered)
            {
                rca.Event__c = c.Id;
                insert rca;
            }

            if(!childCases.isEmpty())
            {

        	/* moved to CaseEventClass
            for(Case ic:childCases)
            {
                //don't change status if attached to known issue
                if(ic.KnownIssue__c == NULL)
                {
                    ic.Status = c.Status;
                }

                ic.Disposition__c = c.Disposition__c;
                ic.Reason = c.Reason;
                ic.Issue_Product__c = c.Issue_Product__c;
                ic.Clients__c = c.Clients__c;


            }

            update childCases;
           	*/
                //CaseEventClass.SyncChildCases(c.Id);

                ID jobID = System.enqueueJob(new CaseEventUpdateChildCasesQueueable(c.Id, new Set<Id>()));
            }

            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Record was saved successfully. Pleaes click on Cancel to go back'));
        }
        catch(DmlException ex)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getDmlMessage(0)));
            //return null;
        }
        

        
        //return to case page
        //PageReference casePage = new PageReference('/' + c.Id);
       // casePage.setRedirect(true);
        
      //  return casePage;
    }
    
    public PageReference Cancel()
    {
        //return to case page
        PageReference casePage = new PageReference('/' + c.Id);
        casePage.setRedirect(true);
        
        return casePage;
    }
    
    public String PublicComment
    {
        get{return comment;}
        set{comment = value;}        
    }
    
    public List<Schema.FieldSetMember> RCAFields
    {
        get{return SObjectType.RCA__c.FieldSets.NewRCA.getFields();}
    }
    
    public List<selectOption> RecordTypeOptions
    {
            get 
            {
                    //new list for holding all of the picklist options
                    List<SelectOption> options = new List<SelectOption>();
                    //Add the first option of '- Select Record Type -' in case no values are returned from query below
                    options.add(new selectOption('', '- Select Record Type -'));
                    //Create an Option for each of the Record Types
                    for(RecordType rt : recordTypes)
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
                    if(noText)
                    {
                        //loop though standard text to display the selected results
                        for(Standard_Text__c st : standardTexts)
                        {
                                if(st.Id == selectedStandardTextId)
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
                    standardTexts = new List<Standard_Text__c>([Select Name, StandardText__c From Standard_Text__c WHERE RecordTypeId = :selRecordTypeId ORDER BY Name]);
                    List<SelectOption> options = new List<SelectOption>();
                    //Add the first option of '- Select Standard Text -' in case no values are returned from query below
                    options.add(new selectOption('','- Select Standard Text -'));
                    //Get Standard Text records for Record Type
                    for(Standard_Text__c s : standardTexts)
                    {
                            options.add(new selectOption(s.Id,s.Name));                                     
                    }
                    return options;
            }
            
            
    }
    
    public boolean RenderClosePage
    {
        get{return renderPage;}
    }
    

}