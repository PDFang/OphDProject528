/**
 * Created by Antara Bhattacharya on 1/19/2018.
 */

public class xMNotificationHistoryModel {
    public String CaseId {get;set;}
    public String CaseNumber {get;set;}
    public String CaseSubject {get;set;}
    public String NotificationId {get;set;}
    public String NotificationName {get;set;}
    public String NotificationType{get;set;}
    public String NotificationDate{get;set;}
    public String NotificationDeviceType {get;set;}
    public string NotificationDeliveryDevice{get;set;}
    public String NotifcationDeliveryStatus{get;set;}


    public xMNotificationHistoryModel(xmDelivery__c  delivery ){
                this.CaseId = delivery.xmNotification__r.Case__c;
                this.CaseNumber = delivery.xmNotification__r.Case__r.CaseNumber;
                this.NotificationId = delivery.xmNotification__c;
                this.NotificationName = delivery.xmNotification__r.Name;
                this.CaseSubject = delivery.xmNotification__r.Case__r.Subject;
                this.NotificationType = delivery.xmNotification__r.Request_Type__c;
                this.NotificationDate = delivery.xmNotification__r.Request_Date__c.format();
                this.NotificationDeviceType = delivery.Device_Type__c;
                this.NotificationDeliveryDevice = delivery.Device__c;
                this.NotifcationDeliveryStatus = delivery.DeliveryStatus__c;
    }
}