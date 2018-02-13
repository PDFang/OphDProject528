public class ContactTriggerHandler extends TriggerHandler{

    @TestVisible
    private static boolean isValidatePersonStatusExecuted = false;
    @TestVisible
    private static boolean calloutXMRestPerson = false;


    public override void beforeInsert(){
        callXmPerSonIdAsync((List<Contact>) trigger.new);
    }

    public override void beforeUpdate(){
        dissociatexMattersUid((List<Contact>) trigger.new, (List<Contact>) trigger.old, (Map<Id, Contact>) trigger.oldMap);
    }

    public override void afterUpdate(){

        if(!isValidatePersonStatusExecuted)
            validatePersonStatus((List<Contact>) trigger.new, (List<Contact>) trigger.old, (Map<Id, Contact>) trigger.oldMap); // this shall be the last method call

    }

    protected override void afterDelete(){

        if(!isValidatePersonStatusExecuted)
            validatePersonStatus((List<Contact>) trigger.new, (List<Contact>) trigger.old, (Map<Id, Contact>) trigger.oldMap); // this shall be the last method call

    }


    private static void dissociatexMattersUid(List<Contact> newList, List<Contact> oldList, Map<Id, Contact> oldMap){
        if(oldMap == null)
            return;
        Set<Id> contactIds = new Set<Id>();
        Set<string> contactEmails = new Set<string>();
        set<Id> dupeContactIds = new set<Id>();
        //String emailNew = '';
        String emailOld = '';
        Boolean isDeactivated = false;
        for(Contact newContact : newList){
            contactIds.add(newContact.Id);
            //emailNew = newContact.Email;
        }

        Map<id, Contact> personMap = new map<id, Contact>([select Id, xmPerson__r.xmPersonUID__c from Contact where Id in: contactIds]);
        for(Contact newContact : newList){
            Contact oldContact = oldMap.get(newContact.Id);
            isDeactivated = newContact.Deactivated__c;
            emailOld = oldContact.Email;
            if((newContact.Deactivated__c && oldContact.Deactivated__c == false && newContact.xmPerson__c != null)){
                newContact.XmattersUid__c = personMap.get(newContact.Id).xmPerson__r.xmPersonUID__c;
                newContact.xmPerson__c = null;
            }
            if(!isDeactivated && !newContact.email.equalsIgnoreCase(emailOld)){
                dupeContactIds.add(newContact.Id);
            }
        }
        updateXMPersonId(dupeContactIds);

    }

    private static void callXmPerSonIdAsync(List<Contact> newList){
        Set<Id> contactIds = new Set<Id>();
        for(Contact newContact : newList){
            contactIds.add(newContact.Id);
        }

        updateXMPersonId(contactIds);

    }



    // validate the contact that is deactivated, disassociated or deleted was the only active contact associated with xMatters person
    private static void validatePersonStatus(List<Contact> newList, List<Contact> oldList, Map<Id, Contact> oldMap){
        if(oldMap == null){
            return;
        }

        Set<Id> xmPersonIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();

        List<xmChangeRequestHeaderData> requestList = new List<xmChangeRequestHeaderData>();
        list<Contact> deactivatedContacts = new list<Contact>();
        // update
        if(trigger.isUpdate){

            Set<Id> accountIds = new Set<Id>();
            for(Contact newContact : newList){
                accountIds.add(newContact.AccountId);
            }

            Map<Id, Account> accountMap = new Map<Id, Account>([
                    Select Id, CG_Disconnect_Date__c from Account
                    Where Id IN :accountIds
            ]);

            for(Contact newContact : newList){
                Contact oldContact = oldMap.get(newContact.Id);

                if( (newContact.Deactivated__c && oldContact.Deactivated__c == false && oldContact.xmPerson__c != null)
                        || (newContact.xmPerson__c != oldContact.xmPerson__c && oldContact.xmPerson__c != null))
                {

                    xmPersonIds.add(oldContact.xmPerson__c);
                    contactIds.add(newContact.Id);



                    Account acct = accountMap.get(newContact.AccountId);
                    system.debug ('validatePersonStatus(): acct - ' + acct);

                    //if the account is being deactivated we don't want to add more removal requests for the contacts
                    if (acct != null && acct.CG_Disconnect_Date__c == null ){
                        xmChangeRequestHeaderData newCR = new xmChangeRequestHeaderData();
                        newCR.accountId = newContact.AccountId;
                        newCR.sObjectId = newContact.Id;
                        newCR.sObjectType = 'Contact';
                        requestList.add(newCR);
                    }
                }
            }

            system.debug('validatePersonStatus(): no of contacts deactivated or disassociated - ' + contactIds.size());

        }
        // delete
        else if(trigger.isDelete){

            for(Contact oldContact : oldList){

                if(oldContact.Deactivated__c == false && oldContact.xmPerson__c != null){
                    xmPersonIds.add(oldContact.xmPerson__c);
                    contactIds.add(oldContact.Id);

                    xmChangeRequestHeaderData newCR = new xmChangeRequestHeaderData();
                    newCR.accountId = oldContact.AccountId;
                    newCR.sObjectId = oldContact.Id;
                    newCR.sObjectType = 'Contact';
                    requestList.add(newCR);
                }
            }
            system.debug('validatePersonStatus(): no of contacts deleted - ' + contactIds.size());
        }

        system.debug('validatePersonStatus(): requestList - ' + requestList);

        // create group change request
        if(requestList.size() > 0){

            isValidatePersonStatusExecuted = true;

            xMGroupRequestHelper.CreateGroupChangeRequestHeader(requestList);



        }

        system.debug('validatePersonStatus(): xmPersonIds - ' + xmPersonIds);

        if(xmPersonIds.isEmpty()){
            return;
        }

        Set<Id> activeXmPersonIds = new Set<Id>();

        // find associated contacts if any that are active
        for(Contact cont : [
                Select Id, AccountId, xmPerson__c from Contact
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

        List<xmPerson__c> xmPersonList = new List<xmPerson__c>();

        for(xmPerson__c person : [
                Select Id, xmPersonUID__c from xmPerson__c
                where Id IN :xmPersonIds
                and xmPersonUID__c != null
        ]){
            xmPersonList.add(person);
        }

        if(xmPersonList.isEmpty()){
            return;
        }

        system.debug('deactivateXmPerson(): xmPersonList - ' + xmPersonList);

        XMRestPerson restService = new XMRestPerson();

        for(xmPerson__c person : xmPersonList){

            XMPersonModel newPerson = new XMPersonModel();
            newPerson.id = person.xmPersonUID__c;
            newPerson.status = 'INACTIVE';
            // default to null
            newPerson.roles = null;
            newPerson.recipientType = null;
            newPerson.externallyOwned = null;

            XMPersonModel response;
            try{
                response = restService.modifyPerson(newPerson);
                calloutXMRestPerson = true;
                system.debug('deactivateXmPerson(): response - ' + response);

            }catch(XMCalloutException ex){
                system.debug('deactivateXmPerson(): XMCalloutException - ' + ex);

                // abort unless bad request error
                String statusCode = String.valueOf(ex.HttpStatusCode);
                if(statusCode != '400' && statusCode.startsWith('4') || statusCode.startsWith('5')){
                    inContactBaseClass.SendErrorEmail(ex, person.Id + ' - Error deactivating Person in xMatters');
                    throw ex;
                }
            }

        }

    }

    @Future
    public static void updateXMPersonId(set<Id> dupeContactIds){

        list<contact> newList = [Select Id, Email,xmPerson__c, XmattersUid__c From Contact where id in :dupeContactIds];

        if(newList.size() == 0)
            return;

        set<String> emails = new set<string>();

        for(Contact newContact : newList){
            emails.add(newContact.Email);
        }

        if(emails.size() < 1)
            return;

        map<string, string> contactEmailXmId = new map<string, string>();
        map<string, string> contactEmailXmUId = new map<string, string>();

        for(Contact con : [select Id, Email, xmPerson__c, xmPerson__r.xmPersonUID__c From Contact where Email in : emails and Deactivated__c =: false and xmPerson__c != :null ]){
            if(!contactEmailXmId.containsKey(con.Email)){
                contactEmailXmId.put(con.Email, con.xmPerson__c);
                contactEmailXmUId.put(con.Email, con.xmPerson__r.xmPersonUID__c);
            }
        }

        for(Contact newContact : newList){
            if(contactEmailXmId.containsKey(newContact.Email)){
                newContact.xmPerson__c = contactEmailXmId.get(newContact.Email);
                newContact.XmattersUid__c = null;
            }
            else{
                newContact.xmPerson__c = null;
                newContact.XmattersUid__c = contactEmailXmUId.get(newContact.Email);
            }
        }

        update newList;
    }

}