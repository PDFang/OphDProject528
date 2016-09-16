public class RelatedProjectsViewExtension 
{
    private final Project__c p;
    private List<RelatedProject__c> rpChildList;
    private List<RelatedProject__c> rpParentList;
    
    public RelatedProjectsViewExtension(ApexPages.StandardController controller) 
    {
        this.p = (Project__c)controller.getRecord();
        rpParentList = [SELECT Id, ParentProject__r.Name, ParentProject__r.RecordType.Name, ParentProject__r.Summary__c, ParentProject__r.ProjectStatus__c, ParentProject__r.ClosedDate__c FROM RelatedProject__c WHERE ChildProject__c = :p.Id];
        rpChildList = [SELECT Id, ChildProject__r.Name, ChildProject__r.RecordType.Name, ChildProject__r.Summary__c, ChildProject__r.ProjectStatus__c, ChildProject__r.ClosedDate__c FROM RelatedProject__c WHERE ParentProject__c = :p.Id];
    }
    
    public void RemoveLink()
    {
        //get id from table        
        String lProj;    
        String lName;
         
        lProj = ApexPages.currentPage().getParameters().get('lProj');
        lName = ApexPages.currentPage().getParameters().get('lName');
        
        RelatedProject__c rpDelete = new RelatedProject__c();
        rpDelete = [SELECT Id FROM RelatedProject__c WHERE Id = :lProj];
        
        if(lName == 'parent')
        {
            for(integer i=0; i < rpParentList.size(); i++)
            {
                if(rpParentList[i].Id == lProj)
                {
                    rpParentList.remove(i);
                }
            }
        }
        else
        {
            for(integer i=0; i < rpChildList.size(); i++)
            {
                if(rpChildList[i].Id == lProj)
                {
                    rpChildList.remove(i);
                }
            }
        }
        
        delete rpDelete;    
        
        
        
    }
    
    public List<RelatedProject__c> ChildList
    {
        get{return rpChildList;}
    }
    
    public List<RelatedProject__c> ParentList
    {
        get{return rpParentList;}
    }
    
    
    


}