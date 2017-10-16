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
        Set<Id>  ListofRelatedOrderLineItemIds = new Set<Id>();
        for(OrderLineGeneralItems__c lineItem : lineItems)
        {
            if(lineItem.LineItemResolution__c != null)
            {
                lineItem.ItemStatus__c = lineItem.LineItemResolution__c;
                if(lineItem.ItemStatus__c == 'Canceled')
                     ListofRelatedOrderLineItemIds.add(lineItem.Id);
            }
        }
        List<OrderLineGeneralItems__c> ListofRelatedOrderLineItems = new List<OrderLineGeneralItems__c>();
        ListofRelatedOrderLineItems =[SELECT Id,Name, ItemStatus__c, OrderType__c,ProductName__c, ProductSKU__c, OrderErrorDetail__c  FROM OrderLineGeneralItems__c WHERE CustomerOrder__c = :order.id and ItemStatus__c != 'none' and RelatedLineItem__c IN:ListofRelatedOrderLineItemIds ];
        for(OrderLineGeneralItems__c lineItem : ListofRelatedOrderLineItems)
        {
            lineItem.ItemStatus__c = 'Canceled';
        }
        lineItems.addAll(ListofRelatedOrderLineItems);
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
            options.add(new selectOption('Canceled', 'Canceled'));

            return options;
        }
    }
}