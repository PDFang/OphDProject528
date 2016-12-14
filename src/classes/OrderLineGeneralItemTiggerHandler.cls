public class OrderLineGeneralItemTiggerHandler extends TriggerHandler  {

    public override void afterUpdate()
    {
        UpdateCustomerOrderStatus();
    }
    
    public static void UpdateCustomerOrderStatus()
    {
        List<OrderLineGeneralItems__c> newList = (List<OrderLineGeneralItems__c>)(trigger.new );
        Map<Id, OrderLineGeneralItems__c> oldMap = (Map<Id, OrderLineGeneralItems__c>)(trigger.oldMap );
        Set<Id> CompletedOrderIds = new Set<Id>();
        Set<Id> FailedOrderIds = new Set<Id>();
        
        for(OrderLineGeneralItems__c newOrderLineItem : newList)
        {
            OrderLineGeneralItems__c oldOrderLineItem = ( oldMap != null && oldMap.containsKey(newOrderLineItem.Id) ) ? oldMap.get(newOrderLineItem.Id) : null;
            if ( oldOrderLineItem != null
                    && newOrderLineItem.ItemStatus__c == 'Completed'
                    && oldOrderLineItem.ItemStatus__c != 'Completed')                    
            {                
                CompletedOrderIds.add(newOrderLineItem.CustomerOrder__c);                    
            }
            
            else if ( oldOrderLineItem != null
                    && newOrderLineItem.ItemStatus__c == 'Failed'
                    && oldOrderLineItem.ItemStatus__c != 'Failed')                    
            {                
                FailedOrderIds.add(newOrderLineItem.CustomerOrder__c); 
                CompletedOrderIds.remove(newOrderLineItem.CustomerOrder__c);
            }
        }
        
         if((CompletedOrderIds.isEmpty()) && (FailedOrderIds.isEmpty())){
            return;
        }
        
         List<CustomerOrder__c> OrderList = new List<CustomerOrder__c>();
        
         if(FailedOrderIds.size() > 0)
        {
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
        for(AggregateResult result :[SELECT COUNT(Id), CustomerOrder__c FROM OrderLineGeneralItems__c WHERE CustomerOrder__c IN :CompletedOrderIds 
                                     and ItemStatus__c != 'Completed'
                                     GROUP BY CustomerOrder__c]){
			if(result.get('expr0') != null && (Integer)result.get('expr0') > 0){
				CompletedOrderIds.remove((Id)result.get('CustomerOrder__c'));
            	}                                          
        	}
        }          
             
        
        for(Id CompletedorderId : CompletedOrderIds){
            CustomerOrder__c order = new CustomerOrder__c(
                Id = CompletedorderId,
                OrderStatus__c = 'Completed'
            );
            OrderList.add(order);            
        }      
               
        if(OrderList.size() > 0){
			update OrderList;
        }

    }
}