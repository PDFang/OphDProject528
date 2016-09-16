/* 
 * The purpose of this class is to test the quoteExt class.  The @IsTest annotation
 * excludes this class from the system cache and as such it is not counted against the
 * org code size limit. NOTE: this test and the sample ASSUMES the organization has 
 * opportunity products enabled and does NOT have multi-currency enabled.
 */
@IsTest (SeeAllData=true)
private class quoteExtTest {

    /* This is a basic test which simulates the primary positive case for the 
       save method in the quoteExt class. */
    public static testmethod void basicSaveTest() {

        Opportunity o = quoteExtTest.setupTestOpportunity();
        WfoPremiseQuote__c q = new WfoPremiseQuote__c();

        /* Construct the standard controller for quote. */
        ApexPages.StandardController con = new ApexPages.StandardController(q);

        /* Switch to runtime context */
        //Test.startTest();
        q.Opportunity__c = o.Id;
        

        /* Construct the quoteExt class */
        QuoteExt ext = new QuoteExt(con);
        ext.q = q;
        
        //Test.

        /* Call save on the ext */
       // PageReference result = 
        
        //ext.save();

        /* Switch back to test context */
        //Test.stopTest();

        /* Verify the navigation outcome is as expected */
        //System.assertEquals(result.getUrl(), con.view().getUrl());

        /* Verify the oppty amount is equivalent to the quote amount */
        //Decimal opportunityAmount = [select amount from opportunity where id = :o.id].amount;
        //Decimal quoteAmount       = [select total_price__c from quote__c where id = :con.getId()].total_price__c;        
        //System.assertEquals(opportunityAmount, quoteAmount);

    }

    /* This is a basic test which simulates the primary positive case for the 
       attachQuote method in the quoteExt class. */
    public static testmethod void basicAttachTest() {
        Opportunity o = quoteExtTest.setupTestOpportunity();

        /* Construct the standard controller for quote. */
        
        //quote__c qc = new quote__c(Id = 'a0P70000002pt0qEAA');
        WfoPremiseQuote__c qc = new WfoPremiseQuote__c();
        qc.Opportunity__c = o.Id;
        insert qc;

    
    
        ApexPages.StandardController con = new ApexPages.StandardController(qc);
     /* Switch to runtime context */
        Test.startTest();
    

        /* Construct the quoteExt class */
        QuoteExt ext = new QuoteExt(con);
        
    /* Set the extension quote object using the id on the controller. */
    
    
        ext.q = qc; 

        /* Call save on the ext */
        ext.save();       
        
    



        

       

        /* Simulate the button invocation of the attachQuote action method 
           on the extension. */
        PageReference result = ext.attachQuote();

         /* Switch back to test context */
        Test.stopTest();

        /* Verify the navigation outcome is as expected */
        //System.assertEquals(result.getUrl(), con.view().getUrl());

        /* Verify the attachment was created. */
       //System.assert([select name from attachment where parentid = :con.getId()].name != null);
    }

