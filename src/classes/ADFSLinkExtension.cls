public class ADFSLinkExtension {
        
        private final Contact ct;

    public ADFSLinkExtension(ApexPages.StandardController controller) 
    {
                this.ct = (Contact)controller.getRecord();
                BuildURL();
    }
    
    private void BuildURL()
    {
        if(ct.ADFSGuid__c!=null)
        {
                //Get the URL from the static configuration file
                string url = InContactConfiguration.ADFSContactLink;
                url = url.replace('{AccountNumber}', EncodingUtil.urlEncode(ct.CostGuardAcct__c ,'UTF-8'));
                url = url.replace('{Guid}', EncodingUtil.urlEncode(ct.ADFSGuid__c ,'UTF-8'));
                ADFSUrl = url;
                DisplayText = 'Manage Service Site User'; 
                
                string impURL = InContactConfiguration.ADFSImpersonateContactLink;
                impURL = impURL.replace('{Guid}', EncodingUtil.urlEncode(ct.ADFSGuid__c,'UTF-8'));
                ImpersonateURL = impURL;
                ImpersonateText = 'Impersonate Service Site User';
        }
        else
        {
                //Get the URL from the static configuration file
                string url = InContactConfiguration.ADFSCreateContactLink;
                url = url.replace('{ContactId}', EncodingUtil.urlEncode(ct.Id ,'UTF-8'));
                ADFSUrl = url;
                DisplayText = 'Create Service Site User'; 
                
                ImpersonateURL = '';
                ImpersonateText = '';
        }
    }
    
    public string ADFSUrl { get; private set; }
    
    public string DisplayText { get; private set; }
    
    public string ImpersonateURL { get; private set; }
    
    public string ImpersonateText { get; private set; }
    

}