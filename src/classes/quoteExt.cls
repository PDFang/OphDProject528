/*
 *  This class which extends the WfoPremiseQuote__c standard controller is utilized by the QuoteNew
 *  Visualforce page to default values for the user from the related opportunity during 
 *  the creation of a new quote.  It also provides an action that generates the PDF and creates 
 *  an attachment under the parent Quote record who's id is passed into the same Visualforce page 
 *  that can be accessed in the UI to generate the same PDF.
 */
public class quoteExt {
  
  
  

    /* The standard controller object which will be used later for navigation and to invoke
       it's save action method to create the new Quote. */
    ApexPages.StandardController controller;
    
    /* The quote property which is used by the quoteNew and quotePDF Pages and this controller
       to provide access to the relevant quote information. */
    public WfoPremiseQuote__c q {get;set;} 
    
    /* The constructor to this extension class which takes the standard controller as its argument
       which allows this class to access the methods and information available in the instance for 
       the quote.*/
    public QuoteExt(ApexPages.StandardController c) {
      
        controller = c;     
        q  = (WfoPremiseQuote__c)c.getRecord();
        String  opp_temp2 = q.Opportunity__c;
      //  Opportunity opp_temp = [select name,Quote_Software_Notes__c,Quote_Hardware_Notes__c,Quote_Services_Notes__c,Quote_AMC_Notes__c,Quote_General_Notes__c
     //                     from opportunity 
     //                                   where id = :opp_temp2];
                                        
  
        Opportunity opp_temp = [select name,Quote_Software_Notes__c,Quote_Hardware_Notes__c,Quote_Services_Notes__c,Quote_AMC_Notes__c,Quote_General_Notes__c
    //    Salesperson_Hardware_Section_Discount__c,
    //    Salesperson_Maintenance_Section_Discount__c,
    //    Salesperson_Product_Section_DIscount__c,
    //    Salesperson_Services_Section_Discount__c
                          from opportunity  
                                        where id = :opp_temp2];
                                        
                                        
    //    Decimal SalespersonProductSectionDiscount = opp_temp.Salesperson_Product_Section_DIscount__c;
    //    Decimal SalespersonHardwareSectionDiscount = opp_temp.Salesperson_Hardware_Section_Discount__c;
    //    Decimal SalespersonMaintenanceSectionDiscount = opp_temp.Salesperson_Maintenance_Section_Discount__c;
     //   Decimal SalespersonServicesSectionDiscount = opp_temp.Salesperson_Services_Section_Discount__c;                                
                                        
        //ApexPages.Message myMsgerr = new ApexPages.Message(ApexPages.Severity.Error,'We are working on updating quoting. It will be available again shortly. -- Ray');
        //ApexPages.addMessage(myMsgerr); 
        //ApexPages.Message myMsg2 = new ApexPages.Message(ApexPages.Severity.Error,'This is an error '+opp_temp.Name);
       // ApexPages.addMessage(myMsg2); 
       // if (opp_temp.Name == 'Ray Test')
        //{
          if (!HasRequiredIntegrationType_Voice(opp_temp))
          {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,'Because this opportunity has voice licenses, a Voice Integration type must also be added to the product list. Please add this and then retry quoting.'));
           
          }else if (!HasRequiredIntegrationType_WFM(opp_temp))
          {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,'Because this opportunity has WFM (Clarity) licenses, a WFM Integration type must also be added to the product list. Please add this and then retry quoting.'));
           
          }  
          
          
          
        else{
        
        
        
        
          q.Expiration__c = '30 Days';
          //q.Opportunity__c = ApexPages.currentPage().getParameters().get('oppid');
       
          // Opportunity o       = [select id,Quote_Software_Notes__c,Quote_Hardware_Notes__c,Quote_Services_Notes__c,Quote_AMC_Notes__c,Quote_General_Notes__c from opportunity 
          //                         where id = :q.opportunity__c];
        
          /* Set the quote's lookup field to opportunity to the value of the oppid request parameter. */
        
        
          /* If non-null, get the opportunity and contact role for appropriate defaulting of values. */
          if(q.opportunity__c != null) {
              /* Set the related opportunity with the result of the query that traverses to account for display of the name
                 and down to get the primary contact role. */
              q.opportunity__r = [select name, account.name,Quote_Software_Notes__c,Quote_Hardware_Notes__c,Quote_Services_Notes__c,Quote_AMC_Notes__c,Quote_General_Notes__c,
            
                                         (select contact.name, contact.mailingStreet, contact.mailingcity, contact.mailingstate, 
                                                 contact.mailingpostalcode 
                                          from opportunityContactRoles 
                                          where isPrimary = true)
                                  from opportunity 
                                  where id = :q.opportunity__c];
                                                             
                                                          
                                                                
              if(q.opportunity__r.opportunityContactRoles.size()  == 1) {
                  OpportunityContactRole r = q.opportunity__r.opportunityContactRoles[0];
                  q.contact__r  = r.contact;
                  q.contact__c  = r.contact.id;  
                  q.street__c   = r.contact.mailingstreet;
                  q.city__c     = r.contact.mailingcity;
                  q.state__c    = r.contact.mailingstate;
                  q.zip_code__c = r.contact.mailingpostalcode;              
               
              }
            
                q.Discount_Software__c = 0;
                q.Discount_Services__c = 0;
              q.Discount_Hardware__c = 0;
              q.Discount_AMC__c = 0;
              q.Partner_Name__c='';
            
              Opportunity opp = [select name,Quote_Software_Notes__c,Quote_Hardware_Notes__c,Quote_Services_Notes__c,Quote_AMC_Notes__c,Quote_General_Notes__c
                          from opportunity 
                                        where id = :q.opportunity__c];
           
            
              q.Quote_General_Notes__c = opp.Quote_General_Notes__c;
              q.Quote_Software_Notes__c = opp.Quote_Software_Notes__c;
              q.Quote_Services_Notes__c = opp.Quote_Services_Notes__c;
              q.Quote_Hardware_Notes__c = opp.Quote_Hardware_Notes__c;
              q.Quote_AMC_Notes__c = opp.Quote_AMC_Notes__c;
             
            
              OpportunityPartner[] op = [select AccountToId from OpportunityPartner where IsPrimary=true and OpportunityId = :q.opportunity__c];
              if (op.size() > 0) {
                Account account = [select Name,Id,Discount_Software__c,Discount_Hardware__c,Discount_Services__c,Discount_AMC__c from Account where Id = :op[0].AccountToId];
                if (account != null){
                  q.Discount_Software__c = account.Discount_Software__c;
                  q.Discount_Services__c = account.Discount_Services__c;
                  q.Discount_Hardware__c = account.Discount_Hardware__c;
                  q.Discount_AMC__c = account.Discount_AMC__c;
                  q.Partner_Name__c = account.Name;
                }
              }
            
            
          } 
            
        }
    }
    
    private Decimal ApplyDiscount(Decimal price, Decimal discount){
      if (discount != null) {
        if (discount > 0) {
          price = price * ( (100 - discount) * .01);
        }
      }
      return price;
    }
    
    private Boolean HasRequiredIntegrationType_Voice(Opportunity opp_temp)
    {
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,'PLEASE IGNORE THESE ERROR MESSAGES'));
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,opp_temp.Id));
      
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info,'In HasRequiredIntegrationType_Voice'));
          
          
        Boolean HasVoiceIntegrationtype =  false;
        Boolean HasVoiceLicenses =  false;
      for(OpportunityLineItem oli_update:[select quantity, unitprice,listprice,Adjusted_List__c,Sell_At_Cost__c,totalprice,discount__c,pricebookEntry.product2.name,pricebookEntry.product2.Description,pricebookEntry.product2.family,pricebookEntry.product2.category__c, pricebookEntry.product2.productcode,pricebookEntry.product2.Sort_ID__c, pricebookEntry.product2id 
                                     from opportunitylineitem
                                     where opportunityid = :opp_temp.Id]) 
        {
          
          String name = oli_update.pricebookEntry.product2.name;
          String category = oli_update.pricebookEntry.product2.category__c;
          //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,' name='+name));
          //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,' category='+category));
          
          
          
          if (name.contains('cc:Voice'))
          {
            HasVoiceLicenses = true;          
          }
          
          
          
          //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info,name));
          //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info,oli_update.pricebookentry.product2.category__c)); 
           
          if ((oli_update.pricebookentry.product2.category__c == 'Integration'))
          {
            if (!name.contains('WFM'))
            {
              HasVoiceIntegrationtype = true;
            }
            
          
          }
          
          
            
                                     
        }
        
        
          
          if (HasVoiceLicenses)
          {
            return HasVoiceIntegrationtype;
          }else
          {
            return true;
          }
          
      
    }
    
    
    
     private Boolean HasRequiredIntegrationType_WFM(Opportunity opp_temp)
    {

        Boolean HasWFMIntegrationtype =  false;
        Boolean HasWFMLicenses =  false;
      for(OpportunityLineItem oli_update:[select quantity, unitprice,listprice,Adjusted_List__c,Sell_At_Cost__c,totalprice,discount__c,pricebookEntry.product2.name,pricebookEntry.product2.Description,pricebookEntry.product2.family,pricebookEntry.product2.category__c, pricebookEntry.product2.productcode,pricebookEntry.product2.Sort_ID__c, pricebookEntry.product2id 
                                     from opportunitylineitem
                                     where opportunityid = :opp_temp.Id]) 
        {
          
          String name = oli_update.pricebookEntry.product2.name;
          String category = oli_update.pricebookEntry.product2.category__c;

          if (name.contains('cc: Clarity'))
          {
            HasWFMLicenses = true;          
          }
          
          
          if ((oli_update.pricebookentry.product2.category__c == 'Integration'))
          {
            if (name.contains('WFM'))
            {
              HasWFMIntegrationtype = true;
            }
          
          }
          
          
            
                                     
        }
        
        
          
          if (HasWFMLicenses)
          {
            return HasWFMIntegrationtype;
          }else
          {
            return true;
          }
          
      
    }
    
    /* This save method will be called instead of the standard controller save method when bound
       to an action component in an associated page, (apex:commandButton on the quoteNew 
       Visualforce page in this example) */
    public PageReference save() {
      
      System.debug('quote save()');
    
        /* Invoke the standard controller save method which returns the pageReference class 
           that will be used in the navigation, i.e. send the user to the expected location based on
           standard navigation rules provided by salesforce.com */
        PageReference p = controller.save();
        
        /* The quote's record Id */
        id qid = controller.getId();
        
        
        /* testing subtotal functionality */
        Decimal subtotal_software = 0; 
        Decimal subtotal_hardware = 0; 
        Decimal subtotal_software_list = 0; 
        Decimal subtotal_hardware_list = 0; 
        Decimal subtotal_services = 0; 
        Decimal subtotal_services_list = 0; 
        Decimal subtotal_amc_list = 0; 
        Decimal subtotal_amc = 0;  
        Decimal subtotal_list = 0; 
        Decimal subtotal_other = 0;
        Decimal subtotal_other_list = 0;
        
        Decimal customer_subtotal_software = 0; 
        Decimal customer_subtotal_hardware = 0; 
        Decimal customer_subtotal_services = 0; 
        Decimal customer_subtotal_amc = 0;  
        Decimal customer_subtotal_other = 0;  
        Decimal customer_quote_total_price = 0;  
        
        Boolean software_has_customer_discount = false;
        Boolean hardware_has_customer_discount = false;
        Boolean services_has_customer_discount = false;
        Boolean other_has_customer_discount = false;
        Boolean amc_has_customer_discount = false;
        
        
        Boolean software_has_distributor_discount = false;
        Boolean hardware_has_distributor_discount = false;
        Boolean services_has_distributor_discount = false;
        Boolean amc_has_distributor_discount = false;
        
      
        
        
        /* The collection of quote_item__c records to be created based on the related opportunity's 
           opportunity line items (products), if any. */
        Quote_Item__c[] items = new Quote_Item__c[]{};
        
        OpportunityLineItem maintenanceLineItem;
        Decimal Distributor_Discount = 0;
        
        Decimal customer_unit_price = 0;
        Decimal customer_total_price = 0;
        
        Decimal opportunity_cost;
        Decimal margin_amount;
        Decimal margin_percent;
        
        /* Update Distributor Discount Line Items */
        /* Makes discount available for worlflow purposes */
        
        
        
        
        for(OpportunityLineItem oli_update:[select quantity, unitprice,listprice,Adjusted_List__c,Sell_At_Cost__c,totalprice,discount__c,pricebookEntry.product2.name,pricebookEntry.product2.Description,pricebookEntry.product2.family,pricebookEntry.product2.category__c, pricebookEntry.product2.productcode,pricebookEntry.product2.Sort_ID__c, pricebookEntry.product2id 
                                     from opportunitylineitem
                                     where opportunityid = :q.opportunity__c]) 
        {
          if ((oli_update.pricebookentry.product2.category__c == 'Software')||
              (oli_update.pricebookentry.product2.category__c == 'Integration')) {
                oli_update.Distributor_Discount__c = q.Discount_software__c;
              update oli_update;                         
                                       
            }
            
            if (oli_update.pricebookentry.product2.category__c == 'Services') {
              oli_update.Distributor_Discount__c = q.Discount_services__c;
              update oli_update;
            }
            
            if (oli_update.pricebookentry.product2.category__c == 'Hardware') { 
              oli_update.Distributor_Discount__c = q.Discount_hardware__c;
              update oli_update;
            }
            
            if ((oli_update.pricebookentry.product2.category__c == 'Maintenance')) {              
              oli_update.Distributor_Discount__c = q.Discount_AMC__c;
              update oli_update;
              
            }
                                     
        }
        
        opportunity_cost=0;
            margin_amount=0;
            margin_percent=0;
            
            
        List<OpportunityLineItem> oliToUpdate = new List<OpportunityLineItem>();
            
        /* Establish the quoteItem collection based on the opportunity's line items, if any */
        for(OpportunityLineItem oli:[select quantity, unitprice,listprice,Adjusted_List__c,Sell_At_Cost__c,totalprice,discount__c,pricebookEntry.product2.name,pricebookEntry.product2.Description,pricebookEntry.product2.family,pricebookEntry.product2.category__c, pricebookEntry.product2.productcode,pricebookEntry.product2.Sort_ID__c, pricebookEntry.product2id 
                                     from opportunitylineitem
                                     where opportunityid = :q.opportunity__c]) {
            customer_unit_price = 0;
          customer_total_price = 0;                           
            Distributor_Discount = 0;
            
            
            
           if (oli.Adjusted_List__c == null){             
              oli.Adjusted_List__c = oli.listprice;
           }
           
           if (oli.Adjusted_List__c == 0){             
              oli.Adjusted_List__c = oli.listprice;
           }
            if ((oli.pricebookentry.product2.productcode != null) && (oli.pricebookentry.product2.category__c != 'Maintenance')){
           // if (oli.pricebookentry.product2.productcode.subString(0,2) != 'AMC'){
            //if ((oli.pricebookentry.product2.productcode != null) && (oli.pricebookentry.product2.productcode != 'AMC-18')) {                           
              subtotal_list = subtotal_list + (oli.listprice * oli.quantity);       
            
            }
                                       
            if ((oli.pricebookentry.product2.category__c == 'Integration')) {
            
                 if (oli.Discount__c > 0)  
               {
                 software_has_customer_discount = true;
               }
            }
              
              
            if ((oli.pricebookentry.product2.category__c == 'Software') || (oli.pricebookentry.product2.category__c == 'Integration')) {
                
               if (oli.Discount__c > 0)  
               {
                 software_has_customer_discount = true;
               }
               
               Distributor_Discount =q.Discount_Software__c;
               
               if (Distributor_Discount > 0)  
               {
                 software_has_distributor_discount = true;
               }
               
               if (oli.Adjusted_List__c != null){
                 subtotal_software_list = subtotal_software_list + (oli.Adjusted_List__c * oli.Quantity); // (oli.listprice * oli.Quantity);
               }else
               {
                 subtotal_software_list = subtotal_software_list + (oli.listprice * oli.Quantity);
               } 
               
              // if (oli.Final_Price__c != null){
              // customer_subtotal_software += (oli.Final_Price__c * oli.Quantity);//(oli.unitprice * oli.Quantity);
              // }else
              // {
                 
              // }
               
               
               
               if (oli.Discount__c != null){
                 customer_unit_price = oli.Adjusted_List__c * ((100-oli.Discount__c)/100);
           customer_total_price = ((oli.Adjusted_List__c * (((100-oli.Discount__c)/100))) * oli.Quantity); 
                 }else{
                 customer_unit_price = oli.Adjusted_List__c;
           customer_total_price = (oli.Adjusted_List__c * oli.Quantity);               
                 }
                 customer_subtotal_software += customer_total_price;
            
               
               //subtotal_software = subtotal_software + ApplyDiscount(customer_subtotal_software,Distributor_Discount);
               
               subtotal_software += oli.unitprice * oli.Quantity; 
               //if (Distributor_Discount != null) {
               //   if (Distributor_Discount > 0){
               //     subtotal_software += oli.unitprice * oli.Quantity; //+= (oli.unitprice * ( (100 - Distributor_Discount) * .01)) * oli.Quantity;  
               //   }else{
               //     subtotal_software += ApplyDiscount(oli.unitprice,Distributor_Discount) * oli.Quantity;  
                //  }
                //}        
                //else
                //{                  
                //  subtotal_software += ApplyDiscount(oli.unitprice,Distributor_Discount) * oli.Quantity;
                //}
               
               
               
               //subtotal_software += (oli.unitprice * oli.Quantity); //subtotal_software + oli.totalprice; //ApplyDiscount(oli.totalprice,Distributor_Discount);
               }
               
            if (oli.pricebookentry.product2.category__c == 'Services') {
              if (oli.Discount__c > 0)  
               {
                 services_has_customer_discount = true;
               }
               Distributor_Discount =q.Discount_services__c;
               if (Distributor_Discount > 0)  
               {
                 services_has_distributor_discount = true;
               }
               
               
               if (oli.Discount__c != null){
                 customer_unit_price = oli.Adjusted_List__c * (((100-oli.Discount__c)/100));
           customer_total_price = ((oli.Adjusted_List__c * (((100-oli.Discount__c)/100))) * oli.Quantity); 
                 }else{
                 customer_unit_price = oli.Adjusted_List__c;
           customer_total_price = (oli.Adjusted_List__c * oli.Quantity);               
                 }
                 customer_subtotal_services += customer_total_price;
                    
               
               
               if (oli.Adjusted_List__c != null)
               {
                 subtotal_services_list = subtotal_services_list + (oli.Adjusted_List__c * oli.Quantity); //(oli.listprice * oli.Quantity);
               }
               else
               {
                 subtotal_services_list = subtotal_services_list + (oli.listprice * oli.Quantity);
               
               } 
               
               //subtotal_services = subtotal_services+ ApplyDiscount(customer_subtotal_services,Distributor_Discount);
               //subtotal_services = subtotal_services+ oli.totalprice; //ApplyDiscount(oli.totalprice,Distributor_Discount);
               
               subtotal_services += oli.unitprice * oli.Quantity; 
               //if (Distributor_Discount != null) {
               //   if (Distributor_Discount > 0){
               //     subtotal_services += (oli.unitprice * ( (100 - Distributor_Discount) * .01)) * oli.Quantity;  
               //   }else{
               //     subtotal_services += ApplyDiscount(oli.unitprice,Distributor_Discount) * oli.Quantity;  
               //   }
               // }        
               // else
               // {                  
               //   subtotal_services += ApplyDiscount(oli.unitprice,Distributor_Discount) * oli.Quantity;
               // }
               }
          
            
            if (oli.pricebookentry.product2.category__c == 'Hardware') { 
              if (oli.Discount__c > 0)  
               {
                 hardware_has_customer_discount = true;
               }
               Distributor_Discount = q.Discount_Hardware__c;
               if ((Distributor_Discount > 0) || (oli.Sell_At_Cost__c)) 
               {
                 hardware_has_distributor_discount = true;
               }
               
               
              if (oli.Discount__c != null){
                 customer_unit_price = oli.Adjusted_List__c * (((100-oli.Discount__c)/100));
           customer_total_price = ((oli.Adjusted_List__c * (((100-oli.Discount__c)/100))) * oli.Quantity); 
                 }else{
                 customer_unit_price = oli.Adjusted_List__c;
           customer_total_price = (oli.Adjusted_List__c * oli.Quantity);               
                 }
                 customer_subtotal_hardware += customer_total_price;
               
               
              if (oli.Adjusted_List__c != null)
              {
              subtotal_hardware_list = subtotal_hardware_list + (oli.Adjusted_List__c * oli.Quantity); //(oli.listprice * oli.Quantity); 
              }else{
                
              subtotal_hardware_list = subtotal_hardware_list + (oli.listprice * oli.Quantity); 
              
              }
              //subtotal_hardware = subtotal_hardware + ApplyDiscount(customer_subtotal_hardware,Distributor_Discount);
              //subtotal_hardware = subtotal_hardware + oli.totalprice; //ApplyDiscount(oli.totalprice,Distributor_Discount);
              subtotal_hardware += oli.unitprice * oli.Quantity; 
              
              //if (Distributor_Discount != null) {
              //    if (Distributor_Discount > 0){
              //      subtotal_hardware += (oli.unitprice * ( (100 - Distributor_Discount) * .01)) * oli.Quantity;  
              //    }else{
              //      subtotal_hardware += ApplyDiscount(oli.unitprice,Distributor_Discount) * oli.Quantity;  
              //    }
               // }        
               // else
               // {                  
               //   subtotal_hardware += ApplyDiscount(oli.unitprice,Distributor_Discount) * oli.Quantity;
               // }
              }
            
            
            if (oli.pricebookentry.product2.category__c == 'Other') { 
              if (oli.Discount__c > 0)  
               {
                 other_has_customer_discount = true;
               }
              
               
               
              if (oli.Discount__c != null){
                 customer_unit_price = oli.Adjusted_List__c * (((100-oli.Discount__c)/100));
           customer_total_price = ((oli.Adjusted_List__c * (((100-oli.Discount__c)/100))) * oli.Quantity); 
                 }else{
                 customer_unit_price = oli.Adjusted_List__c;
           customer_total_price = (oli.Adjusted_List__c * oli.Quantity);               
                 }
                 customer_subtotal_other += customer_total_price;
               
               
              if (oli.Adjusted_List__c != null)
              {
              subtotal_other_list = subtotal_other_list + (oli.Adjusted_List__c * oli.Quantity); //(oli.listprice * oli.Quantity); 
              }else{
                
              subtotal_other_list = subtotal_other_list + (oli.listprice * oli.Quantity); 
              
              }
              subtotal_other += oli.unitprice * oli.Quantity; 
    
              }
            
            
            
            if ((oli.pricebookentry.product2.category__c == 'Maintenance')) {
              if (oli.Discount__c > 0)  
               {
                 amc_has_customer_discount = true;
               }
              Distributor_Discount = q.Discount_AMC__c;
              maintenanceLineItem = oli;
              maintenanceLineItem.pricebookentry.product2.name = 'AMC Automatically Calculated';
              
            }else{
                   
                Decimal unit_price =  (oli.unitprice);//oli.unitprice;
                
                
            
                //if (Distributor_Discount != null) {
               //   if (Distributor_Discount > 0){
               //     unit_price = Adjusted_List__c * ( (100 - Distributor_Discount) * .01);  
               //   }
                  //}               
            
            //name = oli.pricebookentry.product2.name
            //if (oli.Discount__c != null){
            //  customer_unit_price = oli.listprice * (1-oli.Discount__c);
      //  customer_total_price = ((oli.listprice * (1-oli.Discount__c)) * oli.Quantity); 
           // }else{
            //  customer_unit_price = oli.listprice;
      //  customer_total_price = (oli.listprice * oli.Quantity);               
            //}
            
            string description = '';
            if (oli.pricebookentry.product2.description != null){
              description = oli.pricebookentry.product2.description;
            }
            
            
            description = description.Replace('#BR#','<br/>');
            
            System.debug('items.add quantity__c = ['+oli.quantity+'], unit_price__c = ['+unit_price+'], quote__c = ['+qid+'],'+
            'discount__c = ['+oli.discount__c+'],'+                       
                                        'list_price__c = ['+oli.listprice+'], name = ['+oli.pricebookentry.product2.name+'],'+ 
                                        'description__c = ['+description +'],'+
                                        'Adjusted_List__c = ['+oli.Adjusted_List__c+'],'+
                                        'Sell_At_Cost__c = ['+oli.Sell_At_Cost__c+'],'+
                                        'product__c = ['+oli.pricebookentry.product2id+'],'+
                                        'Distributor_Discount__c = ['+Distributor_Discount+'],'+
                                        'customer_unit_price__c = ['+customer_unit_price+'],'+
                    'customer_totalprice__c = ['+customer_total_price+'],');
      
      //System.debug('opportunity_cost += '+oli.pricebookentry.product2.cost__c+'  '+oli.pricebookentry.product2.name);      
      
               
            items.add(new Quote_Item__c(quantity__c = oli.quantity, unit_price__c = unit_price, quote__c = qid,discount__c = oli.discount__c,                       
                                        list_price__c = oli.listprice, name = oli.pricebookentry.product2.name, 
                                        description__c = description ,
                                        Adjusted_List__c = oli.Adjusted_List__c,
                                        Sell_At_Cost__c = oli.Sell_At_Cost__c,
                                        product__c = oli.pricebookentry.product2id,
                                        Distributor_Discount__c = Distributor_Discount,
                                        customer_unit_price__c = customer_unit_price,
                    customer_totalprice__c = customer_total_price,
                    sort_id__c = oli.pricebookentry.product2.sort_id__c
                    
                                        ));
                                        
            oli.Distributor_Discount__c = Distributor_Discount;
            
            oliToUpdate.add(oli);
            //update oli;
            }
        }
        
        update oliToUpdate;
        
        if (maintenanceLineItem != null){
          
          
          Decimal AMC_Qualified_Products_Gross_Subtotal = subtotal_hardware_list + subtotal_software_list;
          Decimal AMC_Qualified_Products_Net_Subtotal = subtotal_hardware + subtotal_software;
          Decimal AMC_1_Year_Unit_Cost = 0;
          // 18% of gross qualified product price
          if (maintenanceLineItem.pricebookentry.product2.productcode == 'AMC-18'){
            AMC_1_Year_Unit_Cost = AMC_Qualified_Products_Gross_Subtotal * 0.01 * 18;
          }
          
          // 15% of gross qualified product price
          if (maintenanceLineItem.pricebookentry.product2.productcode == 'AMC-15'){
            AMC_1_Year_Unit_Cost = AMC_Qualified_Products_Gross_Subtotal * 0.01 * 15;
          }
          
          // 18% of net qualified product price
          if (maintenanceLineItem.pricebookentry.product2.productcode == 'AMCNET18'){
            AMC_1_Year_Unit_Cost = AMC_Qualified_Products_Net_Subtotal * 0.01 * 18;
          }
          
          // 15% of net qualified product price
          if (maintenanceLineItem.pricebookentry.product2.productcode == 'AMCNET15'){
            AMC_1_Year_Unit_Cost = AMC_Qualified_Products_Net_Subtotal * 0.01 * 15;
          }
          
          // Custom Maintenance Price
          if (maintenanceLineItem.pricebookentry.product2.productcode == 'AMC Custom'){
            AMC_1_Year_Unit_Cost = (maintenanceLineItem.Adjusted_List__c);//maintenanceLineItem.unitprice;
          }
          
          
          
          WfoPremiseQuote__c qt          = (WfoPremiseQuote__c) controller.getRecord();
          Opportunity op       = [select id,Type from opportunity 
                                where id = :qt.opportunity__c];
                                
             
             
                 
                     
          if ((op.Type == 'New Customer') || (op.Type == 'New System, Existing Customer') )
          { 
            // Minimum of $1500 per year
            if (AMC_1_Year_Unit_Cost < 1500) {
            AMC_1_Year_Unit_Cost = 1500;
            }
          }
          
          // calculate subtotals at list
          Decimal amc_list = AMC_1_Year_Unit_Cost * maintenanceLineItem.Quantity; 
          subtotal_list = subtotal_list + amc_list;  
      subtotal_amc_list = amc_list;
          
          // Apply discounts where applicable
          
          maintenanceLineItem.Adjusted_List__c = AMC_1_Year_Unit_Cost;
          
          // take off customer discount
          if (maintenanceLineItem.Discount__c != null) {                  
            maintenanceLineItem.unitprice = AMC_1_Year_Unit_Cost * ((100 - maintenanceLineItem.Discount__c) * 0.01);
            customer_unit_price           = AMC_1_Year_Unit_Cost * ((100 - maintenanceLineItem.Discount__c) * 0.01);
          }else{
            maintenanceLineItem.unitprice = AMC_1_Year_Unit_Cost;
            customer_unit_price           = AMC_1_Year_Unit_Cost;
          }
          
          // store customer price for display (subtotal and total are the same on purpose)          
          customer_subtotal_amc = customer_unit_price * maintenanceLineItem.Quantity;
          customer_total_price  = customer_unit_price * maintenanceLineItem.Quantity;
          
          // Take off distributor discount (q.Discount_AMC__c = distributor discount as a percent)
          if (q.Discount_AMC__c != null){
            if (q.Discount_AMC__c > 0){
              if (q.Discount_AMC__c > 0)
              {
                amc_has_distributor_discount = true;                
              }
              maintenanceLineItem.unitprice = maintenanceLineItem.unitprice * ((100 - q.Discount_AMC__c) * 0.01) ;
              
              //maintenanceLineItem.totalprice = maintenanceLineItem.unitprice * maintenanceLineItem.Quantity;
            }
          }
          
      
      
      subtotal_amc = maintenanceLineItem.unitprice * maintenanceLineItem.Quantity; 
      maintenanceLineItem.Distributor_Discount__c = q.Discount_AMC__c;
      update maintenanceLineItem;
      
      string description = '';
            if (maintenanceLineItem.pricebookentry.product2.description != null){
              description = maintenanceLineItem.pricebookentry.product2.description;
            }
            description = description.Replace('#BR#','<br/>');
      
          items.add(new Quote_Item__c(quantity__c = maintenanceLineItem.Quantity, 
                                      unit_price__c = maintenanceLineItem.unitprice, 
                                      list_price__c = AMC_1_Year_Unit_Cost, 
                                      Adjusted_List__c = maintenanceLineItem.Adjusted_List__c,
                                      quote__c = qid,
                                      description__c = description,
                                      discount__c = maintenanceLineItem.discount__c,
                                        Sell_At_Cost__c = maintenanceLineItem.Sell_At_Cost__c,
                                        name = maintenanceLineItem.pricebookentry.product2.name,
                                        product__c = maintenanceLineItem.pricebookentry.product2id,                              
                          Distributor_Discount__c = q.Discount_AMC__c,
                                        customer_unit_price__c = customer_unit_price,
                    customer_totalprice__c = customer_total_price,
                    sort_id__c = maintenanceLineItem.pricebookentry.product2.sort_id__c));
           
           //update maintenanceLineItem;
        }
        /* If any line items need to be inserted do so here.*/
        items=sortStandard(items);
        if(items.size() > 0) insert items;
        q          = (WfoPremiseQuote__c) controller.getRecord();
        Opportunity o       = [select id,Quote_Software_Notes__c,Quote_Hardware_Notes__c,Quote_Services_Notes__c,Quote_AMC_Notes__c,Quote_General_Notes__c,Probability//,
        //Overall_Quote_Discount_Dollar__c,
        //Overall_Quote_Discount_Percent__c 
                               from opportunity 
                                where id = :q.opportunity__c];
       
       
        //Decimal Overall_Quote_Discount_Dollar = o.Overall_Quote_Discount_Dollar__c;
        //Decimal Overall_Quote_Discount_Percent = o.Overall_Quote_Discount_Percent__c;
             
        //q.Overall_Quote_Discount_Dollar__c = Overall_Quote_Discount_Dollar;
        //q.Overall_Quote_Discount_Percent__c = Overall_Quote_Discount_Percent;       
                
        //q.Quote_Software_Notes__c = o.Quote_Software_Notes__c;
        //q.Quote_Hardware_Notes__c = o.Quote_Hardware_Notes__c;
        //q.Quote_Services_Notes__c = o.Quote_Services_Notes__c;
        //q.Quote_AMC_Notes__c      = o.Quote_AMC_Notes__c;
        //q.Quote_General_Notes__c  = o.Quote_General_Notes__c; 
        
        o.Quote_Software_Notes__c = q.Quote_Software_Notes__c;
        o.Quote_Hardware_Notes__c = q.Quote_Hardware_Notes__c;
        o.Quote_Services_Notes__c = q.Quote_Services_Notes__c;
        o.Quote_AMC_Notes__c      = q.Quote_AMC_Notes__c;
        o.Quote_General_Notes__c  = q.Quote_General_Notes__c; 
        
        
        q.software_subtotal__c = subtotal_software;
        q.hardware_subtotal__c = subtotal_hardware;
        q.services_subtotal__c = subtotal_services;
        q.other_subtotal__c = subtotal_other;
        q.amc_subtotal__c      = subtotal_amc;
        
        
        q.customer_software_subtotal__c = customer_subtotal_software;
        q.customer_hardware_subtotal__c = customer_subtotal_hardware;
        q.customer_services_subtotal__c = customer_subtotal_services;
        q.customer_other_subtotal__c = customer_subtotal_other;
        q.customer_amc_subtotal__c      = customer_subtotal_amc;
        customer_quote_total_price      = customer_subtotal_software+customer_subtotal_hardware+customer_subtotal_services+customer_subtotal_other+customer_subtotal_amc;
       
        q.customer_total__c        = customer_quote_total_price;
        
        q.software_has_customer_discount__c = software_has_customer_discount;
        q.hardware_has_customer_discount__c = hardware_has_customer_discount;
        q.services_has_customer_discount__c = services_has_customer_discount;
        q.other_has_customer_discount__c = other_has_customer_discount;
        q.amc_has_customer_discount__c = amc_has_customer_discount;
        
        
        q.software_has_distributor_discount__c = software_has_distributor_discount;
        q.hardware_has_distributor_discount__c = hardware_has_distributor_discount;
        q.services_has_distributor_discount__c = services_has_distributor_discount;
        q.amc_has_distributor_discount__c = amc_has_distributor_discount;
        
        
        /*
        q.AppliedSectionDiscountSoftware__c = SalespersonProductSectionDiscount;
        q.AppliedSectionDiscountHardware__c = SalespersonHardwareSectionDiscount;
        q.AppliedSectionDiscountMaintenance__c = SalespersonMaintenanceSectionDiscount;
        q.AppliedSectionDiscountServices__c = SalespersonServicesSectionDiscount;
        */
        q.SectionListSubtotalSoftware__c = subtotal_software_list;
        q.SectionListSubtotalHardware__c =subtotal_hardware_list;
        q.SectionListSubtotalServices__c =subtotal_services_list;
        q.SectionListSubtotalMaintenance__c = subtotal_amc_list;
        
        q.SectionListSubtotalOther__c = subtotal_other_list;
        
        
        subtotal_list = subtotal_software_list + subtotal_services_list + subtotal_hardware_list + subtotal_other_list + subtotal_amc_list;
        
        Decimal Pre_Quote_Discount_Subtotal = q.software_subtotal__c + q.hardware_subtotal__c  + q.services_subtotal__c + q.other_subtotal__c + q.amc_subtotal__c;
        
        o.Amount = Pre_Quote_Discount_Subtotal;
        o.Gross_Amount__c = o.Amount;
        
        
        /* TODO ADD QUOTE LEVEL DISCOUNTING HERE */
        // Variables
        // customer_quote_total_price -> Salesperson_Discount_Percent
        // o.Gross_Amount__c
        // o.Amount = subtotal_quote;
        // subtotal_quote=subtotal_software+subtotal_hardware+subtotal_other+subtotal_services+subtotal_amc;
        
        Decimal subtotal_quote = subtotal_software+subtotal_hardware+subtotal_other+subtotal_services+subtotal_amc;
        
        q.test_data__c = string.valueof(subtotal_software) +' + '+ 
        string.valueof(subtotal_hardware) +' + '+ 
        string.valueof(subtotal_other) +' + '+ 
        string.valueof(subtotal_services)  +' + '+ 
        string.valueof(subtotal_amc);
        
        q.Overall_Quote_Pre_Quotediscount_subtotal__c = subtotal_quote;
        
        Decimal QuoteDiscountedSubtotal = subtotal_quote;
        
        
        /*/ APPLY BOTTOM LINE PERCENTAGE DISCOUNT
        if (Overall_Quote_Discount_Percent > 0)
        {
          
          QuoteDiscountedSubtotal = QuoteDiscountedSubtotal - (QuoteDiscountedSubtotal * Overall_Quote_Discount_Percent);
        }
        // APPLY BOTTOM LINE DOLLAR DISCOUNT
        if (Overall_Quote_Discount_Dollar > 0)
        {
          QuoteDiscountedSubtotal = QuoteDiscountedSubtotal - Overall_Quote_Discount_Dollar;
          
        }
        //Decimal Overall_Quote_Discount_Dollar = op.Overall_Quote_Discount_Dollar__c;
        //Decimal Overall_Quote_Discount_Percent = op.Overall_Quote_Discount_Percent__c;
        */
        q.Overall_Quote_Pre_Quotediscount_amount__c = subtotal_quote - QuoteDiscountedSubtotal;
        
        
        if (subtotal_list > 0) {
          if (o.Gross_Amount__c <= subtotal_list)
            {
              q.Product_Gross_Discount__c = 100 - ( 100 * (o.Gross_Amount__c / subtotal_list));
              o.product_gross_discount_percent__c = 100 - ( 100 * (o.Gross_Amount__c / subtotal_list));
            }
            else
            {
              q.Product_Gross_Discount__c = 0;
              o.product_gross_discount_percent__c = 0;
            }
          
        }else{
          o.product_gross_discount_percent__c =0;  
          q.Product_Gross_Discount__c = 0;
        }

        
        
        Decimal Distributor_Discount_Percent = 0;
        Decimal Salesperson_Discount_Percent = 0;
        
        
        
        
        if (subtotal_list > 0) {
          Salesperson_Discount_Percent = (1 - (customer_quote_total_price/ subtotal_list)) * 100;
        }else {
          Salesperson_Discount_Percent = 0;  
        }
        
        
        // Calculate distributor discount
        
        if (customer_quote_total_price > subtotal_quote){ 
          Decimal distributor_total = subtotal_quote;
          Decimal e = 1;
          if (subtotal_list > 0 ) {
            e = 1 - (customer_quote_total_price/subtotal_list) * subtotal_list;
          }
          Distributor_Discount_Percent =100 * (-1 * (-1 - (distributor_total / e)));
        
        }
        
        o.Product_Salesperson_Discount_Percent__c = Salesperson_Discount_Percent;
        o.Product_Distributor_Discount_Percent__c = Distributor_Discount_Percent;
        
        
        o.Audio_Recording_Amount__c = subtotal_software;
        o.Hardware_Amount__c = subtotal_hardware;
        o.Imp_and_Config_Amount__c = subtotal_services; 
        o.Other_Amount__c = subtotal_other;
        o.Service_Plan_Amount__c     = subtotal_amc;
        

        o.has_quote__c = true;
        o.Amount = subtotal_quote;
       
        update o;
        /* Return the page reference generated by the standard controller save, which usually drops the user
           on the detail page for the newly created object. */
           
        // Update the quote last. Goal is to have the everythign completed when the email workflow is triggered.
        q.subtotal_list_amc__c = subtotal_amc_list;
    q.subtotal_list_hardware__c = subtotal_hardware_list;
    q.subtotal_list_other__c = subtotal_other_list;
    q.subtotal_list_services__c = subtotal_services_list;  
    q.subtotal_list_software__c = subtotal_software_list;  
    q.subtotal_list_total__c = subtotal_list;
    
        q.is_quote_complete__c = 'COMPLETE';
        
        q.Product_Salesperson_Discount__c = Salesperson_Discount_Percent;
        q.Product_Distributor_Discount__c = Distributor_Discount_Percent;

        
        update q;   
        
        
      //  attachQuote();
        
        //update o;   
        return p;
        
    }
    
        /* Sort the collection of opportunities using the standard collection sort method. */
    private static List<Quote_Item__c> sortStandard(List<Quote_Item__c> itemlist) {
        List<Quote_Item__c> resultList = new List<Quote_Item__c>();
    
        /* Create a map of amount to Opportunity collection */
        Map<Decimal, List<Quote_Item__c>> oppMap = new Map<Decimal, List<Quote_Item__c>>();
        
        for(Quote_Item__c o:itemlist) {
            if(oppMap.get(o.sort_id__c) == null) { oppMap.put(o.sort_id__c, new List<Quote_Item__c>()); }
            oppMap.get(o.sort_id__c).add(o);
        }
        
        List<Decimal> keys = new List<Decimal>(oppMap.keySet());
        
        /* Leverage the standard, primitive collection sort method */
        keys.sort();
        
        for(Decimal key:keys) { resultList.addAll(oppMap.get(key)); }
        
        return resultList;
    }
    
    /* The action method that will generate a PDF document from the QuotePDF page and attach it to 
       the quote provided by the standard controller. Called by the action binding for the attachQuote
       page, this will do the work and take the user back to the quote detail page. */
    public PageReference attachQuote() {
      System.debug('attachQuote()');
        /* Get the page definition */
        PageReference pdfPage = Page.quotePDF;
        System.debug('getParameters()');
        /* set the quote id on the page definition */
        pdfPage.getParameters().put('id',q.id);
        
        System.debug('GetRecord()'); 
        WfoPremiseQuote__c qt          = (WfoPremiseQuote__c) controller.getRecord();
        Opportunity op       = [select id,Type,OP_ID__c from opportunity 
                                where id = :qt.opportunity__c];
        System.debug('OP.ID(=)'+op.id);
        /* generate the pdf blob */
        if(!Test.isRunningTest())
        {
            Blob pdfBlob = pdfPage.getContent();
            
            /* create the attachment against the quote */
            Attachment a = new Attachment(parentId = op.id, name='autoattach'+op.OP_ID__c + '.pdf', body = pdfBlob);
            
            /* insert the attachment */
            insert a;
        }
        
        /* send the user back to the quote detail page */
        return controller.view();
    }
}