    /* This setup method will create an opportunity with line items and a primary
       contact role for use in various tests. */
    private static Opportunity setupTestOpportunity() {

        /* Create an account */
        Account a = new Account();
        a.name    = 'TEST';
        Database.insert(a);

        /* Get the standard pricebook. There must be a standard pricebook already 
           in the target org.  */
        Pricebook2 pb = [select name, isactive from Pricebook2 where IsStandard = true limit 1];

        if(!pb.isactive) {
            pb.isactive = true;
            Database.update(pb);
        }

        /* Get a valid stage name */
        OpportunityStage stage = [select MasterLabel from OpportunityStage limit 1];
        Id oppRecordTypeId = inContactBaseClass.SelectRecordTypeIDByName('WFO Premise', 'Opportunity');

        /* Setup a basic opportunity */
        Opportunity o  = new Opportunity();
        o.Name         = 'TEST';
        o.AccountId    = a.id;
        o.CloseDate    = Date.today();
        o.StageName    = stage.masterlabel;
        o.RecordTypeId = oppRecordTypeId;
        o.Pricebook2Id = pb.id;
       // o.PartnerAccountId = '0017000000LIyE6';

        /* Create the opportunity */
        Database.insert(o);
        
        
       // Partner op = new Partner();
        //op. = '0017000000LIyE6';
       // op.OpportunityId = o.Id;
       // op.IsPrimary = true;
       // insert op;

        /* Create a contact */
        Contact c   = new Contact();
        c.lastname  = 'LASTNAME';
        c.firstname = 'FIRSTNAME';

        Database.insert(c);

        /* Create the opportunity contact role */
        OpportunityContactRole r = new OpportunityContactRole();
        r.ContactId     = c.id;
        r.OpportunityId = o.id;
        r.IsPrimary     = true;
        r.role          = 'ROLE';

        Database.insert(r);

      
          /* Create a product2 */
        Product2 p = new Product2();
        p.Name     = 'TEST';
        p.ProductCode ='AMC-18';    
        p.Category__c = 'Maintenance';  
        Database.insert(p);
        
        
        Product2 p1 = new Product2();
        p1.Name     = 'IN TEST';
        p1.ProductCode ='';  
        p1.Category__c ='Integration';    
        Database.insert(p1);
        
        Product2 p2 = new Product2();
        p2.Name     = 'cc:Voice TEST';
        p2.ProductCode =''; 
        p2.Category__c = 'Software';     
        Database.insert(p2);
        
        Product2 p3 = new Product2();
        p3.Name     = 'cc:Integration Test';
        p3.ProductCode =''; 
        p3.Category__c = 'Integration';
        Database.insert(p3);
         
        Product2 p4 = new Product2();
        p4.Name     = 'Hardware Test';
        p4.ProductCode =''; 
        p4.Category__c = 'Hardware';
        Database.insert(p4); 

        /* Create a pricebook entry. */
        PricebookEntry pbe = new PricebookEntry();
        pbe.Pricebook2Id = pb.id;
        pbe.Product2Id   = p.id;
        pbe.IsActive     = true;
        pbe.UnitPrice    = 1;
        Database.insert(pbe);
        
        PricebookEntry pbe1 = new PricebookEntry();
        pbe1.Pricebook2Id = pb.id;
        pbe1.Product2Id   = p1.id;
        pbe1.IsActive     = true;
        pbe1.UnitPrice    = 1;
        Database.insert(pbe1);
        
        PricebookEntry pbe2 = new PricebookEntry();
        pbe2.Pricebook2Id = pb.id;
        pbe2.Product2Id   = p2.id;
        pbe2.IsActive     = true;
        pbe2.UnitPrice    = 1;
        Database.insert(pbe2);
        
        PricebookEntry pbe3 = new PricebookEntry();
        pbe3.Pricebook2Id = pb.id;
        pbe3.Product2Id   = p3.id;
        pbe3.IsActive     = true;
        pbe3.UnitPrice    = 1;
        Database.insert(pbe3);
        
        PricebookEntry pbe4 = new PricebookEntry();
        pbe4.Pricebook2Id = pb.id;
        pbe4.Product2Id   = p4.id;
        pbe4.IsActive     = true;
        pbe4.UnitPrice    = 1;
        Database.insert(pbe4);

        /* Create a line item */
        OpportunityLineItem i = new OpportunityLineItem();
        i.opportunityId       = o.id;
        i.pricebookentryid    = pbe.id;
        i.quantity            = 1;
        i.unitprice           = 1;
        i.Discount__c    =20;
        Database.insert(i);
        
        OpportunityLineItem i1 = new OpportunityLineItem();
        i1.opportunityId       = o.id;
        i1.pricebookentryid    = pbe1.id;
        i1.quantity            = 1;
        i1.unitprice           = 1;
        i1.Discount__c    =20;
        Database.insert(i1);
        
        OpportunityLineItem i2 = new OpportunityLineItem();
        i2.opportunityId       = o.id;
        i2.pricebookentryid    = pbe2.id;
        i2.quantity            = 1;
        i2.unitprice           = 1;
        i2.Discount__c    =20;
        Database.insert(i2);
        
        OpportunityLineItem i3 = new OpportunityLineItem();
        i3.opportunityId       = o.id;
        i3.pricebookentryid    = pbe3.id;
        i3.quantity            = 1;
        i3.unitprice           = 1;
        i3.Discount__c    =20;
        Database.insert(i3);
        
        
        OpportunityLineItem i4 = new OpportunityLineItem();
        i4.opportunityId       = o.id;
        i4.pricebookentryid    = pbe4.id;
        i4.quantity            = 1;
        i4.unitprice           = 1;
        i4.Discount__c    =20;
        Database.insert(i4);

        /* Set up the opportunity with the related records */
        r.Contact        = c;
        r.Opportunity    = o;
        o.Account        = a;
        i.Opportunity    = o;
        pbe.Product2     = p;
        pbe.Pricebook2   = pb;
        i.PricebookEntry = pbe;

        /* Set the request parameter that the constructor for quoteExt is expecting */
        PageReference pref = Page.quoteNew;
        pref.getParameters().put('oppid',o.id);
        Test.setCurrentPage(pref);

        return o;
    }
}