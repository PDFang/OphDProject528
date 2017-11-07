public class CustomerOrderTriggerHandler extends TriggerHandler {
@TestVisible private static boolean emailSent;
    
    private static string orgWideEmailAddressId;

    protected override void beforeInsert()
    {        
        InsertCadebillAccountandContact();   
        
    }   
    
    protected override void afterUpdate()
    {
       system.debug('**Venkata** - AfterUpdate');
       GenerateCase();
        try{            
       		OrderCompleted();
            OrderProcessed();
        }catch(Exception e){
            inContactbaseclass.SendErrorEmail(e, trigger.new[0].Id);
        }
    }
    
    private static void OrderCompleted() {
        system.debug('****Calling OrderCompleted()');
        List<CustomerOrder__c> orderList = (List<CustomerOrder__c>) (trigger.new);
        Map<Id, CustomerOrder__c> oldMap = (Map<Id, CustomerOrder__c>) (trigger.oldMap);
        Set<Id> orderIds = new Set<Id>();

        for (CustomerOrder__c custOrder : orderList) {
            System.debug('****ORDERSTATUS' + custOrder.OrderStatus__c);
            CustomerOrder__c oldOrder = (oldMap != null && oldMap.containsKey(custOrder.Id)) ? oldMap.get(custOrder.Id) : null;
            if (oldOrder != null && custOrder.OrderStatus__c == 'Completed' && oldOrder.OrderStatus__c != 'Completed') {
                orderIds.add(custOrder.Id);
            }
        }
        if(orderIds.size() > 0){
            sendOrderCompletedEmail(orderIds);
        }

    }
    
    private static void OrderProcessed() {
		system.debug('****Calling OrderProcessed()');
        List<CustomerOrder__c> orderList = (List<CustomerOrder__c>) (trigger.new);
        Map<Id, CustomerOrder__c> oldMap = (Map<Id, CustomerOrder__c>) (trigger.oldMap);
        Set<Id> orderIds = new Set<Id>();
       
        for (CustomerOrder__c custOrder : orderList) {

            CustomerOrder__c oldOrder = (oldMap != null && oldMap.containsKey(custOrder.Id)) ? oldMap.get(custOrder.Id) : null;
            if (oldOrder != null && custOrder.OrderStatus__c == 'Canceled' && oldOrder.OrderStatus__c != 'Canceled') {
                orderIds.add(custOrder.Id);
            }
        }
        if(orderIds.size() > 0){
            UpdateCaseforCanceledItems(orderIds);
        }
    }

    @Future
    private static void sendOrderCompletedEmail(Set<Id> orderIds){

        Set<Id> AccountIds = new Set<Id>();
        List<CustomerOrder__c> orderList = new List<CustomerOrder__c>();
        for (CustomerOrder__c custOrder : [Select Id, Name, OrderStatus__c, Customer__c, Contact__c from CustomerOrder__c where Id IN :orderIds]) {
            AccountIds.add(custOrder.Customer__c);
            orderList.add(custOrder);
        }

        if(AccountIds.size() <= 0){
            return;
        }
        
        system.debug('****List of Customer Orders Generated with ' + orderList.size() + ' records.');
        List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
        
        system.debug('****List of email object created');
        EmailTemplate templateId = [Select id from EmailTemplate where developername = 'Customer_Order_Completed'];
        
        if(templateId == null){
            throw new EmailException('Template Id for Email Template "Customer_Order_Completed" is null or invalid');
        }
        
        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address ='customersupportnotifications@incontact.com'];								               
       	if(owea.size() > 0)
        {
             system.debug('****Org Wide Email Id : ' + owea.get(0).Id); 
            orgWideEmailAddressId = owea.get(0).Id;
        } 
        
        system.debug('****Template Id has been set to - ' + templateId.Id);
        
        Map<Id, List<Contact>> contactMap = new Map<Id, List<Contact>>();
        	
        system.debug('****Created contactmapping');
        for(Contact con : [SELECT Id, AccountId, Email from Contact where AccountId IN :AccountIds AND Contact_Role__c INCLUDES('MAIN')]){
            List<Contact> conList = contactMap.get(con.AccountId);
            if(conList == null){
                conList = new List<Contact>();
                contactMap.put(con.AccountId,conList);   
            }
            conList.add(con);
        }
        
        system.debug('****ContactMapping populated with ' + contactMap.size() + ' records.');
        
        if(contactMap.size() <= 0){
            return;
        }
        
        boolean orderContactFound = false;
               
        
        for(CustomerOrder__c order : orderList){
            if(order != null && order.OrderStatus__c == 'Completed'){
              system.debug('****Found completed order number - ' + order.Name);       
                //Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();        		  
                List<Contact> contactList = contactMap.get(order.Customer__c);                
                system.debug('****Contact List ' + contactList);
                system.debug('****Contact List generated for all accounts with role of "Main" for Order ' + order.Name);                
                for(Contact emailContact : contactList){
                    system.debug('****Adding new contact to receive email from Contact List');
                    if(emailContact.Email != null){
                        Messaging.SingleEmailMessage mail = CreateSingleEmailMessage(templateId.Id, emailContact.Id, order.Id);
                    	allmsg.add(mail);   
                    }
                    system.debug('****Added mail object for contact to list of email objects successfully');
                    if(emailContact.Id == order.Contact__c){
                        system.debug('****Found Order Contact!');
                        orderContactFound = true;
                    }
                }
                
                //if ordercontact not in list, add order contact email to message list
                if(!orderContactFound){
                    system.debug('****Order Contact not found in list of email recipients, adding manually....');
                    Messaging.SingleEmailMessage mail = CreateSingleEmailMessage(templateId.Id, order.Contact__c, order.Id);
                    allmsg.add(mail);
                    system.debug('****Order Contact added successfully!');
                }
            }
            
            //Reset boolean in case more than one order in list
            orderContactFound = false;
        }
        try{
            if(allmsg.size() > 0){
                emailSent = test.isRunningTest();
                system.debug('****Sending Email objects.....');  
                List<Messaging.SendEmailResult> emailResults = Messaging.sendEmail(allmsg, false);
                system.debug('****Email sent successfully!');
                List<Messaging.SendEmailResult> ErrorEmailResults = new List<Messaging.SendEmailResult>();
                for(Messaging.SendEmailResult result: emailResults){
                    if(!result.isSuccess()){
                        ErrorEmailResults.add(result);
                      }
                }
                if(ErrorEmailResults.size() > 0)
                {
                    system.debug('****Trigger Error Detail Email');
                    sendDetailEmail(ErrorEmailResults);
                }
                    
            }
        }
        catch(EmailException e){
            system.debug('**** emailRunResult(): Email Exception - ' + e); 
        }
        catch(system.Exception ex){
            system.debug('**** emailRunResult(): Exception - ' + ex);            
        }
    }
    
    private static void UpdateCaseforCanceledItems(Set<Id> orderIds){
       system.debug('**** Canceled Set ' + orderIds.Size() + ' records.');
       List<Case> CaseList = new List<Case>(); 
       for (case uCase : [SELECT Id FROM Case WHERE CustomerOrder__c IN :orderIds]) {
           		uCase.DateTimeOfCanceledNotification__c = datetime.now();
          		CaseList.add(uCase);
        }       
       update CaseList;
    }
    
    private static void sendDetailEmail( List<Messaging.SendEmailResult> ErrorEmailResults){
        system.debug('****Entered Error Detail Email');
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setSenderDisplayName('SalesforceAdmins');
        message.setSubject('Salesforce Account Change Error Notification');
        SiteConfiguration__c siteConfig = SiteConfiguration__c.getInstance(UserInfo.getOrganizationId().left(15));
        string[] toAddresses = new String[]{siteConfig.DeveloperErrorEmail__c};        
    	message.setSenderDisplayName(siteConfig.DeveloperErrorFromName__c);        
        message.setToAddresses(toAddresses);

        String thead = '<tr>'
                + '<th>Target Object Id</th>'
                + '<th>Error Message</th>'                
                + '</tr>';
        String tdetailTemplate = '<tr>'
                + '<td>{0}</td>'
                + '<td>{1}</td>'   
                + '</tr>';
        
        String tdetail = '';
        for(Messaging.SendEmailResult  ErrorResult: ErrorEmailResults){           
            tdetail +=  string.format(tdetailTemplate, new String[]{
                    ErrorResult.getErrors()[0].getTargetObjectId(),
                    ErrorResult.getErrors()[0].getMessage()                    
           });   
        }     
        String htmlBody = '<table border="1" cellpadding="5" cellspacing="0">'+thead+tdetail+'</table>';
        system.debug('****Created Error Detail HTML Body');
        message.setHtmlBody(htmlBody);
        try
        {
        	messaging.sendEmail(new  Messaging.SingleEmailMessage[]{message});
        }
        catch(EmailException e){
            system.debug('**** emailRunResult(): Email Exception - ' + e); 
        }        
        system.debug('****Sent Error Detail Email');
    }
    
    public class MyException extends Exception {}
    
    private static Messaging.SingleEmailMessage CreateSingleEmailMessage(String templateId, String contactId, String orderId){
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setOrgWideEmailAddressId(orgWideEmailAddressId);
        //message.setSaveAsActivity(false);
        message.setTemplateId(templateId);
        system.debug('**** Template Id set successfully');
        message.setTargetObjectId(contactId);
        system.debug('****Target Contact Id set to - ' + contactId);
        message.setWhatId(orderId);
        system.debug('****Order Id passed to template - ' + orderId);
        system.debug('****Mail contents - ' + message);
        return message;
    }
    
    public static void GenerateCase()
    {
        List<CustomerOrder__c> newList = (List<CustomerOrder__c>)(trigger.new);       
        Map<Id, CustomerOrder__c> oldMap = (Map<Id, CustomerOrder__c>)(trigger.oldMap );

        Set<CustomerOrder__c> FailedOrders = new Set<CustomerOrder__c>();
        Set<CustomerOrder__c> DIDOrders = new Set<CustomerOrder__c>();
        for(CustomerOrder__c newOrder : newList)
        {
            Account[] accts =[SELECT CG_Disconnect_Date__c FROM Account WHERE CadebillAccountNo__c =: newOrder.CadebillAccountNumber__c];
            if(!(accts.size() > 0 && accts[0].CG_Disconnect_Date__c !=null))
            {
            CustomerOrder__c oldOrder = ( oldMap != null && oldMap.containsKey(newOrder.Id) ) ? oldMap.get(newOrder.Id) : null;
            	if ( oldOrder != null
                    && newOrder.OrderStatus__c == 'Failed'
                    && oldOrder.OrderStatus__c != 'Failed')                    
            	{         
                	FailedOrders.add(newOrder);                
            	}
            }            
        }

        for(OrderLineGeneralItems__c OrderLineItem : [SELECT CustomerOrder__c,OrderErrorDetail__c,Name FROM OrderLineGeneralItems__c
        WHERE OrderLineGeneralItems__c.CustomerOrder__c IN :newList AND OrderLineGeneralItems__c.InstrumentType__c =: 12554]){
            CustomerOrder__c order = [Select Id, Customer__c, Contact__c from CustomerOrder__c where Id = :OrderLineItem.CustomerOrder__c];
            DIDOrders.Add(order);
        }

        
        Map<Id, List<OrderLineGeneralItems__c>> OrderLineItemMap = new Map<Id, List<OrderLineGeneralItems__c>>(); 
         if(FailedOrders.size() > 0)
        { 
            system.debug('**Venkata** -' + FailedOrders.size());
            for(OrderLineGeneralItems__c OrderLineItem :[SELECT CustomerOrder__c,OrderErrorDetail__c,Name FROM OrderLineGeneralItems__c 
                                                         WHERE OrderLineGeneralItems__c.CustomerOrder__c IN :FailedOrders AND OrderLineGeneralItems__c.ItemStatus__c =:'Failed']){  
                List<OrderLineGeneralItems__c> FailedOrderLineItems = OrderLineItemMap.get(OrderLineItem.CustomerOrder__c);
                if(FailedOrderLineItems == null){
                 FailedOrderLineItems = new List<OrderLineGeneralItems__c>();
                 OrderLineItemMap.put(OrderLineItem.CustomerOrder__C,FailedOrderLineItems);   
                }
                FailedOrderLineItems.add(OrderLineItem);
                system.debug('**Venkata** -' + FailedOrderLineItems.size());
            }                
         }        
       
         	Schema.DescribeSObjectResult d = Schema.SObjectType.Case;
            Map<String,Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();
       	    Id serviceRequestRecordType = rtMapByName.get('Work Orders').getRecordTypeId(); 
       List<Case> CaseList = new List<Case>();    
       for(CustomerOrder__c CustOrder :FailedOrders)
       {
           List<OrderLineGeneralItems__c> FailedOrderLineItems = OrderLineItemMap.get(CustOrder.Id);
           if(FailedOrderLineItems!= NULL && !FailedOrderLineItems.isEmpty())
           {
               Case nCase = new Case();
               database.DMLOptions dmo = new database.DMLOptions();
               dmo.assignmentRuleHeader.useDefaultRule = true;
               dmo.EmailHeader.triggerUserEmail = true; 
               String link = url.getSalesforceBaseUrl().toExternalForm() + '/' +CustOrder.Id;           
               nCase.AccountID  = CustOrder.Customer__c;
               nCase.ContactId = CustOrder.Contact__c;           
               nCase.Subject  = 'CSO Provisioning Error: ' + 'IP Voice/inContact Softphone' ;
               nCase.Origin = 'CSO Middleware';
               
               string Description = 'One or more errors have occurred on CSO Order: '+ CustOrder.Name + ' - ' + link;
               for(OrderLineGeneralItems__c FailedOrder : FailedOrderLineItems)
               {
                   string FailedOrderLink = url.getSalesforceBaseUrl().toExternalForm() +'/' +FailedOrder.Id;
                   Description +=  '\n' + FailedOrder.Name + '- ' + FailedOrderLink + ' and Error Description : ' + FailedOrder.OrderErrorDetail__c ;
                   system.debug('**Venkata** -' +Description);
               }
               nCase.Description = Description;         
               nCase.Request_Type__c='CSO Real Time Error Handling';
               nCase.Product_or_Service__c ='CSO';
               nCase.SubProductorService__c ='IP Voice/inContact Softphone';
               nCase.Priority ='P2';          
               nCase.RecordTypeId   = serviceRequestRecordType;
               nCase.IsVisibleInSelfService =true;
               nCase.Status = 'New';
               nCase.CustomerOrder__c = CustOrder.Id;
               nCase.setOptions(dmo);
               CaseList.add(nCase);
            }
       }
        if(DIDOrders.size() > 0)
        {
            system.debug('**Janani** -' + DIDOrders.size());
            for(CustomerOrder__c CustOrder :DIDOrders) {
                List<OrderLineGeneralItems__c> OrderLineItems = OrderLineItemMap.get(CustOrder.Id);
                if (OrderLineItems != NULL && !OrderLineItems.isEmpty()) {
                    Case nCase = new Case();
                    database.DMLOptions dmo = new database.DMLOptions();
                    dmo.assignmentRuleHeader.useDefaultRule = true;
                    dmo.EmailHeader.triggerUserEmail = true;
                    String link = url.getSalesforceBaseUrl().toExternalForm() + '/' + CustOrder.Id;
                    nCase.AccountID = CustOrder.Customer__c;
                    nCase.ContactId = CustOrder.Contact__c;
                    nCase.Subject = 'DID Test: ' + 'DID' ;
                    nCase.Origin = 'TEST';

                    string Description = 'Testing DID ' + CustOrder.Name + ' - ' + link;

                    nCase.Description = Description;
                    nCase.Request_Type__c = 'CSO Real Time Error Handling';
                    nCase.Product_or_Service__c = 'CSO';
                    nCase.SubProductorService__c = 'DID';
                    nCase.Priority = 'P2';
                    nCase.RecordTypeId = serviceRequestRecordType;
                    nCase.IsVisibleInSelfService = true;
                    nCase.Status = 'New';
                    nCase.CustomerOrder__c = CustOrder.Id;
                    nCase.setOptions(dmo);
                    CaseList.add(nCase);
                }
            }
        }
        insert CaseList;
    }  
     
    public static void InsertCadebillAccountandContact(){
        
        List<CustomerOrder__c> orderList = (List<CustomerOrder__c>)(trigger.new);
        Set<string> usernameSet = new Set<string>();
        
        system.debug('orderList - '+orderList);
        Set<Integer> cadebillAccounts = new Set<Integer>();
        for(CustomerOrder__c newCustomerOrder : orderList){
            // add validation
            if(newCustomerOrder.Customer__c == null && newCustomerOrder.CadebillAccountNumber__c == null){
                newCustomerOrder.addError('Cadebill Account Number cannot be blank.');
                continue;
            }
            // process only if Customer__c is null and CadebillAccountNumber__c is not null
            if(newCustomerOrder.Customer__c == null && newCustomerOrder.CadebillAccountNumber__c != null){
                Integer cbAccount = Integer.valueOf(newCustomerOrder.CadebillAccountNumber__c);
                cadebillAccounts.add(cbAccount);
            }
            
             usernameSet.add(newCustomerOrder.Username__c);
        }
        //system.debug('cadebillAccounts - '+cadebillAccounts);
        // return if none of the orders require an update
        //if(cadebillAccounts.isEmpty()){
           // return;
        //}
        
        // use map collection here so to avoid nested for loops below
        Map<Integer, Account> accountMap = new Map<Integer, Account>();

        if(cadebillAccounts.size() > 0){
            for(Account acct :[SELECT Id, CadebillAccountNo__c FROM Account WHERE CadebillAccountNo__c IN :cadebillAccounts]){
                accountMap.put(Integer.valueOf(acct.CadebillAccountNo__c), acct);        
            }
        } 
        
        Set<Id> AccountIds = new Set<Id>();
        for(CustomerOrder__c cOrder: orderList){
            if(cOrder.Customer__c == null){
                // incoming from support site
                Account sfAccount = accountMap.get(Integer.valueOf(cOrder.CadebillAccountNumber__c));
                // make use of map collection methods containsKey and get here
                if(sfAccount == null){
                    cOrder.addError('Account '+ cOrder.CadebillAccountNumber__c + ' does not exist in Salesforce.');
                    continue;
                }                
                cOrder.Customer__c = sfAccount.Id; 
            }            
          AccountIds.add(cOrder.Customer__c);
        }
            
          system.debug('**Venkata** cadebillAccountIds - '+AccountIds);   
     
        Map<string, Contact> ContactMap = new Map<string, Contact>();        
        for(Contact cont :[SELECT Id,AccountId,Username__c FROM Contact WHERE AccountId IN :AccountIds and Username__c IN :usernameSet ]){               
            string ContactKey = cont.AccountId + cont.Username__c;
            ContactMap.put(ContactKey, cont);
      
             for(CustomerOrder__c CustOrder: orderList){
                if(ContactMap.containsKey(CustOrder.Customer__c+CustOrder.Username__c))
                {
                    CustOrder.Contact__c = ContactMap.get(CustOrder.Customer__c+CustOrder.Username__c).Id;                
                }
            }
        }
    }
}