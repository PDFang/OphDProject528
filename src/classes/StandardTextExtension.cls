public class StandardTextExtension 
{
                
        List<CaseComment> cCom;
        private Case uCase;
        private final List<RecordType> recordTypes;
        private ID selRecordTypeId;
        private List<Standard_Text__c> standardTexts;
        private ID selStandardTextId;
        private Integer timeSpentCase;
        private String standText;
        private boolean usestandText;
        private boolean isPublic;
        public boolean statusDetail {get;set;}
        
        public StandardTextExtension(ApexPages.StandardController stdCtrl)
        {
                uCase = (Case)stdCtrl.getRecord();
                //get all Standard Text record types for dropdown
                recordTypes = new List<RecordType>([SELECT Name FROM RecordType WHERE sObjectType = 'Standard_Text__c' ORDER BY Name]);
                //initiate list for standard text
                standardTexts = new List<Standard_Text__c>();
                useStandText = false;
                statusDetail = false;
                //isPublic = false;
        } 
        
        public PageReference CopyStandardText()
        {
                
                
                
                if(standText == null || standText == '')
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Comment detail cannot be blank.'));
                    return null;
                }
                
                uCase.Description = uCase.Description + '\n' + standText;
                
                
                update uCase;
                
                //redirect to Case edit page            
                PageReference casePage = new PageReference('/' + uCase.id + '/e?retURL=%2F' + uCase.Id);
                casePage.setRedirect(false);
        
                        return casePage;
        }
        
        public PageReference AddStandardTextAsCaseComment()
        {
                SaveComment();
            
                
            if(ApexPages.hasMessages())
            {
                return null;
            }
                
                //redirect to Case edit page            
                PageReference caseCommentPage = new PageReference('/' + uCase.Id);
                caseCommentPage.setRedirect(false);
        
                return caseCommentPage;
                        
        }
        
        public PageReference PublisherSave()
        {
            SaveComment();
            timeSpentCase = null;
            standText = null;
            usestandText = false;
            isPublic = false;
            statusDetail = false;
            
            return null;
        }
        
        public void SaveComment()
        {
            //create new case comment
                CaseComment cc = New CaseComment();
                cc.ParentId = uCase.Id;
                
                database.DMLOptions dmo = new database.DMLOptions();
                dmo.EmailHeader.triggerOtherEmail = true;
                cc.setOptions(dmo);
                
                if(timeSpentCase == null)
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Time Spent is Required.'));
                    return;
                }
                
                if(standText == null || standText == '')
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Comment detail cannot be blank.'));
                    return;
                }
                
                if(standText.length() > 4000)
                {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Comment detail is too long. Detail must be 4000 characters or less.'));
                    return;
                }
                
                cc.CommentBody = standText; //st.StandardText__c;
                cc.IsPublished = isPublic;
                
                
                insert cc;
                
                //create worklog activity
                if(timeSpentCase > 0)
                {
                    Task t = new Task();
                    t.ActivityDate = date.today();
                    t.WhatId = uCase.Id;
                    t.WorkDuration__c = timeSpentCase;
                    t.Subject = 'Log Time on Case ' + String.valueof(uCase.CaseNumber);
                    t.Status = 'Completed';
                    t.Type = 'Time Tracking';
                    
                    insert t;
                }
                
                if(statusDetail)
                {
                    uCase.StatusDetails__c = cc.CommentBody;
                    
                    try
                    {
                        update uCase;
                    }
                    catch(Exception ex)
                    {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
                    }
                }
        }
        
        //used to hide buttons until a standard text is selected
        public Boolean ButtonsRendered
        {       
                get
                {
                        boolean render; 
                        //check if standard text is blank.
                        if(SelectedStandardText == '' || SelectedStandardText == null)
                        {
                                 render = false; 
                        }
                        else
                        {
                                render = true;
                        }
                        
                        if(!NoText)
                        {
                            render = true;
                        }
                        
                        return render;
                }
        }
        
        public boolean NoText
        {
            get
            {
                return useStandText;
            }
            set
            {
                useStandText = value;
            }
        }
        
        public boolean IsPublicComment
        {
            get
            {
                return isPublic;
            }
            set
            {
                isPublic = value;
            }
        }

        public string SelectedStandardText
        {
                get
                {
                        if(useStandText)
                        {
                            //loop though standard text to display the selected results
                            for(Standard_Text__c st : standardTexts)
                            {
                                    if(st.Id == selStandardTextId)
                                    {
                                            //in the display replace '\n' with '<br>' to add line breaks
                                            standText = st.StandardText__c;
                                            return st.StandardText__c; //st.StandardText__c.replace('\n','<br>') ;
                                    }
                            }
                         }
                        
                        return standText ;
                        
                }
                set
                {
                   standText = value;
                }
        }
        
        //get and set current record type
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
    
    //get and set the current standard text
    public Id SelectedStandardTextId
    { 
        get
        {
                return selStandardTextId; 
        }
        set
        {
        
                standText = ''; 
                selStandardTextId = value;
             
        }
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
        
        public Integer TimeSpent
        {
            get
            {
                return timeSpentCase;
            }
            set
            {
                timeSpentCase = value;
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
        
        
        
        public List<CaseComment> getCaseComments()
        {
            if(cCom==null) cCom = [SELECT CreatedBy.Name, CreatedDate, CommentBody, IsPublished FROM CaseComment WHERE ParentId = :uCase.Id ORDER BY CreatedDate DESC];
            
            return cCom;
        }
       
        
        
}