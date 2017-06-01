public class FeatureCreateFromProject
{

    private Project__c project;
  
    // setup the controller varialbles here 
    public string selectedArea{get; set;}
    public string selectedTeam{get; set;}    

       
    public FeatureCreateFromProject(ApexPages.StandardController controller) 
    {
        this.project = (Project__c)controller.getRecord();
        
        project = [select Area__c, Team__c from Project__c where Id = :project.id];
        
        selectedArea = project.Area__c;
        selectedTeam = project.Team__c;
    }
    
    
    //get all Teams
    public list<selectOption> getTeam()
    {
          list<selectOption> lstOptions = new list<SelectOption>();   
          Schema.DescribeFieldResult fieldResult =  ISTFSWorkItem__c.Team__c.getDescribe();
          List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            
           for( Schema.PicklistEntry f : ple)
           {
              lstOptions.add(new SelectOption(f.getValue(), f.getLabel()));
           }                
          return lstOptions;
             
    }
    
   //get all Area 
   public list<selectOption> getArea()
    {
      list<selectOption> lstOptions = new list<SelectOption>();   
      Schema.DescribeFieldResult fieldResult =  ISTFSWorkItem__c.Product__c.getDescribe();
      List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
       for( Schema.PicklistEntry f : ple)
       {
          lstOptions.add(new SelectOption(f.getValue(), f.getLabel()));
       }              
      return lstOptions;
        
    }
    
    
    
    
   // call the component controller
    public void save()
    {
        
         string checkId = project.Id;
        
        if(checkId != null)
        {        
            try
            {
                 project.Area__c = selectedArea;
                 project.Team__c = selectedTeam;
                 update project;
            }
            catch(Exception e)
            {
                 ApexPages.Message error = new ApexPages.Message(ApexPages.severity.ERROR, 'ERROR: ' + e.getMessage());
                 ApexPages.addMessage(error);
            }         
            
        }
        
    }
    
    public PageReference callTFS()
    {
         // Call Webservice
         set<string> stProjectId = new set<string>();
        stProjectId.add(project.Id);
        boolean result = ISTFSINTEGRATIONCLASS.CreateTFSItems(stProjectId, 'Project__c');
        if(!result)
        {
            string tfsError = [select TFSError__c from Project__c where Id = :project.Id].TFSError__c;
            ApexPages.Message error = new ApexPages.Message(ApexPages.severity.ERROR, 'ERROR:  there are some error occured. Error - ' + tfsError);
            ApexPages.addMessage(error); 
            return null;
        }
        else
        {
            PageReference pageRef = new PageReference('/' + project.Id);
            pageRef.setRedirect(true);
            return pageRef;
        }
        
        return null;
    }
    
    public PageReference Cancel()
    {
        PageReference pageRef = new PageReference('/' + project.Id);
        pageRef.setRedirect(true);
        return pageRef;
    }    
        

}