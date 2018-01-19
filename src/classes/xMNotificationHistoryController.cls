/**
 * Created by Antara Bhattacharya on 1/19/2018.
 */

public with sharing class xMNotificationHistoryController {
    public Contact currentContact{get;set;}
    public list<xMNotificationHistoryModel> NotificationHistoryList{get;set;}
    public integer numberOfRec{get;set;}
    public boolean showLink{get;set;}

    public xMNotificationHistoryController(ApexPages.StandardController controller){
        NotificationHistoryList = new list<xMNotificationHistoryModel>();
        string recordParam = ApexPages.currentPage().getParameters().get('numOfRecord');
        string IdParam = ApexPages.currentPage().getParameters().get('Id');

        currentContact = (Contact)controller.getRecord();
        string contactId = currentContact.Id  == null ? IdParam : currentContact.Id;
        showLink = true;

        numberOfRec = recordParam == null ? 5 : Integer.valueOf(recordParam);
        if(contactId == null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Not a valid Contact.'));
            return;
        }

        currentContact =[select xmPerson__c from Contact where Id = :contactId limit 1];
        getNotificationHistory();
    }

    public void getNotificationHistory(){
        string showLinkParam =  ApexPages.currentPage().getParameters().get('showLink');
        showLink = showLinkParam == 'false' ? false : true;
        for(xmDelivery__c delivery :
                            [select xmNotification__r.Case__c,xmNotification__r.Case__r.CaseNumber,  xmNotification__c,
                                    xmNotification__r.Name, xmNotification__r.Case__r.Subject,xmNotification__r.Request_Type__c,
                                    xmNotification__r.Request_Date__c,Device_Type__c, Device__c, DeliveryStatus__c
                                    FROM xmDelivery__c
                                    Where xMattersPerson__c = :currentContact.xmPerson__c
                                    Order By xmNotification__r.Request_Date__c desc Limit :numberOfRec]){

            NotificationHistoryList.add(new xMNotificationHistoryModel(delivery));
        }
    }



}