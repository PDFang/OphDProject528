global class InContactQuoteCalculatorPlugin implements SBQQ.QuoteCalculatorPlugin {
    
    Map<Id,Product2> productsMap;
    
    global void onInit(SObject[] lines) {
        productsMap = new Map<Id,Product2>([SELECT Id, ProductCode, Cadebill_Product_ID__c, Core_Seat_License__c FROM Product2]);
    }
    
    global void onBeforePriceRules(SObject quote, SObject[] lines) {
        // Maps containing the quantities of users for country-specific telco products.
        Map<String,Decimal> GlobalTFSelectUserMap = new Map<String,Decimal>();
        Map<String,Decimal> IntLocalSelectUserMap = new Map<String,Decimal>();
        Map<String,Decimal> LocalEnhancedUserMap = new Map<String,Decimal>();
        Map<String,Decimal> TFEnhancedUserMap = new Map<String,Decimal>();
        
        // List of country-specific telco setup quote lines to have quantities adjusted.
        List<QuoteLine> GlobalTFSelectUserSetupList = new List<QuoteLine>();
        List<QuoteLine> IntLocalSelectUserSetupList = new List<QuoteLine>();
        List<QuoteLine> LocalEnhancedUserSetupList = new List<QuoteLine>();
        List<QuoteLine> TFEnhancedUserSetupList = new List<QuoteLine>();
        
        for (SObject line : lines) {
            QuoteLine ql = new QuoteLine(line);
            String productCode = productsMap.get(ql.getProductId()).ProductCode;
            if (productCode.startsWith('1268-133-000-')){
                if (productCode.endsWith('-N')){
                    GlobalTFSelectUserSetupList.add(ql);
                } else {
                    GlobalTFSelectUserMap.put(productCode + '-N',ql.getQuantity());
                }
            } else if (productCode.startsWith('1009-149-000-')){
                if (productCode.endsWith('-N')){
                    IntLocalSelectUserSetupList.add(ql);
                } else {
                    IntLocalSelectUserMap.put(productCode + '-N',ql.getQuantity());
                }
            } else if (productCode.startsWith('1009-148-000-')){
                if (productCode.endsWith('-N')){
                    LocalEnhancedUserSetupList.add(ql);
                } else {
                    LocalEnhancedUserMap.put(productCode + '-N',ql.getQuantity());
                }
            } else if (productCode.startsWith('1268-132-000-')){
                if (productCode.endsWith('-N')){
                    TFEnhancedUserSetupList.add(ql);
                } else {
                    TFEnhancedUserMap.put(productCode + '-N',ql.getQuantity());
                }
            }
        }
        
        // Update each of the setup quote lines with the appropriate quantity.
        for (QuoteLine ql : GlobalTFSelectUserSetupList) {
            String productCode = productsMap.get(ql.getProductId()).ProductCode;
            ql.record.put(SBQQ__QuoteLine__c.SBQQ__Quantity__c,GlobalTFSelectUserMap.get(productCode));
        }
        for (QuoteLine ql : IntLocalSelectUserSetupList) {
            String productCode = productsMap.get(ql.getProductId()).ProductCode;
            ql.record.put(SBQQ__QuoteLine__c.SBQQ__Quantity__c,IntLocalSelectUserMap.get(productCode));
        }
        for (QuoteLine ql : LocalEnhancedUserSetupList) {
            String productCode = productsMap.get(ql.getProductId()).ProductCode;
            ql.record.put(SBQQ__QuoteLine__c.SBQQ__Quantity__c,LocalEnhancedUserMap.get(productCode));
        }
        for (QuoteLine ql : TFEnhancedUserSetupList) {
            String productCode = productsMap.get(ql.getProductId()).ProductCode;
            ql.record.put(SBQQ__QuoteLine__c.SBQQ__Quantity__c,TFEnhancedUserMap.get(productCode));
        }
    }
    
    global void onAfterPriceRules(SObject quote, SObject[] lines) {}
    global void onBeforeCalculate(SObject quote, SObject[] lines) {}
    
    global void onAfterCalculate(SObject quote, SObject[] lines) {
        List<QuoteLine> thresholdLines = new List<QuoteLine>();
        Decimal seatQuantity = null;
        
        for (SObject line : lines) {
            QuoteLine ql = new QuoteLine(line);
            // Get the seat count from the bundle. Assuming only one on any given quote.
            // Use 'Seat Level Product' field instead of 'Product ID', to determine if this is a Seat Level Product
            //if (productsMap.get(ql.getProductId()).Cadebill_Product_ID__c == '307'){
            if (productsMap.get(ql.getProductId()).Core_Seat_License__c){            
                seatQuantity = ql.getQuantity();
            // Build a sub-list of the quote lines that only includes professional services implementations.
            } else if (ql.getOverageRate() != null && ql.getImplementationSeatThreshold() != null && ql.getOriginalPrice() != null && !(ql.get3rdParty() && ql.get3rdPartyAllowed())){
                thresholdLines.add(ql);
            }
        }
        
        if (seatQuantity != null && thresholdLines.size() > 0){
            // Update any threshold-type quote line to hold a quantity of 1 and a list price altered by the overage rate and discount.
            for (QuoteLine ql : thresholdLines) {
                Decimal overageRate = ql.getOverageRate();
                Decimal impSeatThreshold = ql.getImplementationSeatThreshold();
                Decimal listUnitPrice = ql.getOriginalPrice();
                Decimal additionalDiscountAmount = ql.getAdditionalDiscountAmount();
                Decimal additionalDiscountPercent = ql.getAdditionalDiscountPercent();
                ql.record.put(SBQQ__QuoteLine__c.SBQQ__Quantity__c,1); // The quantity of the product must be singled out.
                Decimal listPrice = listUnitPrice + (Math.max(seatQuantity,impSeatThreshold) - impSeatThreshold) * overageRate;
                ql.record.put(SBQQ__QuoteLine__c.SBQQ__ListPrice__c,listPrice); // List price does not take into account discounts.
                ql.record.put(SBQQ__QuoteLine__c.SBQQ__ProratedPrice__c,listPrice);
                Decimal netPrice = listPrice;
                if (additionalDiscountAmount != null){ // If discounts are populated, adjust the net price.
                    netPrice = listPrice - additionalDiscountAmount;
                } else if (additionalDiscountPercent != null){
                    netPrice = listPrice * (100 - additionalDiscountPercent) / 100;
                }
                ql.record.put(SBQQ__QuoteLine__c.SBQQ__NetPrice__c,netPrice);
            }
        }
    }
    
    private class QuoteLine {
        private SObject record;
        
        private QuoteLine(SObject record) {
            this.record = record;
        }
        
        public String getProductId() {
            return (String)record.get(String.valueOf(SBQQ__QuoteLine__c.SBQQ__Product__c));
        }
        public Boolean get3rdParty() {
            return (Boolean)record.get(String.valueOf(SBQQ__QuoteLine__c.X3rd_Party__c));
        }
        public Boolean get3rdPartyAllowed() {
            return (Boolean)record.get(String.valueOf(SBQQ__QuoteLine__c.X3rd_Party_Allowed__c));
        }
        
        public Decimal getQuantity() {
            return (Decimal)record.get(String.valueOf(SBQQ__QuoteLine__c.SBQQ__Quantity__c));
        }
        
        public Decimal getOriginalPrice() {
            return (Decimal)record.get(String.valueOf(SBQQ__QuoteLine__c.Original_Price__c));
        }
        
        public Decimal getOverageRate() {
            return (Decimal)record.get(String.valueOf(SBQQ__QuoteLine__c.Overage_Rate__c));
        }
        
        public Decimal getImplementationSeatThreshold() {
            return (Decimal)record.get(String.valueOf(SBQQ__QuoteLine__c.Implementation_Seat_Threshold__c));
        }
        
        public Decimal getAdditionalDiscountAmount() {
            return (Decimal)record.get(String.valueOf(SBQQ__QuoteLine__c.SBQQ__AdditionalDiscountAmount__c));
        }
        
        public Decimal getAdditionalDiscountPercent() {
            return (Decimal)record.get(String.valueOf(SBQQ__QuoteLine__c.SBQQ__Discount__c));
        }
    }
}