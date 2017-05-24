public class OrderLineGeneralItemTiggerHandler extends TriggerHandler  {

    public override void afterUpdate()
    {
        UpdateCustomerOrderStatus();
        Updateafterresolution();
        UpdateCustomerOrderRetryStatus();
    }  
    
    public static void Updateafterresolution()
    {
        System.debug('****Enter After Resolution update');
        List<OrderLineGeneralItems__c> newList = (List<OrderLineGeneralItems__c>)(trigger.new );
        Map<Id, OrderLineGeneralItems__c> oldMap = (Map<Id, OrderLineGeneralItems__c>)(trigger.oldMap );
        Map<Id,string> LineItemResolutionIds = new Map<Id,string>();
        Set<Id> FailedOrderLineItemIds = new Set<Id>();
        List<OrderLineGeneralItems__c> LineItemList = new List<OrderLineGeneralItems__c>();
        Set<Id> FailedOrderIds = new Set<Id>();       
        
        for(OrderLineGeneralItems__c newOrderLineItem : newList)
        {
            OrderLineGeneralItems__c oldOrderLineItem = ( oldMap != null && oldMap.containsKey(newOrderLineItem.Id) ) ? oldMap.get(newOrderLineItem.Id) : null;
            if ( oldOrderLineItem != null
                    && (newOrderLineItem.LineItemResolution__c == 'Retry' || newOrderLineItem.LineItemResolution__c == 'Abandoned') && oldOrderLineItem.ItemStatus__c == 'Failed'
                )                    
            {      
                System.debug('****Add Line Items');
                LineItemResolutionIds.put(newOrderLineItem.Id,newOrderLineItem.LineItemResolution__c);                    
            }          
            
        }
		
          if(LineItemResolutionIds.size() >0)
          {
              for(Id key :LineItemResolutionIds.keySet())
              {
                    OrderLineGeneralItems__c OrderLineItem = new OrderLineGeneralItems__c(  
                    Id = key,    
                    ItemStatus__c = LineItemResolutionIds.get(key)
                );
                  LineItemList.add(OrderLineItem);
              }                     
             
            update LineItemList;
           }
        }     
        
     public static void UpdateCustomerOrderRetryStatus()
    {
        List<OrderLineGeneralItems__c> newList = (List<OrderLineGeneralItems__c>)(trigger.new );
        Map<Id, OrderLineGeneralItems__c> oldMap = (Map<Id, OrderLineGeneralItems__c>)(trigger.oldMap );
        Set<Id> RetryOrderIds = new Set<Id>();
        Set<Id> AbandonedIds = new Set<Id>();
        Set<Id> ProcessedIds = new Set<Id>();
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
                    && newOrderLineItem.ItemStatus__c == 'Abandoned'
                    && oldOrderLineItem.ItemStatus__c == 'Failed'
                    )                    
            {           
                AbandonedIds.add(newOrderLineItem.CustomerOrder__c);                 
            }
            
            else if ( oldOrderLineItem != null
                    && newOrderLineItem.ItemStatus__c == 'Completed'
                    && oldOrderLineItem.ItemStatus__c == 'Retry'
                    )                    
            {           
                ProcessedIds.add(newOrderLineItem.CustomerOrder__c);                 
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
        
        if(AbandonedIds.size() > 0)
        {        
            for(AggregateResult result :[SELECT COUNT(Id), CustomerOrder__c FROM OrderLineGeneralItems__c WHERE CustomerOrder__c IN :AbandonedIds 
                                         and ItemStatus__c NOT IN ('Completed', 'Abandoned','none')
                                         GROUP BY CustomerOrder__c]){
                if(result.get('expr0') != null && (Integer)result.get('expr0') > 0){
                    AbandonedIds.remove((Id)result.get('CustomerOrder__c'));
            	}                                          
        	}
        }   
            
        if(ProcessedIds.size() > 0)
        {        
            for(AggregateResult result :[SELECT COUNT(Id), CustomerOrder__c FROM OrderLineGeneralItems__c WHERE CustomerOrder__c IN :AbandonedIds 
                                         and ItemStatus__c NOT IN ('Failed')
                                         GROUP BY CustomerOrder__c]){
                if(result.get('expr0') != null && (Integer)result.get('expr0') > 0){
                    ProcessedIds.remove((Id)result.get('CustomerOrder__c'));
            	}                                          
        	}
        }    
        
        
        if(AbandonedIds.size() > 0)
        {
            for(Id AbandonedId : AbandonedIds)
            {
                CustomerOrder__c order = new CustomerOrder__c(
                    Id = AbandonedId,
                    OrderStatus__c = 'Processed'
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
            for(AggregateResult result :[SELECT COUNT(Id), CustomerOrder__c FROM OrderLineGeneralItems__c WHERE CustomerOrder__c IN :CompletedOrderIds 
                                         and ItemStatus__c NOT IN ('Completed','none')
                                         GROUP BY CustomerOrder__c]){
                if(result.get('expr0') != null && (Integer)result.get('expr0') > 0){
                    CompletedOrderIds.remove((Id)result.get('CustomerOrder__c'));
                    FailedOrderIds.add((Id)result.get('CustomerOrder__c'));
                }                                          
            }
        }    
        
        if(FailedOrderIds.size() > 0)
        {    
            system.debug('**** UpdateCustomerOrderStatus - Failed Loop remove****');
            for(AggregateResult result :[SELECT COUNT(Id), CustomerOrder__c FROM OrderLineGeneralItems__c WHERE CustomerOrder__c IN :FailedOrderIds 
                                         and ItemStatus__c IN ('In Progress', 'New')
                                         GROUP BY CustomerOrder__c]){
                if(result.get('expr0') != null && (Integer)result.get('expr0') > 0){
                    FailedOrderIds.remove((Id)result.get('CustomerOrder__c'));
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