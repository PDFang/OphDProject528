public with sharing class XMPersonModel {

    public XMPersonModel(){
        this.roles = new String[]{'No Access User'};
        this.recipientType = 'PERSON';
    }

    // This is the Xmatters Unique Id Don't set on create
    public transient String id {get;set;}
    public String targetName {get;set;}
    public String firstName {get;set;}
    public String lastName {get;set;}
    public String recipientType {get;set;}
    public String timezone {get;set;}
    public String[] roles {get;set;}
    public String status {get;set;}
    public boolean externallyOwned {get;set;}
    public String externalKey {get;set;}
}