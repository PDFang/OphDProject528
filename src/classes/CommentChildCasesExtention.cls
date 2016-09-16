public with sharing class CommentChildCasesExtention 
{

	private final Case c;
	private List<Case> childCases;
	public String CommentBodyText {get;set;}
	public boolean IsPublic {get;set;}
	public Integer ChildCaseCount {get;set;}

    public CommentChildCasesExtention(ApexPages.StandardController controller) 
    {
		this.c = (Case)controller.getRecord();
		//do not pull cases if page is not associated to a case ID
		if(c.id != null) 
		{
			childCases = [SELECT Id FROM Case WHERE ParentId = :c.Id];
		}
		//get number of child cases
		ChildCaseCount = childCases.size();
    }
	
	public PageReference SaveComment()
	{
		if(CommentBodyText == '')
		{
			//if the Comment Body is empty then pass and error
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'Must enter a Comment Body'));
			return null;
		} 
		else
		{
			List<CaseComment> caseComments = new List<CaseComment>();
			
			//loop through IDs
			for(Case childCase : childCases)
			{
				//create case comment
				caseComments.add(new CaseComment(ParentId = childCase.Id,CommentBody = CommentBodyText,IsPublished = IsPublic)); 
			}
			insert caseComments; 
			
			//return to the case
			string caseURL = '/' + c.Id;
			return new PageReference(caseURL);
		}
	}	
}