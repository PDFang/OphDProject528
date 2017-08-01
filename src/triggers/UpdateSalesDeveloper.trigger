trigger UpdateSalesDeveloper on Lead (before insert, before update)
{

    Set<Id> ownerIds = new Set<Id>();
    Set<Id> sdOwnerIds = new Set<Id>();

    for(Lead l:trigger.new)
    {
        if(l.ownerId != null)
        {
            // check that owner is a user (not a queue) and if owner name has changed
            if(!ownerIds.contains(l.OwnerId) && ((String)l.OwnerId).substring(0,3) == '005')
            {
                ownerIds.add(l.OwnerId);
            }
        }
    }
    // filter ownerIds for where user role is "Sales Developer" or "Manager, Business Development" or "Business Development - UCaaS" or “Partner Manager, EMEA”
    Map<Id, User> owners = new Map<Id, User>([SELECT Id, UserRole.Name FROM User WHERE Id IN :ownerIds AND (UserRole.Name = 'Sales Developer' OR UserRole.Name = 'Manager, Business Development' OR UserRole.Name = 'Business Development - UCaaS')]);


    for(integer i=0; i < trigger.new.size(); i++)
    {

        Lead ln = trigger.new[i];

        if(ln.ownerId != null)
        {

            if(((String)ln.OwnerId).substring(0,3) == '005' )
            {
                if(trigger.isUpdate)
                {
                    Lead lo = trigger.old[i];

                    if(lo.OwnerId != ln.OwnerId && owners.ContainsKey(ln.OwnerId))
                    {
                        ln.Sales_Developer__c = ln.OwnerId;
                    }

                }
                else
                {
                    if(owners.ContainsKey(ln.OwnerId))
                    {
                        ln.Sales_Developer__c = ln.OwnerId;
                    }
                }
            }
        }
    }


}