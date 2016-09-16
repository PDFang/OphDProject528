public class ProjectReassignExtension {

    
    private Project__c p;
    public string commentText{get;set;}

    public ProjectReassignExtension(ApexPages.StandardController controller) 
    {
        p = (Project__c)controller.getRecord();
    }
    
    public pageReference Save()
    {
        update p;
        
        //add comment if text greater than 0 length
        if(commentText.length()>0)
        {
            ProjectComment__c pc = new ProjectComment__c();
            pc.Project__c = p.Id;
            pc.Comment__c = commentText;
            
            insert pc;
        }
        
        //return to project
        PageReference proj = new PageReference('/' + p.Id);
        proj.setRedirect(false);
    
        return proj;
    }
    
    public pageReference Cancel()
    {
        //return to project
        PageReference proj = new PageReference('/' + p.Id);
        proj.setRedirect(false);
    
        return proj;
    
    }
    
    public void AssignCurrentUser()
    {
        p.OwnerId = UserInfo.getUserId();
    
    }

}