@IsTest
private class PSProjectQuoteProductSelectExtensionTest {

    static final String ACCOUNT_TYPE_CUSTOMERS = 'Customers';
    static final String OPPORTUNITY_TYPE_PS = 'GSD PS Requests';
    static final String PROJECT_TYPE_PARENT_PREMISE = 'PS Parent Project - Premise';

    static final Set<String> recordTypeSet = new Set<String>
    {
            ACCOUNT_TYPE_CUSTOMERS,
            OPPORTUNITY_TYPE_PS,
            PROJECT_TYPE_PARENT_PREMISE
    };

    static Map<String, Id> recordTypeMap = null;
    static Account acct = null;
    static List<Product2> productList = null;
    static List<PricebookEntry> pbeList = null;
    static Opportunity opp = null;
    static BigMachines_Quote__c quote = null;
    static List<Quote_Product__c> quoteProdList = null;
    static List<Project__c> projectList = null;

    static testMethod void testExtension() {
        createTestData();
        createQuoteProductProject();
        test.startTest();
        test.setCurrentPage(Page.PSProjectQuoteProductSelect);
        ApexPages.StandardController controller = new ApexPages.StandardController(projectList[0]);
        PSProjectQuoteProductSelectExtension extension = new PSProjectQuoteProductSelectExtension(controller);
        PSProjectQuoteProductSelectExtension.cQuoteProduct[] cQuoteProducts = extension.QuoteProducts;
        system.assertEquals(2, cQuoteProducts.size());

        cQuoteProducts[0].selected = true;
        cQuoteProducts[1].selected = true;
        extension.save();

        cQuoteProducts[0].selected = false;
        cQuoteProducts[1].selected = true;
        extension.save();

        test.stopTest();
    } // end of testExtension()

    static void createTestData()
    {
        recordTypeMap = new Map<String, Id>();
        for(RecordType record : [Select Id, Name from RecordType
        where Name IN :recordTypeSet])
        {
            recordTypeMap.put(record.Name, record.Id);
        }

        createAccount();
        createProductAndPbe();
        createOpportunity();
        createOpportunityProduct();
        createQuote();
        createQuoteProduct();
        createProject();

    }

    static void createAccount()
    {

        acct = new Account(
                Name = 'AssetTriggerHandlerTest Account',
                RecordTypeId = recordTypeMap.get(ACCOUNT_TYPE_CUSTOMERS)
        );
        insert acct;
    }

    static void createProductAndPbe(){

        productList = new List<Product2>();

        Product2 p1 = new Product2();
        p1.Name     = 'AssetTriggerHandlerTest 1';
        p1.ProductCode ='1111';
        p1.Category__c = 'Integration';
        p1.PriceType__c = 'One Time';
        p1.Family = 'Software';
        productList.add(p1);

        Product2 p2 = new Product2();
        p2.Name     = 'AssetTriggerHandlerTest 2';
        p2.ProductCode ='1097';
        p2.Category__c ='Integration';
        p2.PriceType__c = 'One Time';
        p2.Family = 'Software';
        productList.add(p2);

        insert productList;

        pbeList = new List<PricebookEntry>();

        PricebookEntry pbe1 = new PricebookEntry();
        pbe1.Pricebook2Id = Test.getStandardPriceBookId();
        pbe1.Product2Id   = p1.id;
        pbe1.IsActive     = true;
        pbe1.UnitPrice    = 10;
        pbeList.add(pbe1);

        PricebookEntry pbe2 = new PricebookEntry();
        pbe2.Pricebook2Id = Test.getStandardPriceBookId();
        pbe2.Product2Id   = p2.id;
        pbe2.IsActive     = true;
        pbe2.UnitPrice    = 100;
        pbeList.add(pbe2);

        insert pbeList;

    }

