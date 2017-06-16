@RestResource(urlmapping='/DeliveryNotification/*')
global class XMattersDeliveryWebService {

    @HttpPost
    global static void DeliveryNotification(XMDeliveryReceipt deliveryReceipt){
        RestContext.response.addHeader('Content-Type', 'application/json');
        system.debug('DeliveryNotification() ==> Called with the following values' + deliveryReceipt);

        // Only expect to get one of each back, but this is an easier way to tell if we found something
        List<xmNotification__c> notificationRecord = [SELECT Id from xmNotification__c WHERE Id = : deliveryReceipt.XMNotificationId];
        List<xmPerson__c> xmPeople = [SELECT Id from xmPerson__c WHERE xmPersonUID__c = : deliveryReceipt.XMPersonId];

        // Only create the record if we found both the notification record and the xmPerson record in SF
        if(notificationRecord.size() > 0 && xmPeople.size() > 0){
            xmDelivery__c xmDelivery = new xmDelivery__c();
            xmDelivery.DeliveryStatus__c = deliveryReceipt.Status;
            xmDelivery.Message__c = 'Adding notification for device';
            xmDelivery.xMattersPerson__c = xmPeople[0].Id;
            xmDelivery.XMNotification__c = notificationRecord[0].Id;
            // TODO: Add device list, need to figure out from Mohan what that looks like

            // Set the rest context to indicate that we created the delivery record
            RestContext.response.statusCode = 201;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(xmDelivery));
        } else if(notificationRecord.size() < 1) {
            RestContext.response.statusCode = 415;

            Map<String,String> errorResponse = getErrorMessageResponse('Could not find the XMDelivery Record');

            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(errorResponse));
        } else if (xmPeople.size() < 1){
            RestContext.response.statusCode = 415;

            Map<String,String> errorResponse = getErrorMessageResponse('Could not find the xmPerson record');

            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(errorResponse));
        }

        insert notificationRecord;
    }

    // TODO: Should modify this so that it can add multiple error messages
    private static Map<String, String> getErrorMessageResponse(String errorMessage){
        Map<String,String> errorDictionary = new Map<String, String>();
        errorDictionary.put('ErrorMessage', errorMessage);

        return errorDictionary;
    }
}