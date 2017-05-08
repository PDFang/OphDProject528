public class CustomerOrderController {
    public string customerOrderId { get; set; } //set by CustomerOrderComponent
    public GeneralItems[] orderItems;
    
    public CustomerOrderController() {}
    
    public GeneralItems[] GetOrderItems(){
        orderItems = new List<GeneralItems>();
        
        AggregateResult[] results = [select count(Product2__c) Quantity, Product2__r.Name ProductName, OrderType__c 
                        from orderlinegeneralitems__C 
                        where CustomerOrder__c = :customerOrderId 
                                     group by Product2__r.Name, OrderType__c
                                     order by Product2__r.Name, OrderType__C];
        if(results!= null){
            for(AggregateResult result : results){
                orderItems.add(new GeneralItems(result));            
            }            
        }
        return orderItems;
    }
    
    public class GeneralItems{
        public integer Quantity { get; private set; }
        public string Name { get; private set; }
        public string OrderType { get; private set; }
        
        public GeneralItems(AggregateResult ar){
            Quantity = (Integer)ar.get('Quantity');
            Name = (string)ar.get('ProductName');
            OrderType = (string)ar.get('OrderType__c');
        }
    }
}