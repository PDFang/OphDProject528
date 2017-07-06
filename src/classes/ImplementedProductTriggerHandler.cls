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
        List<xmGroupChangeRequest__c> groupChangeRequestList = new List<xmGroupChangeRequest__c>();
        Map<Id, Id> productAcctMap = new Map<Id, Id>();



        for(ImplementedProduct__c impProduct: productList){
            String oldStatus = oldMap.get(impProduct.Id).Status__c;
            if((impProduct.Status__c != oldStatus && oldStatus == 'Implemented') ||
                    (impProduct.GoLiveDate__c == null && oldMap.get(impProduct.Id).GoLiveDate__c != null
                            && impProduct.EstimatedGoLiveDate__c > System.today().addDays(14))){
                productAcctMap.put(impProduct.Id, impProduct.Account__c);

            }
        }
        System.debug('productAcctMap : ' + productAcctMap);
        if(productAcctMap.size() > 0){
            for(Account act: [select Id,(select Id, xmPerson__c from Contacts
            where xmPerson__c != null ),(select Id from Implemented_Products__r where Id in:
                    productAcctMap.keySet())from Account where Id in : productAcctMap.values()]){


                for(ImplementedProduct__c imp: act.Implemented_Products__r){
                    Set<String> personIdSet = new Set<String>();

                    for(Contact cont: act.Contacts){
                        if(!personIdSet.contains(cont.xmPerson__c)){
                            xmGroupChangeRequest__c grpChangeRequest = new xmGroupChangeRequest__c(
                                    Account__c = act.Id,
                                    Contact__c = cont.Id,
                                    ImplementedProduct__c = imp.Id,
                                    NotificationProfile__c = cont.xmPerson__c,
                                    Status__c = 'In Queue',
                                    Action__c = 'Remove'
                            );
                            System.debug('grpChangeRequest : ' + grpChangeRequest);
                            groupChangeRequestList.add(grpChangeRequest);
                            personIdSet.add(cont.xmPerson__c);
                        }

                    }
                }

            }

            if(groupChangeRequestList.size() >0){
                insert groupChangeRequestList;
            }
        }

    }

}