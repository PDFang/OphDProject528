@isTest
private class TestInContactQuoteCalculatorPlugin {
    @isTest static void testQCP() {
        Account a = new Account(name = 'Sample Account');
        insert a; 

        Opportunity o = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = a.Id,
            StageName = 'Closed Won',
            CloseDate = Date.Today()
        );
        insert o;

        SBQQ__Quote__c q = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = o.Id,
            Usage_Rate_Type__c = 'Flat Usage Rates',
            Flat_Usage_Rates__c = '$.0140'
        );
        insert q;

        Product2 p1 = new Product2(
            Name = 'inContact Seat License (per Configured Station)',
            Cadebill_Product_ID__c = '307',
            Core_Seat_License__c = true,
            Family = 'Bundle',
            ProductCode = 'XXXX-1234',
            third_Party_Implementation__c = false
        );
        
        Product2 p2 = new Product2(
            Name = 'Workgroup - Professional Services Implementation',
            Overage_Rate__c = 100,
            Implementation_Seat_Threshold__c = 20,
            Family = 'Bundle',
            ProductCode = 'XXXX-1235',
            third_Party_Implementation__c = true
        );
        insert new List<Product2>{p1,p2};
            
            system.debug(p1);
        system.debug(p2);
            
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry p1Price = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = p1.Id,
            UnitPrice = 100, IsActive = true);
        
        PricebookEntry p2Price = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = p2.Id,
            UnitPrice = 6500, IsActive = true);
        insert new List<PriceBookEntry>{p1Price,p2Price};

        List<SBQQ__QuoteLine__c> allQLs = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c ql1 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = q.Id,
            SBQQ__Product__c = p1.Id,
            Cadebill_Product_ID__c = '307',
            SBQQ__Quantity__c = 400,
            X3rd_Party__c = false
        );
        allQLs.add(ql1);
        
        SBQQ__QuoteLine__c ql2 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = q.Id,
            SBQQ__Product__c = p2.Id,
            SBQQ__Quantity__c = 400,
            Overage_Rate__c = 100,
            Implementation_Seat_Threshold__c = 20,
            Original_Price__c = 6500,
            SBQQ__AdditionalDiscountAmount__c = 500,
            X3rd_Party__c = false
        );
        allQLs.add(ql2);
        
        SBQQ__QuoteLine__c ql3 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = q.Id,
            SBQQ__Product__c = p2.Id,
            SBQQ__Quantity__c = 6500,
            Overage_Rate__c = 100,
            Implementation_Seat_Threshold__c = 20,
            Original_Price__c = 6500,
            SBQQ__Discount__c = 25,
            X3rd_Party__c = false
        );
        allQLs.add(ql3);
        insert allQLs;
        
        List<SBQQ__QuoteLine__c> quoteLinesPostInsert = [SELECT Id FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :q.Id];
        
        InContactQuoteCalculatorPlugin qcp = new InContactQuoteCalculatorPlugin();
    
        qcp.onInit(new List<SBQQ__QuoteLine__c>{ql1,ql2,ql3});
        qcp.onBeforePriceRules(q,new List<SBQQ__QuoteLine__c>{ql1,ql2,ql3});
        qcp.onAfterPriceRules(q,new List<SBQQ__QuoteLine__c>{ql1,ql2,ql3});
        qcp.onBeforeCalculate(q,new List<SBQQ__QuoteLine__c>{ql1,ql2,ql3});
        qcp.onAfterCalculate(q,new List<SBQQ__QuoteLine__c>{ql1,ql2,ql3});
    }
}