/**
 * Created by ravish.chawla on 8/14/2017.
 */

global class XMPersonGroupUploadBatch implements Database.Batchable<Sobject>, Database.Stateful, Database.AllowsCallouts  {

    public string queryString;
    global XMPersonGroupUploadBatch(){
        queryString = 'select Id,(select Id, XmattersUid__c, xmPerson__c from Contacts where xmPerson__c != null';

        queryString += ' ),(select Id from Implemented_Products__r where Status__c =\'Implemented\'' ;
        queryString += ' ) from Account where CG_Disconnect_Date__c = null';
        System.debug('queryString =>' + queryString);
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(queryString);
    }

    global void execute(Database.BatchableContext BC, List<Account> scope)
    {
        try{
            List<xmGroupChangeRequest__c> groupChangeRequestList = new List<xmGroupChangeRequest__c>();
            for(Account act: scope){

                for(ImplementedProduct__c imp: act.Implemented_Products__r){

                    for(Contact cont: act.Contacts){

                        xmPerson__c xmPerson ;


                        xmGroupChangeRequest__c grpChangeRequest = new xmGroupChangeRequest__c(
                                Account__c = act.Id,
                                Contact__c = cont.Id,
                                ImplementedProduct__c = imp.Id,
                                Status__c = 'In Queue',
                                Action__c = 'Add',
                                NotificationProfile__c = cont.xmPerson__c
                        );
                        xmGroupChangeRequest__c grpChangeRequestMaint = new xmGroupChangeRequest__c(
                                Account__c = act.Id,
                                Contact__c = cont.Id,
                                ImplementedProduct__c = imp.Id,
                                Status__c = 'In Queue',
                                Action__c = 'Add',
                                Maintenance__c = true,
                                NotificationProfile__c = cont.xmPerson__c
                        );

                        System.debug('grpChangeRequest : ' + grpChangeRequest);
                        System.debug('grpChangeRequest : ' + grpChangeRequestMaint);

                        groupChangeRequestList.add(grpChangeRequest);
                        groupChangeRequestList.add(grpChangeRequestMaint);

                    }
                }

            }

            if(groupChangeRequestList.size() >0){
                system.debug ('***  groupChangeRequestList ==> ' + groupChangeRequestList);
                insert groupChangeRequestList;
            }

        }catch (Exception  ex){
            inContactBaseClass.SendErrorEmail(ex, 'Error in Batch class to process change requests in Xmatters');
        }
    }

    global void finish(Database.BatchableContext BC)
    {

    }
}