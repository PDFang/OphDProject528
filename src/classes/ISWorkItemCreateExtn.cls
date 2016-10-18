public class ISWorkItemCreateExtn {
    public ISTFSWorkItem__c wi {get; set;}
    public string definitionOfDone{get;set;}
    public string details{get;set;}
    public string acceptanceCriteria{get;set;}
    public string recordTyp{get;set;}
    private string pId;
    
    public ISWorkItemCreateExtn(ApexPages.StandardController controller)
    {
        wi = new ISTFSWorkItem__c();
        definitionOfDone = Label.TFS_Definition_Of_Done;
        acceptanceCriteria = Label.TFS_WorkItem_Details;
        pId = ApexPages.currentPage().getParameters().get('CF00N2C000000VDW7_lkid'); 
        if(pId==null)
        {
            pId = wi.Project__c;
        }
        else
        {
            wi.Project__c = pId;
        }
        
        
    }
    
    public List<Schema.FieldSetMember> getFields() 
    {
        return SObjectType.ISTFSWorkItem__c.FieldSets.WorkItemCreateFields.getFields();
    }

    
    
    public List<SelectOption> getRecordTypes()
    {
      list<SelectOption> lstRts = new list<SelectOption>();
      for(RecordType rt : [SELECT Id,Name FROM RecordType WHERE SobjectType='ISTFSWorkItem__c' order by Name desc])
      {
          lstRts.add(new SelectOption(rt.Id, rt.Name));
      }
        
	  return lstRts;
    }
    
    public PageReference save()
    {
        try
        {
          
           if(validateSave())
           {
               wi.Details__c = '<br/>' + acceptanceCriteria  + '<br/><br/><u><b>Definition of Done:</b></u>' + definitionofDone;
               
               wi.RecordTypeId = recordTyp;
               Database.SaveResult sr = database.insert(wi, false);
               if(sr.isSuccess())
               {
                   PageReference workItem = new PageReference('/' + sr.getId());
       			   workItem.setRedirect(false);
                   return workItem;
               }
               else
               {
                   string errorMessage;
                    integer errorNum = 0;
                    for(Database.Error er : sr.getErrors())
                    {
                        errorNum++;
                       errorMessage += 'Error ' + errorNum + '- with message ' +  er.getMessage() + ' with statusCode ' +  er.getStatusCode() ;
                    }
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
              		return null;
               }
           }
        }
        catch(Exception ex)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage() + ' at ' + ex.getLineNumber()));
            return null;
        }
        
        return null;
    }
    
    public PageReference SaveNew()
    {
        try
        {
            wi.Details__c = '<br/>' + acceptanceCriteria  + '<br/><br/><u><b>Definition of Done:</b></u>' + definitionofDone;
               
               wi.RecordTypeId = recordTyp;
               Database.SaveResult sr = database.insert(wi, false);
               if(sr.isSuccess())
               {
                   PageReference workItem = new PageReference('/apex/ISWorkItemCreatePage?CF00N2C000000VDW7_lkid=' + pId);                   
       			   workItem.setRedirect(true);
                   return workItem;
               }
               else
               {
                   string errorMessage;
                    integer errorNum = 0;
                    for(Database.Error er : sr.getErrors())
                    {
                        errorNum++;
                       errorMessage += 'Error ' + errorNum + '- with message ' +  er.getMessage() + ' with statusCode ' +  er.getStatusCode() ;
                    }
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
              		return null;
               }
        }
        catch(Exception ex)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage() + ' at ' + ex.getLineNumber()));
            return null;
        }
        return null;
    }
    
    public boolean validateSave()
    {
        if(definitionOfDone.contains('{'))
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Definition of Done is not completed. Please complete all the merge fields(text within {}).'));
                return false;
            }
            else if(acceptanceCriteria.contains('{'))
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Introduction details box is not completed. Please complete all the merge fields(text within {}).'));
                return false;
            }
            else if(wi.Area__c == null)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Area is a required field'));
                return false;
            }
        
         else
             return true;
    }
    
    
    
    public PageReference cancel()
    {
        if(pId != null)
        {
            
            PageReference proj = new PageReference('/' + pId);
       		proj.setRedirect(false);
            return proj;
        }
        else
        {
           string retURL = ApexPages.currentPage().getParameters().get('retURL'); 
            retURL = retURL == null ? '/aDm/o' : retURL;
            PageReference proj = new PageReference('/' + retURL);
       		proj.setRedirect(false);
            return proj;

        }
    }
    

}