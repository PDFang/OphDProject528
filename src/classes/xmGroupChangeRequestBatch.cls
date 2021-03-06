/**
 * Created by william.nelson on 7/6/2017.
 */

global class xmGroupChangeRequestBatch implements Database.Batchable<Sobject>, Database.Stateful, Database.AllowsCallouts {

    public string queryString;

    global xmGroupChangeRequestBatch(){
        queryString = 'Select Id, Action__c, Account__c, Maintenance__c, Contact__r.xmPerson__c, Contact__c, ImplementedProduct__c, xMDeviceId__c, NotificationProfile__c, NotificationProfile__r.xmPersonUID__c,' +
                ' Account__r.inContact_Cluster__c, Account__r.inView_Cluster__c, Account__r.Parentid, Account__r.Verint_Cluster__c,Account__r.NICE_WFM_Cluster__c,Account__r.XMPartnerPrefix__c, ' +
                'Account__r.NICE_QM_Cluster__c,Account__r.Parent.XMPartnerPrefix__c,ImplementedProduct__r.Product__c from xmGroupChangeRequest__C ' +
                'where status__c = \'In Queue\' order by NotificationProfile__r.xmPersonUID__c' ;

        system.debug(queryString);
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(queryString);
    }

    global void execute(Database.BatchableContext BC, List<xmGroupChangeRequest__C> scope)
    {

        Boolean isException = false;
        Map<Id, XMGroupChangeRequestItem> changeRequestItemMap = new Map<Id, XMGroupChangeRequestItem>();

        try{
            system.debug('*** xmGroupChangeRequestBatch Execute **** ');
            XMBusinessLayer businessLayer =  new XMBusinessLayer();
            list<XMGroupChangeRequestItem> requestItems = new list<XMGroupChangeRequestItem>();
            Map<String, ProductEventMap__c> nodeMap;
            nodeMap = ProductEventMap__c.getAll();
            set<string> xmPersonIds = new set<string>();
            set<string> productIds = new set<string>();
            set<string> clusters = new set<string>();
            set<string> accountXmPersonIds = new set<string>();
            list<ChangeRequestxmPersonProduct> lstCRxmPersonProducts = new list<ChangeRequestxmPersonProduct>();

            for (xmGroupChangeRequest__C changeRequest : scope ) {
                string partnerPrefix;
                // system.debug('changeRequest.ImplementedProduct__r.Product__c => +' + changeRequest.ImplementedProduct__r.Product__c);
                ProductEventMap__c productMap = nodeMap.get(changeRequest.ImplementedProduct__r.Product__c);
                // system.debug (productMap);
                businessLayer.notificationType = null;
                if(changeRequest.Maintenance__c)
                    businessLayer.notificationType = 'MaintType';

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
                    clusters.add( changeRequest.Account__r.inContact_Cluster__c);
                    clusters.add( changeRequest.Account__r.Verint_Cluster__c);
                    clusters.add( changeRequest.Account__r.inView_Cluster__c);
                    clusters.add( changeRequest.Account__r.NICE_QM_Cluster__c);
                    clusters.add( changeRequest.Account__r.NICE_WFM_Cluster__c);
                    accountXmPersonIds.add( changeRequest.Account__c + '-' + changeRequest.NotificationProfile__c);
                    if(changeRequest.xMDeviceId__c != null){
                        XMGroupChangeRequestItem item = new XMGroupChangeRequestItem();
                        item.groupName = groupData.XmattersGroupName;
                        item.personId = changeRequest.NotificationProfile__r.xmPersonUID__c;
                        item.ChangeRequestId = changeRequest.Id;
                        item.Action= changeRequest.Action__c;
                        item.deviceId = changeRequest.xMDeviceId__c;
                        requestItems.add(item);

                        changeRequestItemMap.put(item.ChangeRequestId, item);
                    }else{
                        lstCRxmPersonProducts.add(new ChangeRequestxmPersonProduct(groupData,changeRequest.NotificationProfile__r.xmPersonUID__c, changeRequest.Id, changeRequest.Action__c));
                    }

                }
            }
            map<string, boolean> activeProductxmPerson = ProductActiveOnAnotherAccount(accountXmPersonIds, xmPersonIds,productIds, clusters, nodeMap);
            system.debug('activeProductxmPerson =>' + activeProductxmPerson);

            for(ChangeRequestxmPersonProduct request: lstCRxmPersonProducts){
                string productxmPerson =  request.xmPersonId + '~' + request.groupData.Product + '~' + request.groupData.Cluster;
                system.debug('productxmPerson =>' + productxmPerson);
                if(request.Action == 'Add' || (request.Action == 'Remove' && !activeProductxmPerson.containsKey(productxmPerson)) ){
                    XMGroupChangeRequestItem item = new XMGroupChangeRequestItem();
                    item.groupName = request.groupData.XmattersGroupName;
                    item.personId = request.xmPersonId;
                    item.period = null; //clear this for now
                    item.ChangeRequestId = request.ChangeRequestId;
                    item.Action= request.Action;
                    requestItems.add(item);

                    changeRequestItemMap.put(item.ChangeRequestId, item);
                }
            }

            //check to see if this xmperson belongs to another account with the product that is active

            if(requestItems.size() > 0){
                string requestbody = Json.serialize(requestItems);
                system.debug('Request Body =>' + requestbody);

                xmRestWrapper wrapper = new xmRestWrapper();
                wrapper.callChangeRequestInboundIntegration(requestbody);
            }

        }catch (Exception  ex){
            isException = true;
            inContactBaseClass.SendErrorEmail(ex, 'Error in Batch class to process change requests in Xmatters');
        } finally {

            for(xmGroupChangeRequest__C changeRequest : scope){
                changeRequest.Status__c = isException ? 'Failed' : 'Processed';
                changeRequest.Group_Name__c = changeRequestItemMap.containsKey(changeRequest.Id) ? changeRequestItemMap.get(changeRequest.Id).groupName : null;
            }

            update scope;

        }
    }

    global void finish(Database.BatchableContext BC)
    {
        List<CronTrigger> jobs = new list<CronTrigger>([SELECT Id, CronJobDetail.Name, CronJobDetail.JobType
                                                        FROM CronTrigger WHERE State = 'WAITING' and CronJobDetail.Name like 'Group_Chnage_Request_batch%']);

        if( jobs.size() < 1){
            integer interval = integer.valueOf(Label.Group_CR_Batch_interval);
            DateTime scheduledTime = DateTime.now().addMinutes( interval );
            String timeString = scheduledTime.format( 'yyyy-MM-dd HH:mm:ss' );
            String cronString = scheduledTime.format( 's m H d M ? yyyy' );
            system.debug('cronstring =>' + cronString);
            System.schedule( 'Group_Chnage_Request_batch - ' + timeString + ' (' + Math.random() + ')', cronString, new xmGroupChangeRequestScheduler() );
        }

        for(CronTrigger job : [SELECT Id FROM CronTrigger WHERE State != 'WAITING' and CronJobDetail.Name like 'Group_Chnage_Request_batch%']){
            system.abortJob(job.Id);
        }

    }

    public map<string,boolean> ProductActiveOnAnotherAccount(set<string> accountXmPersonIds, set<string> xmPersonIds, set<string> productIds, set<string> clusters,  Map<String, ProductEventMap__c> nodeMap){
        map<string,list<string>> acctXmPersonIds = new map<string,list<string>>();
        map<string, boolean> activeProductxmPerson = new map<string, boolean>();
        XMBusinessLayer businessLayer =  new XMBusinessLayer();

        //  system.debug('clusters ==>' + clusters);
        for (contact con :  [Select AccountId,xmPerson__c, xmPerson__r.xmPersonUID__c from Contact Where xmPerson__c in :xmPersonIds and xmPerson__c != null]){
            if(!accountXmPersonIds.contains(con.AccountId + '-' + con.xmPerson__c)){
                if(!acctXmPersonIds.containsKey(con.AccountId)){
                    acctXmPersonIds.put(con.AccountId, new list<string> {con.xmPerson__r.xmPersonUID__c} );
                }else{
                    acctXmPersonIds.get(con.AccountId).add(con.xmPerson__r.xmPersonUID__c);
                }
            }
        }

        //system.debug('acctXmPersonIds ==>' + acctXmPersonIds);
        //system.debug('productIds ==>' + productIds);
        if (acctXmPersonIds.size() > 0){
            //need to check if other accounts has the same active product
            // system.debug('acctXmPersonIds ==>' + acctXmPersonIds);
            for(ImplementedProduct__c product : [select Account__c, product__c, Account__r.inContact_Cluster__c,Account__r.inView_Cluster__c, Account__r.Verint_Cluster__c,Account__r.NICE_QM_Cluster__c,Account__r.NICE_WFM_Cluster__c  FROM ImplementedProduct__c where product__C in: productIds and DeactivatedDate__c = null and
            Account__c in : acctXmPersonIds.keySet() and (Account__r.inContact_Cluster__c in: clusters or
            Account__r.inView_Cluster__c in : clusters or Account__r.Verint_Cluster__c in: clusters or Account__r.NICE_QM_Cluster__c in :clusters or Account__r.NICE_WFM_Cluster__c in : clusters)]){

                ProductEventMap__c productMap = nodeMap.get(product.Product__c);

                XMBusinessLayer.ProductClusterMapClass prodMap = new XMBusinessLayer.ProductClusterMapClass(
                        product.Product__c,
                        product.Account__r.inContact_Cluster__c,
                        product.Account__r.Verint_Cluster__c,
                        product.Account__r.NICE_WFM_Cluster__c,
                        product.Account__r.NICE_QM_Cluster__c,
                        null,
                        productMap
                );
                XMGroupProductCluster thisgroupData = businessLayer.GetGroupDataMap(prodMap);

                for(string xmPersonId : acctXmPersonIds.get(product.Account__c)){
                    string productxmPerson = xmPersonId + '~' + thisgroupData.Product + '~' + thisgroupData.Cluster;
                    system.debug('productxmPerson in method  ==>' + productxmPerson);
                    activeProductxmPerson.put(productxmPerson, true);
                }

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