/**
 * Created by ravish.chawla on 4/27/2017.
 */

public class ContactTriggerHandler extends TriggerHandler{

    public override void afterInsert(){
        updateReferencable((list<Contact>)trigger.new, new list<Contact>());
    }

    public override void afterUpdate(){
        updateReferencable((list<Contact>)trigger.new, (list<Contact>)trigger.old);

        // this shall be the last method call
        validatePersonStatus((List<Contact>) trigger.new, (List<Contact>) trigger.old, (Map<Id, Contact>) trigger.oldMap);

    }

    protected override void afterDelete(){

        // this shall be the last method call
        validatePersonStatus((List<Contact>) trigger.new, (List<Contact>) trigger.old, (Map<Id, Contact>) trigger.oldMap);

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
        Account[] accts = [SELECT Id, Referenceable__c FROM Account WHERE Id IN :acctAddRef AND Referenceable__c = false];

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
        FROM Account WHERE Id IN :acctRemoveRef];

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

    // validate the contact that is deactivated, disassociated or deleted was the only active contact associated with xMatters person
    private static void validatePersonStatus(List<Contact> newList, List<Contact> oldList, Map<Id, Contact> oldMap){

        if(oldMap == null){
            return;
        }

        Set<Id> xmPersonIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();

        // update
        if(newList != null){

            for(Contact newContact : newList){
                Contact oldContact = oldMap.get(newContact.Id);

                if( (newContact.Deactivated__c && oldContact.Deactivated__c == false && oldContact.xmPerson__c != null)
                        || (newContact.xmPerson__c == null && oldContact.xmPerson__c != null))
                {
                    xmPersonIds.add(oldContact.xmPerson__c);
                    contactIds.add(newContact.Id);
                }
            }

            system.debug('validatePersonStatus(): no of contacts deactivated or disassociated - ' + contactIds.size());

        }
        // delete
        else{

            for(Contact oldContact : oldList){

                if(oldContact.Deactivated__c == false && oldContact.xmPerson__c != null){
                    xmPersonIds.add(oldContact.xmPerson__c);
                    contactIds.add(oldContact.Id);
                }
            }

            system.debug('validatePersonStatus(): no of contacts deleted - ' + contactIds.size());
        }

        system.debug('validatePersonStatus(): xmPersonIds - ' + xmPersonIds);

        Set<Id> activeXmPersonIds = new Set<Id>();

        for(Contact cont : [
                Select Id, xmPerson__c from Contact
                Where xmPerson__c IN :xmPersonIds and Deactivated__c = false
                and Id NOT IN :contactIds
        ]){
            activeXmPersonIds.add(cont.xmPerson__c);
        }

        xmPersonIds.removeAll(activeXmPersonIds);

        system.debug('validatePersonStatus(): xmPersonIds to be deactivated - ' + xmPersonIds);

        if(xmPersonIds.isEmpty()){
            return;
        }

        if(xmPersonIds.size() > limits.getLimitCallouts()){
            throw new LimitException('Unable to deactivate ' + xmPersonIds.size() +' associated users in xMatters. Please try again with a smaller batch size.');
        }

        deactivateXmPerson(xmPersonIds);

    }

    // deactivate the person in xMatters
    @Future(callout=true)
    private static void deactivateXmPerson(Set<Id> xmPersonIds){

        Set<String> xmPersonGuids = new Set<String>();

        for(xmPerson__c person : [
                Select xmPersonUID__c from xmPerson__c
                where Id IN :xmPersonIds
                and xmPersonUID__c != null
        ]){
            xmPersonGuids.add(person.xmPersonUID__c);
        }

        if(xmPersonGuids.isEmpty()){
            return;
        }

        system.debug('deactivateXmPerson(): xmPersonGuids - ' + xmPersonGuids);

        XMRestPerson restService = new XMRestPerson();

        for(String personGuid : xmPersonGuids){

            XMPersonModel newPerson = new XMPersonModel();
            newPerson.id = personGuid;
            newPerson.status = 'INACTIVE';
            // default to null
            newPerson.roles = null;
            newPerson.recipientType = null;
            newPerson.externallyOwned = null;

            XMPersonModel response;
            try{
                response = restService.modifyPerson(newPerson);

                system.debug('deactivateXmPerson(): response - ' + response);

            }catch(XMCalloutException ex){
                system.debug('deactivateXmPerson(): XMCalloutException - ' + ex);

                // abort unless bad request error
                String statusCode = String.valueOf(ex.HttpStatusCode);
                if(statusCode != '400' && statusCode.startsWith('4') || statusCode.startsWith('5')){
                    throw ex;
                }
            }

        }

    }

}