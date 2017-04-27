/**
 * Created by ravish.chawla on 4/27/2017.
 */

public class ContactTriggerHandler extends TriggerHandler{

    public override void afterInsert(){
        updateReferencable((list<Contact>)trigger.new, new list<Contact>());
    }

    public override void afterUpdate(){
        updateReferencable((list<Contact>)trigger.new, (list<Contact>)trigger.old);

    }

    private static void updateReferencable(list<Contact> newContactList, list<Contact> oldContactList)
    {
        Set<Id> acctAddRef = new Set<Id>();
        Set<Id> acctRemoveRef = new Set<Id>();

        if(oldContactList.size() == 0)
        {
            //loop through contacts
            for(Contact c:newContactList)
            {
                //get referenceable contacts
                if(c.Referenceable__c)
                {
                    if(!acctAddRef.contains(c.AccountId))
                    {
                        acctAddRef.add(c.AccountId);
                    }
                }
            }
        }
        else
        {
            //loop through triggers
            for(integer i=0; i < newContactList.size(); i++)
            {
                //get new and old contact record
                Contact cn = newContactList[i];
                Contact co = oldContactList[i];

                //get newly referenceable contacts
                if(!co.Referenceable__c && cn.Referenceable__c)
                {
                    if(!acctAddRef.contains(cn.AccountId))
                    {
                        acctAddRef.add(cn.AccountId);
                    }
                }
                else if(co.Referenceable__c && !cn.Referenceable__c)
                {
                    if(!acctRemoveRef.contains(cn.AccountId))
                    {
                        acctRemoveRef.add(cn.AccountId);
                    }
                }
            }
        }

        if(acctAddRef.size() > 0)
            addAccountRef(acctAddRef);

        if(acctRemoveRef.size() > 0)
            removeAccountRef(acctRemoveRef);
    }

    private static void addAccountRef(set<id> acctAddRef)
    {
        //get accounts that need referenced
        Account[] accts = [SELECT Id, Referenceable__c FROM Account WHERE Id IN :acctAddRef AND ReferenceStor__Import_into_ReferenceStor__c = false];

        //make sure accounts are returned
        if(accts.size()>0)
        {
            //loop through accounts and mark them as referenceable
            for(Account a:accts)
            {
                a.Referenceable__c = true;
            }

            //update accounts
            update accts;
        }
    }

    private static void removeAccountRef(set<id> acctRemoveRef)
    {
        //get accounts that need referenced
        Account[] accts = [SELECT Id, Referenceable__c, (select Id from Contacts where Referenceable__c = true)
        FROM Account WHERE Id IN :acctRemoveRef AND ReferenceStor__Import_into_ReferenceStor__c = false];

        //make sure accounts are returned
        if(accts.size()>0)
        {
            //loop through accounts and mark them as referenceable
            for(Account a:accts)
            {
                if(a.Contacts.size() <= 0)
                {
                    a.Referenceable__c = false;
                }
            }

            //update accounts
            update accts;
        }
    }

}