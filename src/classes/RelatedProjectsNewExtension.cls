public class RelatedProjectsNewExtension 
{
    private final RelatedProject__c rp;

    public RelatedProjectsNewExtension(ApexPages.StandardController controller) 
    {
        this.rp = (RelatedProject__c)controller.getRecord();
        rp.ParentProject__c = ApexPages.CurrentPage().getParameters().get('proj');
    }
    
    public PageReference Save()
    {
        insert rp;
        
        //return to project page
        PageReference projectPage = new PageReference('/' + rp.ParentProject__c);
        projectPage.setRedirect(false);
        
        return projectPage;
    
    }
    
    public PageReference Cancel()
    {
       
        //return to project page
        PageReference projectPage = new PageReference('/' + rp.ParentProject__c);
        projectPage.setRedirect(false);
        
        return projectPage;
    
    }
    

}