/**
 * Created by arnab.karsarkar on 5/4/2017.
 */

public with sharing class XMPersonManagementController {

    public string contactId{get;set;}
    public string emailString{get;set;}
    public string xmPersonId{get;set;}
    public list<XMPersonClass> personLists{get;set;}
    public XMPersonManagementController(ApexPages.StandardController controller){
        contactId = (string)controller.getId();
        emailString = [select Email from Contact where id =: contactId limit 1].Email;
        GetContacts();
    }



    public boolean isPersonMatch
    {
        get
        {
            boolean matchFound = false;
            for(Contact person: [select  xmPerson__c, Id FROM Contact where xmPerson__r.PrimaryContact__r.Email =: emailString]){
                matchFound = true;
                xmPersonId = person.xmPerson__c;
            }
            return matchFound;
        }
        private set;
    }






    public void GetContacts(){

        personLists = new list<XMPersonClass>();
        for(XmPerson__c person: [select  PrimaryContact__c, PrimaryContact__r.AccountId, PrimaryContact__r.Account.Name, PrimaryContact__r.FirstName, PrimaryContact__r.LastName,
                                         PrimaryContact__r.Name, PrimaryContact__r.Email, PrimaryContact__r.Phone
                                        FROM xmPerson__c where PrimaryContact__r.Email =: emailString]){
            XMPersonClass wrapperPerson = new XMPersonClass();
            wrapperPerson.FirstName = person.PrimaryContact__r.FirstName;
            wrapperPerson.LastName = person.PrimaryContact__r.LastName;
            wrapperPerson.Email = person.PrimaryContact__r.Email;
            wrapperPerson.Phone = person.PrimaryContact__r.Phone;
            wrapperPerson.AccountId = person.PrimaryContact__r.AccountId;
            wrapperPerson.AccountName = person.PrimaryContact__r.Account.Name;
            wrapperPerson.ContactId = person.PrimaryContact__c;
            personLists.add(wrapperPerson);
        }



    }



//select Id, AccountId, Account.Name, FirstName, LastName, Name, Email, Phone from Contact where Id =: contactId



    public class XMPersonClass{
        public string FirstName{get;set;}
        public string LastName{get;set;}
        public string Email{get;set;}
        public string Phone{get;set;}
        public string AccountId{get;set;}
        public string AccountName{get;set;}
        public string ContactId{get;set;}
        public XMPersonClass(){

        }
    }
}