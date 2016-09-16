public class PSProjectQuoteProductSelectExtension 
{

    private Project__c p;
    private QuoteProductProject__c[] qppList;
    private cQuoteProduct[] qplist;

    public PSProjectQuoteProductSelectExtension(ApexPages.StandardController controller) 
    {
        this.p = (Project__c)controller.getRecord();
        
        Set<Id> qpSet = new Set<Id>();               
        qplist = new cQuoteProduct[]{};
        for(Quote_Product__c qp:[SELECT Id, Name, Line_Description__c, Total_Price__c, (SELECT ID, QuoteProduct__c, Project__c, PercentAllocation__c FROM Quote_Product_Projects__r) FROM Quote_Product__c WHERE Product__r.PriceType__c = 'One Time' AND Product__r.Family = 'Software' AND BigMachines_Quote__r.Is_Primary__c = true AND BigMachines_Quote__r.Opportunity__c = :p.Opportunity__c])
        {
            qplist.add(new cQuoteProduct(qp,p.Id));
            qpSet.add(qp.Id);
        }
        

        qppList = new List<QuoteProductProject__c>();
        qppList = [SELECT ID, QuoteProduct__c, Project__c, PercentAllocation__c FROM QuoteProductProject__c WHERE QuoteProduct__c IN :qpSet];
        
    }
    
    public cQuoteProduct[] QuoteProducts
    {
        get
        {
            return qplist;
        }
        set
        {
            qplist = value;
        }
    }
    
    public PageReference Save()
    {
        decimal revenue = 0;
    
        List<Quote_Product__c> updateList = new List<Quote_Product__c>();
        List<QuoteProductProject__c> qppUpsertList = new List<QuoteProductProject__c>();
        List<QuoteProductProject__c> qppDeleteList = new List<QuoteProductProject__c>();
        
        for(cQuoteProduct cqp:qplist)
        {
            if(cqp.percentAllocation > 100)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Cannot have over 100% allocation.'));
                return null;
            }
        
            if(cqp.qp.Quote_Product_Projects__r.isEmpty())
            {
                if(cqp.selected)
                {
                    QuoteProductProject__c qpp = new QuoteProductProject__c();
                    qpp.QuoteProduct__c = cqp.qp.Id;
                    qpp.Project__c = p.Id;
                    qpp.PercentAllocation__c = cqp.percentAllocation;
                    
                    qppUpsertList.add(qpp);
                    
                    revenue = revenue + (cqp.qp.Total_Price__c * (cqp.percentAllocation/100));
                }
            }
            else
            {
                decimal paTotal = 0;
                boolean existing = false;
            
                for(QuoteProductProject__c qpl:cqp.qp.Quote_Product_Projects__r)
                {
                                        
                    if(cqp.selected && qpl.Project__c == p.Id)
                    {
                        qpl.PercentAllocation__c = cqp.percentAllocation;
                        revenue = revenue + (cqp.qp.Total_Price__c * (cqp.percentAllocation/100));
                        qppUpsertList.add(qpl);
                        
                        existing = true;
                        
                        paTotal = paTotal + qpl.PercentAllocation__c;
                    }
                    else if(!cqp.selected && qpl.Project__c == p.Id)
                    {
                        qppDeleteList.add(qpl);
                    }
                    else
                    {
                        paTotal = paTotal + qpl.PercentAllocation__c;
                    }
                }
                
                if(cqp.selected && !existing)
                {
                    QuoteProductProject__c qpp = new QuoteProductProject__c();
                    qpp.QuoteProduct__c = cqp.qp.Id;
                    qpp.Project__c = p.Id;
                    qpp.PercentAllocation__c = cqp.percentAllocation;
                    
                    qppUpsertList.add(qpp);
                    
                    revenue = revenue + (cqp.qp.Total_Price__c * (cqp.percentAllocation/100));
                    paTotal = paTotal + cqp.percentAllocation;
                }
                
                if(paTotal > 100)
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Cannot have over 100% allocation.'));
                    return null;
                }
            }
        }
        
        if(!qppUpsertList.isEmpty())
        {
            upsert qppUpsertList;
        }
        
        if(!qppDeleteList.isEmpty())
        {
            delete qppDeleteList;
        }
        
        p.TotalRevenue__c = revenue;
        
        update p;
        
        PageReference projPage = new PageReference('/' + p.Id);
        projPage.setRedirect(true);
        
        return projPage;
    }
    
    
    //wrapper class for the list
    public class cQuoteProduct
    {
        public Quote_Product__c qp{get;set;}
        public Decimal percentAllocation {get;set;}
        public Boolean selected{get;set;}
        public Boolean inUse{get;set;}
        
        public cQuoteProduct(Quote_Product__c quoteProd, ID projId)
        {
            Decimal otherPercentAll = 0;
            qp = quoteProd;
            inUse = false;
            selected = false;
            percentAllocation = 100;
            
            
            for(QuoteProductProject__c qpp:quoteProd.Quote_Product_Projects__r)
            {
                if(qpp.Project__c == projId)
                {
                    selected = true;
                    percentAllocation = qpp.PercentAllocation__c;
                }
                else
                {
                    otherPercentAll = otherPercentAll + qpp.PercentAllocation__c;
                }
            }
            
            if(otherPercentAll > 0 && percentAllocation == 100)
            {
                percentAllocation = percentAllocation - otherPercentAll;
            }
        }
    }
    
    /*
    static testMethod void testPSProjectQuote() {
        Opportunity opty = new Opportunity();
        opty.Name = 'BigMachines test for testSyncQuoteWithOpty()';
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

        // BigMachines_Quote__c.ensurePrimary - begin test
        BigMachines_Quote__c[] quotes = new BigMachines_Quote__c[1];
        for (Integer i=0; i<quotes.size(); i++) {
            quotes[i] = new BigMachines_Quote__c();
            quotes[i].Name = 'BigMachines test quote ' + (i+1) + ' for testSyncQuoteWithOpty()';
            quotes[i].Opportunity__c = opty.Id;
            quotes[i].Is_Primary__c = true;
        }
        insert quotes;  
        // BigMachines_Quote__c.ensurePrimary - end test

        Product2[] prod = new Product2[6];
        for (Integer i=0; i<prod.size(); i++) {
            prod[i] = new Product2();
            prod[i].Name = 'BigMachines test proudct ' + i + ' for testSyncQuoteWithOpty()';
            prod[i].IsActive = true;
            prod[i].BigMachines_Part_Number__c = 'BMITest0' + i;
        }
        insert prod;
        
        
        Pricebook2 pbStandard = [select Id from Pricebook2 where IsStandard = true];
        
        PricebookEntry[] pbookEntry = new PricebookEntry[5];
        for (Integer i=0; i<pbookEntry.size(); i++) {
            pbookEntry[i] = new PricebookEntry();
            pbookEntry[i].IsActive = true;
            pbookEntry[i].Pricebook2Id = pbStandard.id; 
            pbookEntry[i].Product2Id = prod[i].id;
            pbookEntry[i].UnitPrice = i;
        }  
        insert pbookEntry;
        

        // BigMachinesQuoting.syncQuoteWithOpty - begin positive test
        Quote_Product__c[] qProd = new Quote_Product__c[5];  
        for (Integer i=0; i<qProd.size(); i++) {
            qProd[i] = new Quote_Product__c();
            qProd[i].Name = 'BMITest0' + i;
            qProd[i].BigMachines_Quote__c = quotes[0].id;
            qProd[i].Sales_Price__c = i;
            qProd[i].Quantity__c = i+1;
        }
        insert qProd;
        
        Project__c p = new Project__c();
        p.Summary__c = 'Test';
        p.ProjectType__c = 'Customer';
        p.RequestType__c = 'New';
        p.Opportunity__c = opty.Id;
        
        insert p;
        
        ApexPages.StandardController proj = new ApexPages.StandardController(p);
        PSProjectQuoteProductSelectExtension projExt = new PSProjectQuoteProductSelectExtension(proj);
        
        List<cQuoteProduct> qpl = projExt.QuoteProducts;
        projExt.Save();
        
    }
    */
}