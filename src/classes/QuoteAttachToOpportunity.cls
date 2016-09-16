public with sharing class QuoteAttachToOpportunity {
// Constructor - this only really matters if the autoRun function doesn't work right
    private final WfoPremiseQuote__c q;
    public QuoteAttachToOpportunity(ApexPages.StandardController stdController) {
        this.q = (WfoPremiseQuote__c)stdController.getRecord();
    }
 
    // Code we will invoke on page load.
    public PageReference autoRun() {
 
        String theId = ApexPages.currentPage().getParameters().get('id');
     String theType = ApexPages.currentPage().getParameters().get('quotetype');
        if (theId == null) {
            // Display the Visualforce page's content if no Id is passed over
            return null;
        }
 
        for (WfoPremiseQuote__c q:[select id,Name,opportunity__c from WfoPremiseQuote__c where id =:theId]) {
            // Do all the dirty work we need the code to do
    
          /* Get the page definition */
          PageReference pdfPage_c = Page.quotePDFwPSQv2;
          PageReference pdfPage_p = Page.quotePDFwPSQv2;
          pdfPage_c.getParameters().put('id',theId);
      pdfPage_c.getParameters().put('quotetype','Customer');
      pdfPage_p.getParameters().put('id',theId);
      pdfPage_p.getParameters().put('quotetype','Partner');
      
            /* set the quote id on the page definition */
          //pdfPage.getParameters().put('id',q.id);
         
 

          Opportunity op       = [select id from opportunity 
                                where id = :q.opportunity__c];
                                
            op.Final_Quote__c = q.Id;
            update op;

          /* generate the pdf blob CUSTOMER*/
          Blob pdfBlob_c = pdfPage_c.getContent();
        
          /* create the attachment against the quote */
            Attachment a_c = new Attachment(parentId = op.id, name='autoattach_'+'Customer'+'_'+q.Name + '.pdf', body = pdfBlob_c);
        
          /* insert the attachment */
            insert a_c;
            
            /* generate the pdf blob CUSTOMER*/
          Blob pdfBlob_p = pdfPage_p.getContent();
        
          /* create the attachment against the quote */
            Attachment a_p = new Attachment(parentId = op.id, name='autoattach_'+'Partner'+'_'+q.Name + '.pdf', body = pdfBlob_p);
        
          /* insert the attachment */
            insert a_p;
       
        }
 
        // Redirect the user back to the original page
        PageReference pageRef = new PageReference('/' + theId);
        pageRef.setRedirect(true);
        return pageRef;
 
    }
}