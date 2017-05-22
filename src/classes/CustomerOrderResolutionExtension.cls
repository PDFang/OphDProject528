public class CustomerOrderResolutionExtension {

    private CustomerOrder__c order;
    public String updateAllResolution{get; set;}
    public List<OrderLineGeneralItems__c> lineItems {get;set;}
    public boolean failStatus{get;set;}
    public String apexMessage{get;set;}
    
    public CustomerOrderResolutionExtension (ApexPages.StandardController controller) {
    
        order = (CustomerOrder__c)controller.getRecord();
        GetLineItems();
        ShowPage();
        if(lineItems.isEmpty()) apexMessage = 'No items requiring a resolution.';
        
    }
    
    public void GetLineItems()
    {
        lineItems = [SELECT Id,Name, ItemStatus__c, OrderType__c,ProductName__c, ProductSKU__c, OrderErrorDetail__c, LineItemResolution__c FROM OrderLineGeneralItems__c WHERE CustomerOrder__c = :order.id and ItemStatus__c = 'Failed'];

    }
    
    public PageReference SaveLineItems()
    {
        update lineItems;
        
        return RedirectPage();
    }    
    
    public PageReference RedirectPage(){
        
        PageReference pageRef;
        pageRef = new PageReference('/'+ order.Id);
        
        pageRef.setRedirect(true);
        return pageRef;
    }
    
    public void UpdateAll()
    {
       
        for(OrderLineGeneralItems__c li:lineItems)
        {            
            li.LineItemResolution__c = updateAllResolution;
        }
        
    }

    public boolean ShowPage()
    {
                
        if(order.OrderStatus__c != 'Failed') failStatus = false;
        
        else failStatus = true;
        
        return failStatus;
    }
    
    public List<selectOption> UpdateAllOptions
        {
                get 
                {
                        //new list for holding all of the picklist options
                        List<SelectOption> options = new List<SelectOption>();
                        
                        options.add(new selectOption('', '- Select Resolution -'));
                        
                        options.add(new selectOption('Retry', 'Retry'));
                        options.add(new selectOption('Abandoned', 'Abandoned'));
                                       
                        return options;
                } 
        }
}