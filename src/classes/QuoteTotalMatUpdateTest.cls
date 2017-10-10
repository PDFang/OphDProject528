@IsTest 
public class QuoteTotalMatUpdateTest {

    public static void setupData(){
        
       list<Product2> prods = new list<Product2>(); 
       list<SBQQ__QuoteLine__c> quoteLines = new list<SBQQ__QuoteLine__c>(); 
       
        /* Create an account */
        Account a = new Account();
        a.name    = 'TEST';
        Database.insert(a);

        
   /**     Pricebook2 pb = new PriceBook2();
        pb.Name = 'TEST PB';
        pb.IsActive = true;

        insert pb; **/
        
        /* Get a valid stage name */
       
        /* Setup a basic opportunity */
        Opportunity o  = new Opportunity();
        o.Name         = 'TEST';
        o.AccountId    = a.id;
        o.CloseDate    = Date.today();
        o.StageName    = '5-Proposal / Negotiation';       
        o.inContact_MRC_Min__c = 500.00;
        /* Create the opportunity */
        Database.insert(o);
     
        
        //products
        
        
        Product2 p = new Product2();
        p.Name     = 'TEST';
        p.ProductCode ='1234520-000-000-XX';    
        p.Family = 'SOFTWARE MRC PRODUCTS';  
        prods.add(p);
        
        
        Product2 p1 = new Product2();
        p1.Name     = 'IN TEST';
        p1.ProductCode ='';  
        p1.Family ='SOFTWARE USAGE PRODUCTS';    
        prods.add(p1);
            
        // insert products    
        Database.insert(prods);
           
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.SBQQ__Primary__c = true;
        quote.SBQQ__Type__c = 'Quote';
        quote.SBQQ__Opportunity2__c = o.Id;
        quote.Usage_Rate_Type__c = 'Flat Usage Rates'; 
        quote.Flat_Usage_Rates__c = '$.0135';
        insert quote;
   
        // list of quote lines
       
        SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c();
        ql.SBQQ__Product__c = p.Id;
        ql.SBQQ__Existing__c = false;
        ql.SBQQ__NetPrice__c  = 20.00;
        ql.SBQQ__Quantity__c = 5;
        ql.SBQQ__Quote__c = quote.Id;
        quoteLines.add(ql);

        
        SBQQ__QuoteLine__c ql2= new SBQQ__QuoteLine__c();
        ql2.SBQQ__Product__c = p1.Id;
        ql2.SBQQ__Existing__c = false;
        ql2.SBQQ__NetPrice__c  = 30.00;
        ql2.SBQQ__Quantity__c = 5;        
        ql2.SBQQ__Quote__c = quote.Id;
        quoteLines.add(ql2);
        
        // insert lines
        insert quoteLines;
    }
    //// Scenario 1
    public static testmethod void testTotalMatInsert(){
        QuoteTotalMatUpdateTest.setupData();
        test.startTest();        
        Opportunity opp = [select Id, Total_MAT_New__c from Opportunity limit 1];
        system.assertEquals(250.0, opp.Total_MAT_New__c);              
        test.stopTest();       
    }
    
    // Scenario 2
    public static testmethod void testTotalMatAfterUpdate(){
        QuoteTotalMatUpdateTest.setupData();        
        test.startTest();                                         
        SBQQ__QuoteLine__c ql = [select Id, SBQQ__NetPrice__c from SBQQ__QuoteLine__c where SBQQ__NetPrice__c = 20.00 limit 1];
        ql.SBQQ__NetPrice__c = 100.00;
        update ql;
        Opportunity opp = [select Id, Total_MAT_New__c from Opportunity limit 1];
        system.assertEquals(650.0, opp.Total_MAT_New__c);     
        test.stopTest();               
    }
    
    // Scenario 3
    public static testmethod void testTotalMatWithoutSoftware(){
        QuoteTotalMatUpdateTest.setupData();        
        test.startTest();                                         
        
        Opportunity opp = [select Id, Total_MAT_New__c from Opportunity limit 1];
        SBQQ__Quote__c quote2 = new SBQQ__Quote__c();
        quote2.SBQQ__Primary__c = false;
        quote2.SBQQ__Type__c = 'Quote';
        quote2.SBQQ__Opportunity2__c = opp.Id;
        quote2.Usage_Rate_Type__c = 'Flat Usage Rates'; 
        quote2.Flat_Usage_Rates__c = '$.0135';
        insert quote2;        
        
        quote2.SBQQ__Primary__c = true;
        update quote2;
        
        opp = [select Id, Total_MRC_Min__c, Total_MAT_New__c from Opportunity limit 1];
        system.assertEquals(opp.Total_MRC_Min__c, opp.Total_MAT_New__c, 'Total Mat was changed');        
        test.stopTest();               
    }
    
    
}