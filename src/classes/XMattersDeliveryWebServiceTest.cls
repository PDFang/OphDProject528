@isTest
Private class XMattersDeliveryWebServiceTest {

    static testMethod void testDeliveryNotification(){

        RestRequest testRequest = new RestRequest();
        testRequest.addHeader('Content-Type', 'application/json');

        testRequest.httpMethod = 'POST';
        testRequest.requestURI = '/services/apexrest/DeliveryNotification';
        String requestJson = '{"deliveryReceipt":{"XMPersonId":"cd874706-1b8e-49e6-aad4-2c9b38f12e3e","XMNotificationId":"aFp3C000000GmiwSAC","Status":"Delivered","DeviceType":"Work Email","DeliveryDate":"26-06-19 20:34:59.625","Device":"testuser@incontact.com"}}';
        testRequest.requestBody = Blob.valueOf(requestJson);

        RestResponse testResponse = new RestResponse();
        RestContext.Request = testRequest;
        RestContext.Response = testResponse;

        XMDeliveryReceipt receipt = new XMDeliveryReceipt();
        receipt.XMNotificationId = 'aFp3C000000GmiwSAC';
        receipt.XMPersonId = 'cd874706-1b8e-49e6-aad4-2c9b38f12e3e';
        receipt.Status = 'Delivered';
        receipt.DeliveryDate = '26-06-19 20:34:59.625';
        receipt.DeviceType = 'Work Email';
        receipt.Device = 'testuser@incontact.com';
        receipt.Message = '';

        XMattersDeliveryWebService.DeliveryNotification(receipt);

        system.debug(testResponse.responseBody);

    }

}