global class CcrViewExtension 
{
    
    public String releaseValueList{get;set;}
    public string ccrId;
    
    public CcrViewExtension(ApexPages.StandardController controller) {
    
		 ccrId = Apexpages.currentPage().getParameters().get('id');
		releaseValueList = ReleaseValueListfromAction();

    }
    
    public string ReleaseValueListfromAction(){
    	
            string[] caseReleaseVals  = new String[]{};
            try
            {
                caseReleaseVals = TfsAccess.TfsReleaseValues();
            }
            catch(Exception ex)
            {
                caseReleaseVals.add('List Failed to Load');
                inContactBaseClass.SendErrorEmail(ex,ccrId);
            }
            return JSON.serialize(caseReleaseVals);
    }
    
    @RemoteAction
    global static string ReleaseValueList(string ccrId)
    {   
            string[] caseReleaseVals  = new String[]{};
    
            try
            {
                caseReleaseVals = TfsAccess.TfsReleaseValues();
            }
            catch(Exception ex)
            {
                caseReleaseVals.add('List Failed to Load');
                inContactBaseClass.SendErrorEmail(ex,ccrId);
            }
            return JSON.serializePretty(caseReleaseVals);
    }

}