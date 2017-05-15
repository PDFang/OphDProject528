public class XMPersonWrapper {

    public string firstName{get;set;}
    public string lastName{get;set;}
    public string email{get;set;}
    public string phone{get;set;}
    public string accountId{get;set;}
    public string accountName{get;set;}
    public string contactId{get;set;}
    public string xmPersonId{get;set;}
    public string timezone{get;set;}
    public string status{get;set;}

    public XMPersonWrapper(Contact cont){
        this.firstName = cont.FirstName;
        this.lastName = cont.LastName;
        this.email = cont.Email;
        this.phone = cont.Phone;
        this.accountId = cont.AccountId;
        this.accountName = cont.Account.Name;
        this.contactId = cont.Id;
        this.xmPersonId = cont.xmPerson__c;
        this.timezone = (cont.xmPerson__c != null && cont.xmPerson__r.Timezone__c != null) ? cont.xmPerson__r.Timezone__c : null;
    }

    public XMPersonWrapper(XMPersonModel model){

        this.firstName = model.firstName;
        this.lastName = model.LastName;
        this.contactId = model.externalKey;
        this.status = model.status;
        this.timezone = model.timezone;

    }

}