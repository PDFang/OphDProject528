public class BigMachinesNewQuoteController {
    
    private class QuoteCreationException extends Exception {}
    
    private Boolean bmUsesSSL;
 
    // for Visualforce pages
    private String bmCreateURL = '';
    private String bmSubtitle = '';
    
    // object IDs
    private ID bmOpportunityId;
    private ID bmAccountId;
    private String bmTransaction;

    public BigMachinesNewQuoteController() {
        bmUsesSSL = BigMachinesParameters.usesSSL;
        Opportunity opp = new Opportunity();
        Account act = new Account();
        try {
            bmOpportunityId = ApexPages.currentPage().getParameters().get('oppId');
            if (bmOpportunityId != null) {
                opp = [select AccountId from Opportunity where Id = :bmOpportunityId];
            }
        } catch (Exception e) {
            System.debug('BigMachinesNewQuoteController: Parameter \'oppId\' was specified '
                    + 'but it was either invalid or did not belong to an existing opportunity.');
            throw new QuoteCreationException('Could not find specified opportunity '
                    + 'to which quote should be associated.');
        }
        try {
            bmAccountId = ApexPages.currentPage().getParameters().get('actId');
        } catch (Exception e) {
            System.debug('BigMachinesNewQuoteController: Parameter \'actId\' was specified '
                    + 'but it was invalid.');
            throw new QuoteCreationException('Could not find specified account '
                    + 'to which quote should be associated.');
        }
        if (bmAccountId == null) {
            if (opp.AccountId == null) {
                throw new QuoteCreationException('Could not find an account with which to '
                        + 'associate the quote.');
            } else {
                bmAccountId = opp.AccountId;
            }
        }
        try {
            act = [select Id from Account where Id = :bmAccountId];
        } catch (Exception e) {
            System.debug('BigMachinesNewQuoteController: Account Id did not belong to an '
                    + 'existing account.');
            throw new QuoteCreationException('Could not find account to which quote '
                    + 'should be associated.');
        }
        ID quoteId = null;
        try {
            quoteId = ApexPages.currentPage().getParameters().get('cloneId');
        } catch (Exception e) {
            System.debug('BigMachinesNewQuoteController: Parameter \'cloneId\' was specified '
                    + 'but it was invalid.');
            throw new QuoteCreationException('Could not find specified quote to clone.');
        }
        if (quoteId != null) {
            BigMachines_Quote__c cloneQuote = new BigMachines_Quote__c();
            try {
                cloneQuote = [select Name, BigMachines_Transaction_Id__c 
                              from BigMachines_Quote__c where Id = :quoteId];
            } catch (Exception e) {
                System.debug('BigMachinesNewQuoteController: Parameter \'cloneId\' was specified '
                        + 'but it did not belong to an existing quote.');
                throw new QuoteCreationException('Could not find specified quote to clone.');
            }
            bmSubtitle = 'Clone of ' + cloneQuote.Name;
            bmTransaction = cloneQuote.BigMachines_Transaction_Id__c;
        } else {
            bmSubtitle = 'New ' + Schema.SObjectType.BigMachines_Quote__c.Label;
        }   
        buildURL();
    }
    
    private void buildURL() {
        bmCreateURL = 'http' + ((bmUsesSSL) ? 's' : '') + '://'
                    + BigMachinesParameters.bm_site + '.bigmachines.com/commerce/buyside/';
        if (bmTransaction != null) {
            bmCreateURL += 'copy_processing.jsp?bs_id=' + bmTransaction 
                         + '&action_id=' + BigMachinesParameters.action_id_copy
                         + '&bm_cm_process_id=' + BigMachinesParameters.process_id
                         + '&version_id=' + BigMachinesParameters.version_id;
        } else {
            bmCreateURL += 'document.jsp?formaction=create'
                         + '&process=' + BigMachinesParameters.process_var;
        }
        bmCreateURL += '&bm_url_capture_cookie=' + BigMachinesParameters.bm_site
                     + '&_partnerAccountId=' + bmAccountId;
        if (bmOpportunityId != null) {
            bmCreateURL += '&_partnerOpportunityId=' + bmOpportunityId;
        }
    }
    
    public String getCreateURL() {
        return bmCreateURL;
    }
    
    public String getSubtitle() {
        return bmSubtitle;
    }
   
    static testMethod void testGetCreateURL() {
        Account acct = new Account();
        acct.Name = 'BigMachines test Account for testGetCreateURL';
        insert acct;
        Opportunity opty = new Opportunity();
        opty.Name = 'BigMachines test Opportunity for testGetCreateURL';
        opty.StageName = 'Prospecting';
        opty.CloseDate = Date.today();
        opty.Probability = 25;
    	opty.Partner_Deal__c = 'NO';
    	opty.Project__c = true;
    	opty.Project_Budget__c = true;
    	opty.Project_Owner__c = true;
    	opty.Project_Timeline__c = true;
    	opty.Project_Detail__c = 'blah blah';
    	opty.Project_Owner_Detail__c = 'me';
    	opty.Project_Budget_Detail__c = 1000;
    	opty.Project_Timeline_Detail__c = date.today();
    	opty.Contract_Type__c = 'New Customer';
    	opty.inContact__c = 'YES';
    	opty.inContact_Setup_Fee__c = 1000;
    	opty.inContact_Seats__c = 1;
    	opty.inContact_MRC_Min__c = 1000;
    	opty.inContact_Ports__c = 1;
    	opty.inContact_MRC_Exp__c = 1000;
    	opty.ECHO__c = 'NO';
    	opty.eLearning__c = 'NO';
    	opty.Hiring__c = 'NO';
    	opty.WFM__c = 'NO';
        insert opty;
        BigMachines_Quote__c quote = new BigMachines_Quote__c();
        quote.Name = 'BigMachines test Quote for testGetCreateURL';
        quote.Opportunity__c = opty.id;
        quote.BigMachines_Transaction_Id__c = 'transactionId';
        insert quote;
        BigMachinesNewQuoteController controller = null;

        // error case - no account specified
        ApexPages.currentPage().getParameters().put('oppId', opty.id);
        try {
            controller = new BigMachinesNewQuoteController();
            System.assert(false);
        } catch (Exception e) {}
        
        // success case - create new quote
        opty.AccountId = acct.id;
        update opty;
        try {
            controller = new BigMachinesNewQuoteController();
        } catch (Exception e) {
            System.assert(false);
        }
        controller.bmUsesSSL = true;
        controller.buildURL();
        
        // success case - create clone of quote
        ApexPages.currentPage().getParameters().put('actId', acct.id);
        ApexPages.currentPage().getParameters().put('cloneId', quote.id);
        try {
            controller = new BigMachinesNewQuoteController();
        } catch (Exception e) {
            System.assert(false);
        }
        controller.bmUsesSSL = false;
        controller.buildURL();
        controller.getCreateURL();
        controller.getSubtitle();

        // error case - invalid clone object type
        ApexPages.currentPage().getParameters().put('cloneId', opty.id);
        try {
            controller = new BigMachinesNewQuoteController();
            System.assert(false);
        } catch (Exception e) {}

        // error case - invalid clone id
        ApexPages.currentPage().getParameters().put('cloneId', 'garbage');
        try {
            controller = new BigMachinesNewQuoteController();
            System.assert(false);
        } catch (Exception e) {}

        // error case - invalid account object type
        ApexPages.currentPage().getParameters().put('actId', opty.Id);
        try {
            controller = new BigMachinesNewQuoteController();
            System.assert(false);
        } catch (Exception e) {}
        
        // error case - invalid account id
        ApexPages.currentPage().getParameters().put('actId', 'garbage');
        try {
            controller = new BigMachinesNewQuoteController();
            System.assert(false);
        } catch (Exception e) {}

        // error case - invalid opportunity id
        ApexPages.currentPage().getParameters().put('oppId', 'garbage');
        try {
            controller = new BigMachinesNewQuoteController();
            System.assert(false);
        } catch (Exception e) {}
        
    }
}