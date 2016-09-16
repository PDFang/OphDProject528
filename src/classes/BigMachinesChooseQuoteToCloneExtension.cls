public class BigMachinesChooseQuoteToCloneExtension {

    private ApexPages.StandardSetController bmStdSetCtrl;    

    private ID bmOpportunityId;
    private String bmOpportunityName;
    private ID bmSelectedQuoteId;

    public BigMachinesChooseQuoteToCloneExtension(ApexPages.StandardSetController stdSetCtrl) {
        bmOpportunityId = ApexPages.currentPage().getParameters().get('oppId');
        bmOpportunityName = [select Name from Opportunity where Id = :bmOpportunityId].Name;
        bmStdSetCtrl = stdSetCtrl;
    }

    public void setSelectedQuoteId(ID quoteId) {
        bmSelectedQuoteId = quoteId;
    }    

    public String getSelectedQuoteId() {
        return bmSelectedQuoteId;
    }

    public String getOppName() {
        return bmOpportunityName;
    }
    
    public ID getOppId() {
        return bmOpportunityId;
    }

    public Integer getStartOfRange() {
        return (bmStdSetCtrl.getPageNumber()-1) * bmStdSetCtrl.getPageSize() + 1;
    }
    
    public Integer getEndOfRange() {
        Integer rangeEnd = bmStdSetCtrl.getPageNumber() * bmStdSetCtrl.getPageSize();
        if (rangeEnd > bmStdSetCtrl.getResultSize()) {
            rangeEnd = bmStdSetCtrl.getResultSize();
        }
        return rangeEnd;
    }

    public PageReference cloneQuote() {
        if (bmSelectedQuoteId != null) {
            return new PageReference('/apex/BM_NewQuote?cloneId=' + bmSelectedQuoteId + '&oppId=' + bmOpportunityId);
        } else {
            return new PageReference('/apex/BM_CloneSelection?oppId=' + bmOpportunityId);
        }
    }

    public PageReference cancel() {
        return new PageReference('/' + bmOpportunityId);
    }

    static testMethod void testGetQuoteListFromOpty() {
        //BigMachinesController controller = new BigMachinesController();
        Opportunity opty = new Opportunity();
        opty.Name = 'BigMachines test Opportunity for testGetQuoteList';
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
        quote.Name = 'BigMachines test quote for testGetQuoteListFromOpty';
        quote.Opportunity__c = opty.id;
        insert quote;
        ApexPages.StandardSetController stdSetCtrl = new ApexPages.StandardSetController([select id from BigMachines_Quote__c limit 1]);
        ApexPages.currentPage().getParameters().put('oppId', opty.id);
        BigMachinesChooseQuoteToCloneExtension controller = new BigMachinesChooseQuoteToCloneExtension(stdSetCtrl);
        controller.getOppName();
        controller.getOppId();
        controller.getStartOfRange();
        controller.getEndOfRange();
        controller.cloneQuote();
        controller.setSelectedQuoteId(quote.id);
        controller.getSelectedQuoteId();
        controller.cloneQuote();
        controller.cancel();
    }

}