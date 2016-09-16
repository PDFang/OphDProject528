@isTest
public class SetSaaSServiceContractOnQuoteTest {
    static testMethod void testExtension() {
        SBQQ__Quote__c q = new SBQQ__Quote__c(Usage_Rate_Type__c = 'Flat Usage Rates', Flat_Usage_Rates__c ='0.0140');
        Insert q;
        SetSaaSServiceContractOnQuote ext = new SetSaaSServiceContractOnQuote(
            new ApexPages.StandardController(q));
        
        ApexPages.currentPage().getParameters().put('id',q.Id);
        
        PageReference pr = ext.setServiceContractValue();
        // System.assert...
        PageReference prEX = Page.RecallQuote;
        pr.getParameters().put('id',q.Id);
        System.assert(pr.getUrl().contains(prEX.getUrl()), 'Expected '+pr.getUrl() + ' to contain ' +prEx.getUrl());
            
        q = [select Id, Quote_Template__c from SBQQ__Quote__c where Id = :q.Id];
        System.assertEquals('inContact Saas Proposal Template',q.Quote_Template__c);
                
    }
    
    
    static testMethod void testExtensionEmpty() {
        SBQQ__Quote__c q = new SBQQ__Quote__c(Usage_Rate_Type__c = 'Flat Usage Rates', Flat_Usage_Rates__c ='0.0140');
        Insert q;
        SetSaaSServiceContractOnQuote ext = new SetSaaSServiceContractOnQuote(
            new ApexPages.StandardController(q));
        
        PageReference pr = ext.setServiceContractValue();
        // System.assert...
        PageReference prEX = Page.RecallQuote;
        System.assert(pr.getUrl().contains(prEX.getUrl()), 'Expected '+pr.getUrl() + ' to contain ' +prEx.getUrl());
                
    }
}