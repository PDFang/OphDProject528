/**
 * Created by ravish.chawla on 7/6/2017.
 */

public class ImplementedProductTriggerHandler extends TriggerHandler {

    protected override void afterUpdate()
    {
        insertXMGroupChangeRequest();
    }

    private static void insertXMGroupChangeRequest(){
        List<ImplementedProduct__c> productList = (List<ImplementedProduct__c>) (trigger.new);
        Map<Id, ImplementedProduct__c> oldMap = (Map<Id, ImplementedProduct__c>) (trigger.oldMap);
        set<Id> productIds = new set<Id>();
        set<Id> accountIds = new set<Id>();
        List<xmChangeRequestHeaderData> xmChangeRequestHeaderDataList = new List<xmChangeRequestHeaderData>();


        for(ImplementedProduct__c impProduct: productList){
            String oldStatus = oldMap.get(impProduct.Id).Status__c;
            if((impProduct.Status__c != oldStatus && oldStatus == 'Implemented') ||
                    (impProduct.GoLiveDate__c == null && oldMap.get(impProduct.Id).GoLiveDate__c != null
                            && impProduct.EstimatedGoLiveDate__c > System.today().addDays(14))){
                xmChangeRequestHeaderData objxmChangeRequestHeaderData = new xmChangeRequestHeaderData();
                objxmChangeRequestHeaderData.sObjectId = impProduct.Id;
                objxmChangeRequestHeaderData.accountId = impProduct.Account__c;
                objxmChangeRequestHeaderData.sObjectType = 'ImplementedProduct';
                xmChangeRequestHeaderDataList.add(objxmChangeRequestHeaderData);
//                productIds.add(impProduct.Id);
//                accountIds.add(impProduct.Account__c);

            }
        }

        System.debug('xmChangeRequestHeaderDataList =>' + xmChangeRequestHeaderDataList);
        //System.debug('productAcctMap : ' + productAcctMap);
        if(xmChangeRequestHeaderDataList.size() > 0){
            xMGroupRequestHelper.CreateGroupChangeRequestHeader(xmChangeRequestHeaderDataList);
        }

    }

}