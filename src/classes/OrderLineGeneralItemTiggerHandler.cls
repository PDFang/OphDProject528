public class OrderLineGeneralItemTiggerHandler extends TriggerHandler  {

    public override void afterUpdate()
    {
        UpdateCustomerOrderStatus();        
        UpdateCustomerOrderRetryStatus();
    }  
    
        
     public static void UpdateCustomerOrderRetryStatus()
    {
        List<OrderLineGeneralItems__c> newList = (List<OrderLineGeneralItems__c>)(trigger.new );
        Map<Id, OrderLineGeneralItems__c> oldMap = (Map<Id, OrderLineGeneralItems__c>)(trigger.oldMap );
        Set<Id> RetryOrderIds = new Set<Id>();
        Set<Id> CanceledIds = new Set<Id>();    
         Set<Id> CompletedPartialIds = new Set<Id>();
        for(OrderLineGeneralItems__c newOrderLineItem : newList)
        {
            OrderLineGeneralItems__c oldOrderLineItem = ( oldMap != null && oldMap.containsKey(newOrderLineItem.Id) ) ? oldMap.get(newOrderLineItem.Id) : null;
          if ( oldOrderLineItem != null
                    && newOrderLineItem.ItemStatus__c == 'Retry'
                    && oldOrderLineItem.ItemStatus__c == 'Failed'
                    )                    
            {   
                System.debug('***Retry Order Ids' + RetryOrderIds); 
                RetryOrderIds.add(newOrderLineItem.CustomerOrder__c);                 
            }
            
            else if ( oldOrderLineItem != null
                    && newOrderLineItem.ItemStatus__c == 'Canceled'
                    && oldOrderLineItem.ItemStatus__c != 'Canceled'
                    )                    
            {           
                CanceledIds.add(newOrderLineItem.CustomerOrder__c);                 
            }           
            
            
        List<CustomerOrder__c> OrderList = new List<CustomerOrder__c>();
        
        if(RetryOrderIds.size() > 0)
        {   
            System.debug('***Retry Order Ids size greater than zero'); 
            for(Id OrderId :RetryOrderIds)
              {
                   CustomerOrder__c order = new CustomerOrder__c(
                    Id = OrderId,
                    OrderStatus__c = 'Retry'
                );
                OrderList.add(order);            
              }    
        }    
        
        if(CanceledIds.size() > 0)
        {        
             System.debug('***Canceled Order Ids size greater than zero'); 
            for(AggregateResult result :[SELECT COUNT(Id), CustomerOrder__c FROM OrderLineGeneralItems__c WHERE CustomerOrder__c IN :CanceledIds 
                                         and ItemStatus__c NOT IN ('none','In Progress','Canceled') 
                                         GROUP BY CustomerOrder__c]){
                if(result.get('expr0') != null && (Integer)result.get('expr0') > 0){                   
                    CanceledIds.remove((Id)result.get('CustomerOrder__c'));
                    CompletedPartialIds.add((Id)result.get('CustomerOrder__c'));
            	}                                          
        	}
             System.debug('***CompletedPartial Order Ids size greater than zero :' + CompletedPartialIds.size()); 
            for(AggregateResult result :[SELECT COUNT(Id), CustomerOrder__c FROM OrderLineGeneralItems__c WHERE CustomerOrder__c IN :CompletedPartialIds 
                                         and ItemStatus__c NOT IN ('Completed','Canceled','none')
                                         GROUP BY CustomerOrder__c]){
                if(result.get('expr0') != null && (Integer)result.get('expr0') > 0){                   
                    CompletedPartialIds.remove((Id)result.get('CustomerOrder__c'));
            	}                                          
        	}
        } 
            
         
        
        
        if(CompletedPartialIds.size() > 0)
        {
            for(Id ComplPartialId : CompletedPartialIds)
            {
                CustomerOrder__c order = new CustomerOrder__c(
                    Id = ComplPartialId,
                    OrderStatus__c = 'Completed (Partial)'
                );
            	OrderList.add(order);            
        	}
        }
            
             if(CanceledIds.size() > 0)
        {
            for(Id CanceledId : CanceledIds)
            {
                CustomerOrder__c order = new CustomerOrder__c(
                    Id = CanceledId,
                    OrderStatus__c = 'Canceled'
                );
            	OrderList.add(order);            
        	}
        }
            
        if(OrderList.size() > 0){
            update OrderList;
            System.debug('****Order List Updated from OrderLineGeneralItemTrigger');
        }

        }
    }       
    
    
    public static void UpdateCustomerOrderStatus()
    {
        List<OrderLineGeneralItems__c> newList = (List<OrderLineGeneralItems__c>)(trigger.new );
        Map<Id, OrderLineGeneralItems__c> oldMap = (Map<Id, OrderLineGeneralItems__c>)(trigger.oldMap );
        Set<Id> CompletedOrderIds = new Set<Id>();
        Set<Id> FailedOrderIds = new Set<Id>();
        Set<Id> CanceledIds = new Set<Id>();
        Set<Id> PartialCompletedIds = new Set<Id>();
        System.debug('**** UpdateCustomerOrderStatus ****');  
        
        for(OrderLineGeneralItems__c newOrderLineItem : newList)
        {
            OrderLineGeneralItems__c oldOrderLineItem = ( oldMap != null && oldMap.containsKey(newOrderLineItem.Id) ) ? oldMap.get(newOrderLineItem.Id) : null;
            if ( oldOrderLineItem != null
                    && newOrderLineItem.ItemStatus__c == 'Completed'
                    && oldOrderLineItem.ItemStatus__c != 'Completed'
                )                    
            {  
                System.debug('**** UpdateCustomerOrderStatus - Completed ****');
                CompletedOrderIds.add(newOrderLineItem.CustomerOrder__c);                    
            }
            
            else if ( oldOrderLineItem != null
                    && newOrderLineItem.ItemStatus__c == 'Failed'
                    && oldOrderLineItem.ItemStatus__c != 'Failed'
                    )                    
            {       
                system.debug('**** UpdateCustomerOrderStatus - Failed ****');
                FailedOrderIds.add(newOrderLineItem.CustomerOrder__c); 
                CompletedOrderIds.remove(newOrderLineItem.CustomerOrder__c);
            }           
           
        }
        
        
        
        if((CompletedOrderIds.isEmpty()) && (FailedOrderIds.isEmpty())){
            return;
        }       

        List<CustomerOrder__c> OrderList = new List<CustomerOrder__c>();
        
        if(CompletedOrderIds.size() > 0)
        {   
            system.debug('**** UpdateCustomerOrderStatus - Completed loop remove ****');
            for(AggregateResult result :[SELECT COUNT(Id), CustomerOrder__c,ItemStatus__c FROM OrderLineGeneralItems__c WHERE CustomerOrder__c IN :CompletedOrderIds 
                                         and ItemStatus__c NOT IN ('Completed','none') 
                                         GROUP BY CustomerOrder__c,ItemStatus__c]){
                if(result.get('expr0') != null && (Integer)result.get('expr0') > 0){
                    CompletedOrderIds.remove((Id)result.get('CustomerOrder__c'));
                    if(result.get('ItemStatus__c') == 'Canceled')
                    {
                        system.debug('**** UpdateCustomerOrderStatus - canceled loop ****');
                        CanceledIds.add((Id)result.get('CustomerOrder__c'));
                    }
                    if(result.get('ItemStatus__c') == 'Failed')
                    {
                        system.debug('**** UpdateCustomerOrderStatus - add to Failed loop ****');
                        FailedOrderIds.add((Id)result.get('CustomerOrder__c'));
                    }                   
                }                                          
            }           
                        
        }    
        
        if(FailedOrderIds.size() > 0|| (CanceledIds.size()>0))
        {
            set<Id> FailedandCanceledIds = new Set<Id>();
			FailedandCanceledIds.addAll(FailedOrderIds);
            FailedandCanceledIds.addAll(CanceledIds);
            system.debug('**** UpdateCustomerOrderStatus - Failed Loop remove****');
            for(AggregateResult result :[SELECT COUNT(Id), CustomerOrder__c FROM OrderLineGeneralItems__c WHERE CustomerOrder__c IN :FailedandCanceledIds
                                         and ItemStatus__c IN ('In Progress', 'New') and (RelatedLineItemStatus__c =NULL OR RelatedLineItemStatus__c IN ('In Progress', 'New','Completed'))
                                         GROUP BY CustomerOrder__c]){
                if(result.get('expr0') != null && (Integer)result.get('expr0') > 0){
                    FailedOrderIds.remove((Id)result.get('CustomerOrder__c'));
                    CanceledIds.remove((Id)result.get('CustomerOrder__c'));                    
            	}                                          
        	}           
           
        }
           
        if(FailedOrderIds.size() > 0)
        {      
             system.debug('**** UpdateCustomerOrderStatus - update to Failed ****');
              for(string OrderId :FailedOrderIds)
              {
                   CustomerOrder__c order = new CustomerOrder__c(
                    Id = OrderId,
                    OrderStatus__c = 'Failed'
                );
                OrderList.add(order);            
              }                           
        }
        
         if(CanceledIds.size() > 0)
        {      
             system.debug('**** UpdateCustomerOrderStatus - update to Processed ****');
              for(string OrderId :CanceledIds)
              {
                   CustomerOrder__c order = new CustomerOrder__c(
                    Id = OrderId,
                    OrderStatus__c = 'Completed (Partial)'
                );
                OrderList.add(order);            
              }                           
        }       
        
        
        if(CompletedOrderIds.size() > 0)
        {
            system.debug('**** UpdateCustomerOrderStatus - update to Completed ****');
            for(Id CompletedorderId : CompletedOrderIds)
            {
                CustomerOrder__c order = new CustomerOrder__c(
                    Id = CompletedorderId,
                    OrderStatus__c = 'Completed'
                );
            	OrderList.add(order);            
        	}
        }
            
        if(OrderList.size() > 0){
            update OrderList;
            System.debug('****Order List Updated from OrderLineGeneralItemTrigger');
        }
    }

}