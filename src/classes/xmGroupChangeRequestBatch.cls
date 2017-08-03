/**
 * Created by william.nelson on 7/6/2017.
 */

global class xmGroupChangeRequestBatch implements Database.Batchable<Sobject>, Database.Stateful, Database.AllowsCallouts {
    private string queryString;
    global xmGroupChangeRequestBatch(){
        queryString = 'Select Id, Action__c, Account__c, Contact__r.xmPerson__c, Contact__c, ImplementedProduct__c,NotificationProfile__c, NotificationProfile__r.xmPersonUID__c,' +
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
        try{
            system.debug('*** xmGroupChangeRequestBatch Execute **** ');
            XMBusinessLayer businessLayer =  new XMBusinessLayer();
            list<XMGroupChangeRequestItem> requestItems = new list<XMGroupChangeRequestItem>();
            Map<String, ProductEventMap__c> nodeMap;
            nodeMap = ProductEventMap__c.getAll();
            set<string> xmPersonIds = new set<string>();
            set<string> productIds = new set<string>();
            set<string> clusters = new set<string>();
            list<ChangeRequestxmPersonProduct> lstCRxmPersonProducts = new list<ChangeRequestxmPersonProduct>();

            for (xmGroupChangeRequest__C changeRequest : scope ) {
                string partnerPrefix;
                // system.debug('changeRequest.ImplementedProduct__r.Product__c => +' + changeRequest.ImplementedProduct__r.Product__c);
                ProductEventMap__c productMap = nodeMap.get(changeRequest.ImplementedProduct__r.Product__c);
                // system.debug (productMap);
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
                    xmPersonIds.add(changeRequest.NotificationProfile__c);
                    productIds.add(groupData.Product);
                    clusters.add(groupData.Cluster.substring(0, groupData.Cluster.indexOf(' - ')));
                    lstCRxmPersonProducts.add(new ChangeRequestxmPersonProduct(groupData,changeRequest.NotificationProfile__r.xmPersonUID__c, changeRequest.Id, changeRequest.Action__c));
                }
            }
            map<string, boolean> activeProductxmPerson = ProductActiveOnAnotherAccount(xmPersonIds,productIds, clusters);

            for(ChangeRequestxmPersonProduct request: lstCRxmPersonProducts){
                string productxmPerson =  request.xmPersonId + '~' + request.groupData.Product;
               // system.debug('productxmPerson =>' + productxmPerson);
                if (!activeProductxmPerson.containsKey(productxmPerson)){
                    XMGroupChangeRequestItem item = new XMGroupChangeRequestItem();
                    item.groupName = request.groupData.XmattersGroupName;
                    item.personId = request.xmPersonId;
                    item.ChangeRequestId = request.ChangeRequestId;
                    item.Action= request.Action;
                    requestItems.add(item);
                }
            }

            //check to see if this xmperson belongs to another account with the product that is active

            if(requestItems.size() > 0){
                string requestbody = Json.serialize(requestItems);
                system.debug('Request Body =>' + requestbody);

                xmRestWrapper wrapper = new xmRestWrapper();
                wrapper.callChangeRequestInboundIntegration(requestbody);
            }

            for(xmGroupChangeRequest__C changeRequest : scope){
                changeRequest.Status__c = 'Processed';
            }

            update scope;

        }catch (Exception  ex){
            inContactBaseClass.SendErrorEmail(ex, 'Error in Batch class to process change requests in Xmatters');
        }
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


    public map<string,boolean> ProductActiveOnAnotherAccount(set<string> xmPersonIds, set<string> productIds, set<string> clusters ){
        map<string,string> acctXmPersonIds = new map<string,string>();
        map<string, boolean> activeProductxmPerson = new map<string, boolean>();

      //  system.debug('clusters ==>' + clusters);
        for (contact con :  [Select AccountId, xmPerson__r.xmPersonUID__c from Contact Where xmPerson__c in :xmPersonIds and xmPerson__c != null]){
            acctXmPersonIds.put(con.AccountId, con.xmPerson__r.xmPersonUID__c);
        }

        //system.debug('acctXmPersonIds ==>' + acctXmPersonIds);
        //system.debug('productIds ==>' + productIds);
        if (acctXmPersonIds.size() > 0){
            //need to check if other accounts has the same active product
           // system.debug('acctXmPersonIds ==>' + acctXmPersonIds);
            for(ImplementedProduct__c product : [select Account__c, product__c FROM ImplementedProduct__c where product__C in: productIds and DeactivatedDate__c = null and
            Account__c in : acctXmPersonIds.keySet() and (Account__r.inContact_Cluster__c in: clusters or
            Account__r.inView_Cluster__c in : clusters or Account__r.Verint_Cluster__c in: clusters)]){
                string productxmPerson = acctXmPersonIds.get(product.Account__c) + '~' + product.Product__c;
                //system.debug('productxmPerson in method  ==>' + productxmPerson);
                activeProductxmPerson.put(productxmPerson, true);
            }

        }

        return activeProductxmPerson;
    }

    public class ChangeRequestxmPersonProduct{
        public XMGroupProductCluster GroupData;
        public string xmPersonId;
        public string ChangeRequestId;
        public string Action;

        public ChangeRequestxmPersonProduct(XMGroupProductCluster grp, string xmPerson, string cr, string action){
            this.GroupData = grp;
            this.xmPersonId = xmPerson;
            this.ChangeRequestId = cr;
            this.Action = action;
        }

    }

}