/**
 * Created by mohandaas.rangaswamy on 4/17/2017.
 */

public class PartnerDocumentPreviewController {

    public String documentUrl{get; private set;}

    public PartnerDocumentPreviewController(){


        List<Partner_Document_Manager__c> records = [
                Select Id, Title__c, Content_Delivery_URL__c from Partner_Document_Manager__c
                where Content_Delivery_URL__c != null and Active__c = true
        ];

        system.debug('records - '+records);
        if(records.size() > 0){
            documentUrl = records[0].Content_Delivery_URL__c;
        }
    }

}