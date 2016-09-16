public class BigMachinesQuoting {

    public static void syncQuoteWithOpty(ID quoteId, ID opportunityId) {
        BigMachines_Quote__c[] quotesToUpdate = markOthersAsNonPrimary(quoteId, opportunityId);
        OpportunityLineItem[] oppProdToDelete = getOldOpportunityProducts(opportunityId);

        /*
            To update opportunity with values from the primary quote:
                1) type additional quote fields in "quote" select statement
                2) assign the fields to the opportunity (ie. opportunity.FieldA = quote.FieldB__c) 
        */
        BigMachines_Quote__c quote = [select Name, CustomTerms__c, VPCSApprovalStatus__c, COOApprovalStatus__c, CTOApprovalStatus__c, CFOApprovalStatus__c, CEOApprovalStatus__c, EVPApprovalStatus__c, SVPApprovalStatus__c, RVPApprovalStatus__c, ManagerApprovalStatus__c, ServiceDeliveryApprovalStatus__c, SalesEngineeringApprovalStatus__c, CoGSApprovalStatus__c, CreditApprovalStatus__c, ContractsApprovalStatus__c, PartnerSupportApprovalStatus__c, COGSNotes__c, INTERSTATEOutboundTermICBRate__c, INTERSTATEInboundTollFreeICBRate__c, ServicePlan__c, QuoteStep__c, ICBRateRequired__c, Total__c, Pricebook_Id__c, AdvancePayment__c, PlatinumServicePlan__c, GoldServicePlan__c, SilverServicePlan__c, ServiceAdvantageAddOn__c from BigMachines_Quote__c where Id = :quoteId];
        Opportunity opportunity = [select Name, CustomTerms__c, VPCSApprovalStatus__c, COOApprovalStatus__c, CTOApprovalStatus__c, CFOApprovalStatus__c, CEOApprovalStatus__c, EVPApprovalStatus__c, SVPApprovalStatus__c, RVPApprovalStatus__c, ManagerApprovalStatus__c, ServiceDeliveryApprovalStatus__c, SalesEngineeringApprovalStatus__c, CoGSApprovalStatus__c, CreditApprovalStatus__c, ContractsApprovalStatus__c, PartnerSupportApprovalStatus__c, QuoteStep__c, BigMachinesCOGSNotes__c, INTERSTATEOutboundTermICBRate__c, INTERSTATEInboundTollFreeICBRate__c, ICBRateRequired__c, Pricebook2Id, Prepaid_Amount__c, ServicePlan__c, ServiceAdvantageAddOn__c from Opportunity where Id = :opportunityId];
        opportunity.Amount = quote.Total__c;
		opportunity.Prepaid_Amount__c = quote.AdvancePayment__c;
		opportunity.QuoteStep__c = quote.QuoteStep__c;
		opportunity.ICBRateRequired__c = quote.ICBRateRequired__c;
		opportunity.INTERSTATEInboundTollFreeICBRate__c = quote.INTERSTATEInboundTollFreeICBRate__c;
		opportunity.INTERSTATEOutboundTermICBRate__c = quote.INTERSTATEOutboundTermICBRate__c;
		opportunity.BigMachinesCOGSNotes__c = quote.COGSNotes__c;
		opportunity.ServicePlan__c = quote.ServicePlan__c;
		opportunity.VPCSApprovalStatus__c = quote.VPCSApprovalStatus__c;
		opportunity.COOApprovalStatus__c =  quote.COOApprovalStatus__c;
		opportunity.CTOApprovalStatus__c = quote.CTOApprovalStatus__c;
		opportunity.CFOApprovalStatus__c = quote.CFOApprovalStatus__c;
		opportunity.CEOApprovalStatus__c = quote.CEOApprovalStatus__c;
		opportunity.EVPApprovalStatus__c =  quote.EVPApprovalStatus__c;
		opportunity.SVPApprovalStatus__c = quote.SVPApprovalStatus__c;
		opportunity.RVPApprovalStatus__c = quote.RVPApprovalStatus__c;
		opportunity.ManagerApprovalStatus__c = quote.ManagerApprovalStatus__c;
		opportunity.ServiceDeliveryApprovalStatus__c = quote.ServiceDeliveryApprovalStatus__c;
		opportunity.SalesEngineeringApprovalStatus__c = quote.SalesEngineeringApprovalStatus__c;
		opportunity.CoGSApprovalStatus__c = quote.CoGSApprovalStatus__c;
		opportunity.CreditApprovalStatus__c =  quote.CreditApprovalStatus__c;
		opportunity.ContractsApprovalStatus__c = quote.ContractsApprovalStatus__c;
		opportunity.PartnerSupportApprovalStatus__c = quote.PartnerSupportApprovalStatus__c;
				
		if(quote.ServiceAdvantageAddOn__c == 'true')
		{
			opportunity.ServiceAdvantageAddOn__c = True;
		}
		else
		{ 
			opportunity.ServiceAdvantageAddOn__c = False;
		}
		
		if(quote.CustomTerms__c == 'Yes') 
		{
			opportunity.CustomTerms__c = True;
		}
		else
		{ 
			opportunity.CustomTerms__c = False;
		}
		
        // get opportunity pricebook, if pricebook is not specified use standard pricebook        
        ID optyPricebookId = opportunity.Pricebook2Id;
        if (optyPricebookId == null) {
            optyPricebookId = [select Id from Pricebook2 where IsStandard = true].Id;
        }

        // get quote pricebook, pricebook ID on quote is stored as a String
        // if no pricebook Id is specified on quote then just use opportunity pricebook
        // if pricebook Id is specified on quote then it must match opportunity
        ID quotePricebookId = null;
        try {
            quotePricebookId = (ID)quote.Pricebook_Id__c;
        } catch (Exception e) {} 
        if (quotePricebookId != null && quotePricebookId != optyPricebookId) {
            quote.Is_Primary__c = false;
            update quote;
            throw new QuoteSyncException('Could not sync quote [' + quote.Name + '] with opportunity ['
                    + opportunity.Name + '] because they are using different pricebooks.  '
                    + 'In order to sync this quote and opportunity, first change the pricebook on one '
                    + 'of the objects to match the other and then try again.');
        }    

        /*
            To update opportunity products with additional fields from quote products
                1) type additional quote product fields in "quoteProds" select statement
                2) include additional assignments in OpportunityLineItem constructor below
        */
        //OpportunityLineItem[] oppProdToCreate = new OpportunityLineItem[200];
        List<OpportunityLineItem> oppProdToCreate = new List<OpportunityLineItem>();
        Quote_Product__c[] quoteProds = [select Id, Name, Product__c, Quantity__c, Sales_Price__c 
                                         from Quote_Product__c where BigMachines_Quote__c = :quoteId];
        if (quoteProds.size() > 0) {
            Set<ID> productIdSet = new Set<ID>();
            for (Quote_Product__c qProd : quoteProds) {
                productIdSet.add(qProd.Product__c);
            }
            PricebookEntry[] pbEntries = [select Id, Product2Id from PricebookEntry 
                                          where Pricebook2Id = :optyPricebookId and Product2Id in :productIdSet];
            if (productIdSet.size() != pbEntries.size()) {
                quote.Is_Primary__c = false;
                update quote;
                if (productIdSet.size() > pbEntries.size()) {
                    throw new QuoteSyncException('Could not sync quote [' + quote.Name + '] with opportunity ['
                            + opportunity.Name + '] because at least one product did not have a corresponding '
                            + 'pricebook entry in the opportunity\'s pricebook.  This can be corrected by '
                            + 'manually adding the pricebook entry in Salesforce or by having a BigMachines '
                            + 'administrator run a part sync.');
                } else {
                    throw new QuoteSyncException('Could not sync quote [' + quote.Name + '] with opportunity ['
                            + opportunity.Name + '] because there are more pricebook entries than products.  '
                            + 'To correct this, the Apex code that deals with the BigMachines integration '
                            + 'probably needs to be updated to select the correct currency.');
                }
            }
            Map<ID,ID> prodMap = new Map<ID,ID>();
            for (PricebookEntry pbEntry : pbEntries) {
                prodMap.put(pbEntry.Product2Id, pbEntry.Id);
            }
            for (Quote_Product__c qProd : quoteProds) {
                oppProdToCreate.add(new OpportunityLineItem(PriceBookEntryId = prodMap.get(qProd.Product__c), 
                                                            Quantity = qProd.Quantity__c, 
                                                            UnitPrice = qProd.Sales_Price__c, 
                                                            OpportunityId = opportunity.Id));
            }
        }
        //commit changes
        update opportunity;
        update quotesToUpdate;

        Integer numberOfRecords = Limits.getDMLRows() + oppProdToDelete.size();
        if (numberOfRecords < Limits.getLimitDMLRows()) {
            delete oppProdToDelete;
            numberOfRecords += oppProdToCreate.size();
        }
        if (numberOfRecords < Limits.getLimitDMLRows()) {
            insert oppProdToCreate;
        }
        if (numberOfRecords >= Limits.getLimitDMLRows()) {
            opportunity.BigMachines_Message__c = 'Syncing large number of opportunity products.  Please refresh page to see updated opportunity values.';
            update opportunity;
            updateProductsLater(quoteId, opportunityId);
        }
    }
    
    private static BigMachines_Quote__c[] markOthersAsNonPrimary(ID quoteId, ID opportunityId) {
        BigMachines_Quote__c[] otherQuotes = [select Id, Is_Primary__c, Opportunity__c from BigMachines_Quote__c 
                                              where Opportunity__c = :opportunityId and Id != :quoteId];
        for (BigMachines_Quote__c quote : otherQuotes) {
            //set the quote to non-primary 
            quote.Is_Primary__c = false;
        }
        return otherQuotes;
    }
    
    private static OpportunityLineItem[] getOldOpportunityProducts(ID opportunityId) {
        return [select Id, OpportunityId from OpportunityLineItem
                where OpportunityId = :opportunityId];       
    }
    
    private static OpportunityLineItem[] getNewOpportunityProducts(ID quoteId, ID opportunityId) {
        Opportunity opportunity = [select Name, Pricebook2Id from Opportunity where Id = :opportunityId];
        List<OpportunityLineItem> oppProdToCreate = new List<OpportunityLineItem>();
        Quote_Product__c[] quoteProds = [select Id, Name, Product__c, Quantity__c, Sales_Price__c 
                                         from Quote_Product__c where BigMachines_Quote__c = :quoteId];
        if (quoteProds.size() > 0) {
            ID pricebookId = opportunity.Pricebook2Id;
            if (pricebookId == null) {
                pricebookId = [select Id from Pricebook2 where IsStandard = true].Id;
            }
            Set<ID> productIdSet = new Set<ID>();
            for (Quote_Product__c qProd : quoteProds) {
                productIdSet.add(qProd.Product__c);
            }
            PricebookEntry[] pbEntries = [select Id, Product2Id from PricebookEntry 
                                          where Pricebook2Id = :pricebookId and Product2Id in :productIdSet];
            Map<ID,ID> prodMap = new Map<ID,ID>();
            for (PricebookEntry pbEntry : pbEntries) {
                prodMap.put(pbEntry.Product2Id, pbEntry.Id);
            }
            for (Quote_Product__c qProd : quoteProds) {
                oppProdToCreate.add(new OpportunityLineItem(PriceBookEntryId = prodMap.get(qProd.Product__c), 
                                                            Quantity = qProd.Quantity__c, 
                                                            UnitPrice = qProd.Sales_Price__c, 
                                                            OpportunityId = opportunity.Id));
            }
        }
        return oppProdToCreate;
    }

    @future private static void updateProductsLater(ID quoteId, ID opportunityId) {
        Opportunity opportunity = [select Id from Opportunity where Id = :opportunityId];
        OpportunityLineItem[] oppProdToDelete = getOldOpportunityProducts(opportunityId);
        OpportunityLineItem[] oppProdToInsert = getNewOpportunityProducts(quoteId, opportunityId);
        opportunity.BigMachines_Message__c = '';
        delete oppProdToDelete;
        insert oppProdToInsert;
        update opportunity;
    }

    public class QuoteSyncException extends Exception {}    
    
    static testMethod void testSyncQuoteWithOpty() {
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
        BigMachines_Quote__c[] quotes = new BigMachines_Quote__c[3];
        for (Integer i=0; i<quotes.size(); i++) {
            quotes[i] = new BigMachines_Quote__c();
            quotes[i].Name = 'BigMachines test quote ' + (i+1) + ' for testSyncQuoteWithOpty()';
            quotes[i].Opportunity__c = opty.Id;
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
        quotes[0].Is_Primary__c = true;
        update quotes; 
        
        updateProductsLater(quotes[0].id, opty.id);
        // BigMachinesQuoting.syncQuoteWithOpty - end positive test
        
        // Quote_Product__c.propogateModifications - begin test
        delete qProd[0];
        // Quote_Product__c.propogateModifications - begin test

        // BigMachinesQuoting.syncQuoteWithOpty - begin no product price negative test 
        Quote_Product__c noPriceProd = new Quote_Product__c();
        noPriceProd.Name = 'BMITest05';
        noPriceProd.BigMachines_Quote__c = quotes[0].id;
        noPriceProd.Sales_Price__c = 5;
        noPriceProd.Quantity__c = 6;
        boolean throwsException = false;
        try {
            insert noPriceProd;
        } catch (Exception e) {
            throwsException = true;
        }
        System.assert(throwsException);
        // BigMachinesQuoting.syncQuoteWithOpty - end no product price negative test

        // Quote_Product__c.propogateModifications - begin error check test
        qProd = new Quote_Product__c[2];
        for (Integer i=0; i<qProd.size(); i++) {
            qProd[i] = new Quote_Product__c();
            qProd[i].Name = 'BMITest0' + i;
            qProd[i].BigMachines_Quote__c = quotes[i+1].id;
            qProd[i].Sales_Price__c = 1;
            qProd[i].Quantity__c = 1;
        }
        insert qProd;
        delete qProd;
        // Quote_Product__c.propogateModifications - end error check test

        // BigMachines_Quote__c.promotePrimaryProdToOppty - begin multi-case test
        quotes[0].Is_Primary__c = false;
        quotes[1].Is_Primary__c = true;
        quotes[2].Is_Primary__c = true;
        update quotes;
        // BigMachines_Quote__c.promotePrimaryProdToOppty - end multi-case test
        
        // BigMachinesQuoting.syncQuoteWithOpty - begin invalid pricebook negative test
        Pricebook2 pbook = new Pricebook2();
        pbook.Name = 'Different pricebook';
        insert pbook;
        quotes[0].Is_Primary__c = true;
        quotes[0].Pricebook_Id__c = pbook.id;
        throwsException = false;
        try {
            update quotes;
        } catch (Exception e) {
            throwsException = true;
        }
      //  System.assert(throwsException);
        // ignore invalid pricebook Id
        quotes[0].Pricebook_Id__c = 'garbage';
        quotes[0].Is_Primary__c = true;
        update quotes;
        // BigMachinesQuoting.syncQuoteWithOpty - end invalid pricebook negative test
    } 

}