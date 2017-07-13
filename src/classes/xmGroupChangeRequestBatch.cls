/**
 * Created by william.nelson on 7/6/2017.
 */

global class xmGroupChangeRequestBatch implements Database.Batchable<Sobject>, Database.Stateful {
    private string queryString;
     global xmGroupChangeRequestBatch(){
         queryString = 'Select Id, Action__c, Account__c, Contact__c, ImplementedProduct__c, NotificationProfile__r.xmPersonUID__c,' +
                 ' Account__r.inContact_Cluster__c, Account__r.Parentid, Account__r.Verint_Cluster__c,Account__r.NICE_WFM_Cluster__c,Account__r.XMPartnerPrefix__c, ' +
                 'Account__r.NICE_QM_Cluster__c,Account__r.Parent.XMPartnerPrefix__c,ImplementedProduct__r.Product__c from xmGroupChangeRequest__C ' +
                 'where status__c = \'In Queue\' order by NotificationProfile__r.xmPersonUID__c' ;

         system.debug(queryString);
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(queryString);
    }

    global void execute(Database.BatchableContext BC, List<xmGroupChangeRequest__C> scope)
    {
        XMBusinessLayer businessLayer =  new XMBusinessLayer();
        list<XMGroupChangeRequestItem> requestItems = new list<XMGroupChangeRequestItem>();
        Map<String, ProductEventMap__c> nodeMap;
        nodeMap = ProductEventMap__c.getAll();

        for (xmGroupChangeRequest__C changeRequest : scope ) {
            string partnerPrefix;
            ProductEventMap__c productMap = nodeMap.get(changeRequest.ImplementedProduct__r.Product__c);
            system.debug (productMap);
            if (productMap != null) {
                if (changeRequest.Account__r.Parent != null) {
                    partnerPrefix = changeRequest.Account__r.Parent.XMPartnerPrefix__c;
                } else if (changeRequest.Account__r.XMPartnerPrefix__c != null) {
                    partnerPrefix = changeRequest.Account__r.XMPartnerPrefix__c;
                }
                XMBusinessLayer.ProductClusterMapClass prodMap = new XMBusinessLayer.ProductClusterMapClass(
                        productMap.Name,
                        changeRequest.Account__r.inContact_Cluster__c,
                        changeRequest.Account__r.Verint_Cluster__c,
                        changeRequest.Account__r.NICE_WFM_Cluster__c,
                        changeRequest.Account__r.NICE_QM_Cluster__c,
                        partnerPrefix,
                        productMap
                );
                XMGroupProductCluster groupData = businessLayer.GetGroupDataMap(prodMap);
                XMGroupChangeRequestItem item = new XMGroupChangeRequestItem();
                item.groupName = groupData.XmattersGroupName;
                item.personId = changeRequest.NotificationProfile__r.xmPersonUID__c;
                item.ChangeRequestId = changeRequest.Id;
                item.Action= changeRequest.action__c;
                system.debug('Request Item => ' + item);
                requestItems.add(item);
            }

        }
        string requestbody = Json.serialize(requestItems);
        system.debug('Request Body =>' + requestbody);

        xmRestWrapper wrapper = new xmRestWrapper();
        wrapper.callChangeRequestInboundIntegration(requestbody);


    }

    global void finish(Database.BatchableContext BC)
    {

        try
        {

        }
        catch(System.EmailException ex){
            system.debug('finish() EmailException - ' + ex);
        }

    }

    private void sendErrorEmail(Exception ex, String recordId){
        try{

        } catch(System.EmailException emailEx){
            system.debug('sendErrorEmail() EmailException - ' + emailEx);
        }
    }





}