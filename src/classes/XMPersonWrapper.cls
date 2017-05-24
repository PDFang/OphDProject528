public class XMPersonWrapper {

    public string firstName{get;set;}
    public string lastName{get;set;}
    public string contactId{get;set;}
    public string xmPersonId{get;set;}
    public string timezone{get;set;}
    public string status{get;set;}

    public XMPersonWrapper(Contact cont){
        this.firstName = cont.FirstName;
        this.lastName = cont.LastName;
        this.contactId = cont.Id;
        this.xmPersonId = cont.xmPerson__c;
        this.status = 'Active';
    }

    public XMPersonWrapper(XMPersonModel model){

        this.firstName = model.firstName;
        this.lastName = model.LastName;
        this.contactId = model.externalKey;
        this.status = model.status;
        this.timezone = model.timezone;

    }

}