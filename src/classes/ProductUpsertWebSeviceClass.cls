@RestResource(urlmapping='/UpsertProduct/*')
global class ProductUpsertWebSeviceClass {

 @HTTPPOST
 global static void UpsertProduct(list<ProductFields> lstProds){
       list<Product2> lstFormatterProds = new List<Product2>();
       list<string> errorMessages = new list<string>();
       try{
            for(ProductFields prod : lstProds){
                Product2 newProd = new Product2();           
                if(prod.prodId != null && prod.prodId != '')
                        newProd.Id = prod.prodId;
                newProd.CadebillFeatureDetailID__c = prod.CadebillFeatureDetailID;
                newProd.CadebillFeatureKey__c = prod.CadebillFeatureKey;
                newProd.Cadebill_Product_ID__c = prod.CadebillProductID;
                newProd.Description = prod.Description;
                newProd.Name = prod.Name;
                newProd.ProductCode = prod.ProductCode;
                newprod.ListPrice__c = prod.UnitPrice;
                newprod.IsActive = prod.isActive;
                newprod.Cadebill_Country_Code__c = prod.CountryCode;
                lstFormatterProds.add(newProd);            
            }        
            if(lstFormatterProds.size() > 0)
                ProductUpsertWebSeviceClass.upsertProds(lstFormatterProds);   
       }
       Catch(Exception ex){
            string error = 'The following error has occurred. ' +  ex.getMessage() 
                		+ ' at line ' +  ex.getLineNumber();
          errorMessages.add(error);
           
       }             
       if(errorMessages.size() > 0)
           ProductUpsertWebSeviceClass.doSendEmail(errorMessages);
        
    } 
    
 // return Pricebook Id
 private static Map<string, string> getPriceBookId(set<string> pbNames){     
     map<string, string> mpPriceBooks = new map<string, string>();
     for(PriceBook2 pb : [select Id, Name, isStandard 
                          From PriceBook2 
                          where (Name in :pbNames or isStandard = true) and isActive = true]){
          if(pb.isStandard)
               mpPriceBooks.put('Standard_PB', pb.Id);
          else 
               mpPriceBooks.put(pb.Name, pb.Id);
       }
       return mpPriceBooks;        
    }
    
 // create pricebooks 
 private static void insertPriceBookEntries(List<Product2> lstProds){
     set<string> pbNames = new set<string>();
     pbNames.add('SaaS-Cadebill');
     map<string, string> mpPriceBooks = ProductUpsertWebSeviceClass.getPriceBookId(pbNames);
     list<PricebookEntry> lstPriceBookEntries = new list<PricebookEntry>();
     list<string> errorMessages = new list<string>();
        
     for(Product2 prod : lstProds){
         for(string pricebookId : mpPriceBooks.values()){             
             PricebookEntry newPBEntry = new PricebookEntry();  
             newPBEntry.IsActive = true;          
             newPBEntry.Product2Id = prod.Id;             
             newPBEntry.Pricebook2Id = pricebookId;    
             newPBEntry.UnitPrice = prod.ListPrice__c; 
             newPBEntry.UseStandardPrice = false;
             lstPriceBookEntries.add(newPBEntry);  
         }
        }
        
     if(lstPriceBookEntries.size() > 0){            
        Database.SaveResult[] resultlists = Database.insert(lstPriceBookEntries, false);     
        for (Database.SaveResult sr : resultlists) {   			
            for(Database.Error err : sr.getErrors()) {
               string error = 'The following error has occurred. ' +  err.getMessage() 
               		  + '. PriceBookEntry fields that effected this error : ' + err.getFields();
               errorMessages.add(error);
            }
       }
       if(errorMessages.size() > 0)
          ProductUpsertWebSeviceClass.doSendEmail(errorMessages);
    }        
 }
    
 //upsert products       
 private static void upsertProds(List<Product2> lstFormatterProds){
     set<Id> stSuccessProdInserts = new set<Id>();
     list<string> errorMessages = new list<string>();
     Database.UpsertResult[] upsertProdResults = Database.upsert(lstFormatterProds, false);
     for(Database.UpsertResult upr : upsertProdResults){
         if(upr.isSuccess() && upr.isCreated())
            stSuccessProdInserts.add(upr.getId());
         else{
              for(Database.Error err : upr.getErrors()) {
                  string error = 'The following error has occurred. ' +  err.getMessage() 
                           + '.  Product fields that effected this error : ' + err.getFields();
                  errorMessages.add(error);
              }
           }            
     }        
     
     if(errorMessages.size() > 0)
       	ProductUpsertWebSeviceClass.doSendEmail(errorMessages);
        
     if(stSuccessProdInserts.size() > 0){
        List<Product2> lstProds = new list<Product2>([select Id, Name,ListPrice__c from Product2 where Id =:stSuccessProdInserts]);
        ProductUpsertWebSeviceClass.insertPriceBookEntries(lstProds);
    }
  }
    
 // Alert developers in case of error
 private static void doSendEmail(list<string> emailbody){
     string htmlbodyText = 'Errors  - ';
     for(integer i = 0; i < emailbody.size(); i++){
         integer thisNumber = i + 1;
         htmlbodyText += '<br/>' + thisNumber + '. ' + emailbody[i]; 
       }        
     Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
	 String[] toAddresses = new String[] {'Arnab.KarSarkar@incontact.com', 'Shawn.Hartke@incontact.com'};
	 mail.setToAddresses(toAddresses);
	 mail.setSubject('There is an unexpected error occured');
	 mail.setHtmlBody(htmlbodyText);
	Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });	
 }
    
 // WrapperClass for Product Update/Insert
 global class ProductFields{
        global string ProdId;       
        global decimal CadebillFeatureDetailID;
        global decimal CadebillFeatureKey;
        global string CadebillProductID;
        global string Description;
        global boolean isActive;
        global string Name;
        global string ProductCode;
        global decimal UnitPrice;
     	global string Family;
     	global string  CountryCode;     
        
    }
    
}