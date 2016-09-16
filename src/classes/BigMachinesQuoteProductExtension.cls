public class BigMachinesQuoteProductExtension {

    // URLs for Visualforce pages
    private String bmRedirectURL = '';
    
    private Quote_Product__c bmQuoteProd;

    public BigMachinesQuoteProductExtension(ApexPages.StandardController stdCtrl) {
        bmQuoteProd = (Quote_Product__c)stdCtrl.getRecord();
        bmRedirectURL = '/apex/BM_EditQuote?id=' + bmQuoteProd.BigMachines_Quote__c;
    }

    public String getRedirectURL() {
        return bmRedirectURL;
    }

    static testMethod void testQuoteProdExt() {
        BigMachines_Quote__c quote = new BigMachines_Quote__c();
        quote.Name = 'BigMachines test quote for testQuoteProdExt';
        insert quote;
        Quote_Product__c qProd = new Quote_Product__c();
        qProd.Name = 'BigMachines test quote product for testQuoteProdExt';
        qProd.BigMachines_Quote__c = quote.id;
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(qProd);
        BigMachinesQuoteProductExtension controller = new BigMachinesQuoteProductExtension(stdCtrl);
        controller.getRedirectURL();
    }

    
}