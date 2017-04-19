/**
 * Created by mohandaas.rangaswamy on 4/17/2017.
 */

public class PartnerDocumentPreviewController {

    private Partner_Document_Manager__c record;
    private String documentId;
    public String documentUrl{get; private set;}

    public PartnerDocumentPreviewController(){

        try{
            documentId = ApexPages.currentPage().getParameters().get('id');
            if(string.isBlank(documentId)){
                documentId = '0693C000000CjEqQAK';
            }
            List<Partner_Document_Manager__c> records = [
            Select Id, Title__c, Expiration_Date__c, Generate_URL__c, Content_Delivery_URL__c from Partner_Document_Manager__c
            where ContentDocumentId__c = :documentId and Content_Delivery_URL__c != null and Active__c = true
            ];

            system.debug('records - '+records);
            //if(records.size() > 0){
                documentUrl = records[0].Content_Delivery_URL__c;
                record = records[0];
            //}
        }catch(Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error while loading the document.'));
        }

    }

//    public void CreateContentDelivery(){
//
//        record.Generate_URL__c = true;
//        update record;
//
//        List<Partner_Document_Manager__c> records = [
//                Select Id, Title__c, Expiration_Date__c, Generate_URL__c, Content_Delivery_URL__c from Partner_Document_Manager__c
//                where ContentDocumentId__c = :documentId and Content_Delivery_URL__c != null and Active__c = true
//        ];
//        documentUrl = records[0].Content_Delivery_URL__c;
//
//    }

}