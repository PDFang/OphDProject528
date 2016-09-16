public class SetSaaSServiceContractOnQuote {

    public SetSaaSServiceContractOnQuote(ApexPages.StandardController sc){
        
    }
    
    public PageReference setServiceContractValue(){
        ID qId = ApexPages.currentPage().getParameters().get('id');
        
        // Build page reference and pass on page parameters
        PageReference pr = Page.RecallQuote;
        pr.getParameters().putAll(ApexPages.currentPage().getParameters());
        
        if(qId == null)
            return pr;
        SBQQ__Quote__c q = new SBQQ__Quote__c(Id = qId, Quote_Template__c = 'inContact Saas Proposal Template');
        Update q;
        return pr;
    }
}