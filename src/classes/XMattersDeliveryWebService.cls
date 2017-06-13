@RestResource(urlmapping='/DeliveryNotification/*')
global class XMattersDeliveryWebService {

    @HttpPost
    global static void DeliveryNotification(XMDeliveryReceipt deliveryReceipt){
        RestContext.response.addHeader('Content-Type', 'application/json');
        system.debug('DeliveryNotification() ==> Called with the following values' + deliveryReceipt);

        List<xmNotification__c> notificationRecord = [SELECT Id from xmNotification__c WHERE Id = : deliveryReceipt.XMNotificationId];

        if(notificationRecord.size() > 0){
            xmDelivery__c xmDelivery = new xmDelivery__c();
            xmDelivery.Case__c = deliveryReceipt.CaseId;
            xmDelivery.DeliveryStatus__c = deliveryReceipt.Status;
            xmDelivery.EventType__c = 'Confirmed';  //TODO: Do we pass this?
            xmDelivery.Message__c = 'Adding notification for device';

            RestContext.response.statusCode = 201;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(xmDelivery));
          //  xmDelivery.Device__c = ??
        } else {
            RestContext.response.statusCode = 415;

            Map<String,String> errorResponse = getErrorMessageResponse('Could not find the XMDelivery Record');

            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(errorResponse));
        }

       // insert notificationRecord;
    }

    private static Map<String, String> getErrorMessageResponse(String errorMessage){
        Map<String,String> errorDictionary = new Map<String, String>();
        errorDictionary.put('ErrorMessage', errorMessage);

        return errorDictionary;
    }
}