    static void createOpportunity(){
        opp = new Opportunity();
        opp.Name = 'AssetTriggerHandlerTest Opp';
        opp.AccountId = acct.Id;
        opp.RecordTypeId = recordTypeMap.get(OPPORTUNITY_TYPE_PS);
        opp.StageName = 'Prospecting';
        opp.CloseDate = Date.today();
        opp.Probability = 25;
        opp.Partner_Deal__c = 'NO';
        opp.Project__c = true;
        opp.Project_Budget__c = true;
        opp.Project_Owner__c = true;
        opp.Project_Timeline__c = true;
        opp.Project_Detail__c = 'blah blah';
        opp.Project_Owner_Detail__c = 'me';
        opp.Project_Budget_Detail__c = 1000;
        opp.Project_Timeline_Detail__c = date.today();
        opp.Contract_Type__c = 'New Customer';
        opp.inContact__c = 'YES';
        opp.inContact_Setup_Fee__c = 1000;
        opp.inContact_Seats__c = 1;
        opp.inContact_MRC_Min__c = 1000;
        opp.inContact_Ports__c = 1;
        opp.inContact_MRC_Exp__c = 1000;
        opp.ECHO__c = 'NO';
        opp.eLearning__c = 'NO';
        opp.Hiring__c = 'NO';
        opp.WFM__c = 'NO';
        insert opp;

    }

    static void createOpportunityProduct(){

        List<OpportunityLineItem> oppItemList = new List<OpportunityLineItem>();
        OpportunityLineItem item1 = new OpportunityLineItem();
        item1.opportunityId = opp.id;
        item1.quantity = 5;
        item1.unitprice = 10;
        item1.Discount__c = 2;
        item1.PricebookEntryId = pbeList[0].Id;
        oppItemList.add(item1);

        OpportunityLineItem item2 = new OpportunityLineItem();
        item2.opportunityId = opp.id;
        item2.quantity = 8;
        item2.unitprice = 100;
        item2.Discount__c = 12;
        item2.PricebookEntryId = pbeList[1].Id;
        oppItemList.add(item2);

        insert oppItemList;

    }
    static void createQuote(){

        quote = new BigMachines_Quote__c();
        quote.Account__c = acct.Id;
        quote.Opportunity__c = opp.id;
        quote.Is_Primary__c = true;
        quote.AdvancePayment__c = 0;

        insert quote;

    }

    static void createQuoteProduct(){

        quoteProdList = new List<Quote_Product__c>();

        Quote_Product__c quoteProd1 = new Quote_Product__c();
        quoteProd1.Name = '89914';
        quoteProd1.Product__c = productList[0].Id;
        quoteProd1.BigMachines_Quote__c = quote.id;
        quoteProd1.Sales_Price__c = 100;
        quoteProd1.Quantity__c = 5;
        quoteProdList.add(quoteProd1);

        Quote_Product__c quoteProd2 = new Quote_Product__c();
        quoteProd2.Name = '77125';
        quoteProd2.Product__c = productList[1].Id;
        quoteProd2.BigMachines_Quote__c = quote.id;
        quoteProd2.Sales_Price__c = 100;
        quoteProd2.Quantity__c = 5;
        quoteProdList.add(quoteProd2);

        insert quoteProdList;

    }

    static void createProject(){

        projectList = new List<Project__c>();
        Project__c project1 = new Project__c();
        project1.RecordTypeId = recordTypeMap.get(PROJECT_TYPE_PARENT_PREMISE);
        project1.Opportunity__c = opp.Id;
        project1.Account__c = acct.Id;
        projectList.add(project1);

        Project__c project2 = new Project__c();
        project2.RecordTypeId = recordTypeMap.get(PROJECT_TYPE_PARENT_PREMISE);
        project2.Opportunity__c = opp.Id;
        project2.Account__c = acct.Id;
        projectList.add(project2);

        insert projectList;

    }

    static void createQuoteProductProject() {

        List<QuoteProductProject__c> qProductProjectList = new List<QuoteProductProject__c>();
        QuoteProductProject__c qProductProject1 = new QuoteProductProject__c();
        qProductProject1.QuoteProduct__c = quoteProdList[0].id;
        qProductProject1.Project__c = projectList[0].Id;
        qProductProject1.PercentAllocation__c = 90;
        qProductProjectList.add(qProductProject1);

        QuoteProductProject__c qProductProject2 = new QuoteProductProject__c();
        qProductProject2.QuoteProduct__c = quoteProdList[0].id;
        qProductProject2.Project__c = projectList[1].Id;
        qProductProject2.PercentAllocation__c = 70;
        qProductProjectList.add(qProductProject2);

        insert qProductProjectList;

    }

}