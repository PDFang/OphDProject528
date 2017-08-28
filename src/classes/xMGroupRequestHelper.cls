/**
 * Created by arnab.karsarkar on 7/11/2017.
 */
public class xMGroupRequestHelper extends TriggerHandler {

    public static void CreateGroupChangeRequestHeader(list<xmChangeRequestHeaderData> requestList){
        try{
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
        catch (Exception ex){
            inContactBaseClass.SendErrorEmail(ex, 'Error in CreateGroupChangeRequestHeader');

        }


    }


    public override void afterInsert(){

        set<id> headerIds = new set<id>();

        for (xmGroupChangeRequestHeader__c header: (list<xmGroupChangeRequestHeader__c> )Trigger.new)
        {
            headerIds.add(header.id);

        }

        CreateGroupChangeRequests(headerIds);

    }

    public override void afterUpdate(){

        set<id> headerIds = new set<id>();

        for (xmGroupChangeRequestHeader__c header: (list<xmGroupChangeRequestHeader__c> )Trigger.new)
        {
            if(header.Retry__c){
                headerIds.add(header.id);
            }
        }
        if(headerIds.size() > 0)
            CreateGroupChangeRequests(headerIds);

    }

    @future
    public static void CreateGroupChangeRequests(set<id> headers){
        try{
            //determine object types and process
            set<id> implmentedProductIds = new set<id>();
            set<id> contactIds = new set<id>();
            Set<id> accounts = new Set<id>();
            Map<id, id> groupCRAccount = new Map<id, id>();

            for (xmGroupChangeRequestHeader__c header : [select  sObjectId__c,sObjectType__c,Account__c  from xmGroupChangeRequestHeader__c where id in :  headers]){

                accounts.add(header.Account__c);
                groupCRAccount.put(header.Account__c, header.Id);

                if(header.sObjectType__c == 'ImplementedProduct'){
                    implmentedProductIds.add(header.sObjectId__c);
                }
                else if (header.sObjectType__c == 'Contact'){
                    contactIds.add(header.sObjectId__c);
                }

            }


            List<xmGroupChangeRequest__c> groupChangeRequestList = new List<xmGroupChangeRequest__c>();
            string queryString = 'select Id,(select Id, XmattersUid__c, xmPerson__c from Contacts ';
            if(contactIds.size() > 0)
                queryString += ' where Id in :  contactIds';
            else
                    queryString += ' where xmPerson__c != null or XmattersUid__c != null';

            queryString += ' ),(select Id from Implemented_Products__r' ;
            if (implmentedProductIds.size() > 0){

                queryString += ' where Id in:  implmentedProductIds';
            }
            queryString += ' ) from Account where Id in : accounts';
            System.debug('queryString =>' + queryString);

            list<Account> accountList = Database.query(queryString);
            System.debug('accountList =>' + accountList);

            for(Account act: accountList){

                for(ImplementedProduct__c imp: act.Implemented_Products__r){

                    for(Contact cont: act.Contacts){

                        xmPerson__c xmPerson ;


                        xmGroupChangeRequest__c grpChangeRequest = new xmGroupChangeRequest__c(
                                Account__c = act.Id,
                                Contact__c = cont.Id,
                                ImplementedProduct__c = imp.Id,
                                NotificationProfile__r = xmPerson,
                                Status__c = 'In Queue',
                                Action__c = 'Remove',
                                xmGroupChangeRequestHeader__c = groupCRAccount.get(act.Id)
                        );

                        xmGroupChangeRequest__c grpChangeRequest1 = new xmGroupChangeRequest__c(
                                Account__c = act.Id,
                                Contact__c = cont.Id,
                                ImplementedProduct__c = imp.Id,
                                NotificationProfile__r = xmPerson,
                                Status__c = 'In Queue',
                                Action__c = 'Remove',
                                Maintenance__c = true,
                                xmGroupChangeRequestHeader__c = groupCRAccount.get(act.Id)
                        );

                        if(cont.xmPerson__c == null){
                            xmPerson = new xmPerson__c(
                                    xmPersonUID__c =  cont.XmattersUid__c
                            );
                            grpChangeRequest.NotificationProfile__r = xmPerson;
                            grpChangeRequest1.NotificationProfile__r = xmPerson;
                        }
                        else {
                            grpChangeRequest.NotificationProfile__c = cont.xmPerson__c;
                            grpChangeRequest1.NotificationProfile__c = cont.xmPerson__c;
                        }
                        System.debug('grpChangeRequest : ' + grpChangeRequest);
                        groupChangeRequestList.add(grpChangeRequest);
                        groupChangeRequestList.add(grpChangeRequest1);



                    }
                }

            }

            if(groupChangeRequestList.size() >0){
                system.debug ('***  groupChangeRequestList ==> ' + groupChangeRequestList);
                insert groupChangeRequestList;
            }
        }
        catch(Exception ex){
            inContactBaseClass.SendErrorEmail(ex, 'Error in CreateGroupChangeRequests');
        }



    }

}