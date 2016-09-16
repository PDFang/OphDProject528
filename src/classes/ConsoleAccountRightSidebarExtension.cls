public with sharing class ConsoleAccountRightSidebarExtension 
{
    private Account acct;
    
    
    public ConsoleAccountRightSidebarExtension(ApexPages.StandardController controller) 
    {
        this.acct = (Account)controller.getRecord();
    }
    
    public List<Contact> contactList
    {
        get
        {
            return [SELECT Id, LastName, FirstName, Contact_Role__c, Email, Phone FROM Contact WHERE AccountId = :acct.Id AND Deactivated__c = false ORDER BY FirstName, LastName];
        }
    }
    
    public List<Case> caseList
    {
        get
        {
            return [SELECT Id, CaseNumber, Priority, Owner.Name, Subject, RecordType.Name, Status FROM Case WHERE AccountId = :acct.Id AND IsClosed = false ORDER BY Priority];
        }
    }

}