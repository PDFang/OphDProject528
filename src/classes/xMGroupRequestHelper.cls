/**
 * Created by arnab.karsarkar on 7/11/2017.
 */




public class xMGroupRequestHelper extends TriggerHandler {

    public static void CreateGroupChangeRequestHeader(list<xmChangeRequestHeaderData> requestList){

        list<xmGroupChangeRequestHeader__c> headers = new list<xmGroupChangeRequestHeader__c>();

        for ( xmChangeRequestHeaderData request : requestList)  {

            xmGroupChangeRequestHeader__c header = new xmGroupChangeRequestHeader__c();
            header.sObjectId__c = request.sObjectId;
            header.sObjectType__c = request.sObjectType;
            header.Account__c =  request.accountId;
            headers.add(header);
        }
        insert(headers);
    }


    public override void afterInsert(){

        set<id> headerIds = new set<id>();

        for (xmGroupChangeRequestHeader__c header: (list<xmGroupChangeRequestHeader__c> )Trigger.new)
        {
            headerIds.add(header.id);

        }

        CreateGroupChangeRequests(headerIds);

    }

    @future
    public static void CreateGroupChangeRequests(set<id> headers){

        //determine object types and process
        Map<id, id> implementedProductAccount = new Map<id, id>() ;
        Map<id, id> contactAccount = new Map<id, id>();
        Set<id> accounts = new Set<id>();

        for (xmGroupChangeRequestHeader__c header : [select  sObjectId__c,sObjectType__c,Account__c  from xmGroupChangeRequestHeader__c where id in :  headers]){

            accounts.add(header.Account__c);

            if(header.sObjectType__c == 'ImplementedProduct'){
                implementedProductAccount.put(header.sObjectId__c,header.Account__c);
            }
            else if (header.sObjectType__c == 'Contact'){
                contactAccount.put(header.sObjectId__c,header.Account__c);
            }
        }


        List<xmGroupChangeRequest__c> groupChangeRequestList = new List<xmGroupChangeRequest__c>();
        string queryString = 'select Id,(select Id, xmPerson__c from Contacts where xmPerson__c != null ';
        if(contactAccount.size() > 0)
            queryString += ' and Id in : contactAccount.keyset()';

        queryString += ' ),(select Id from Implemented_Products__r' ;
         if (implementedProductAccount.size() > 0){

            queryString += ' where Id in: implementedProductAccount.keyset()';
         }
         queryString += ') from Account where Id in : accounts';

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