/**
 * Created by arnab.karsarkar on 7/11/2017.
 */

public class xMGroupRequestHelper {

    public static void CreateGroupChangeRequests(set<id> productIds, set<Id> acctIds, set<Id> xmPersonIds){

        List<xmGroupChangeRequest__c> groupChangeRequestList = new List<xmGroupChangeRequest__c>();
        if(productIds == null){
            productIds = new set<Id>();
            for(ImplementedProduct__c imp :[select Id from ImplementedProduct__c
            WHERE Account__c in :acctIds  and Account__r.CG_Disconnect_Date__c = NULL
            AND(GoLiveDate__c <= TODAY
            OR(EstimatedGoLiveDate__c <= NEXT_N_DAYS : 14
            AND Status__c != 'Canceled'))])
            {
                productIds.add(imp.Id);
            }
        }

        string queryString = 'select Id,(select Id, xmPerson__c from Contacts where xmPerson__c != null ';
        if(xmPersonIds.size() > 0)
            queryString += ' and Id in : xmPersonIds ';

        queryString += ' ),(select Id from Implemented_Products__r where Id in: productIds)from Account where Id in : acctIds';

        list<Account> accountList = Database.query(queryString);

        for(Account act: accountList){

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