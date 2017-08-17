/**
 * Created by ravish.chawla on 8/14/2017.
 */

global class XMPersonGroupUploadBatch implements Database.Batchable<Sobject>, Database.Stateful, Database.AllowsCallouts  {

    public string queryString;
    global XMPersonGroupUploadBatch(){
        queryString = 'select Id,(select Id, XmattersUid__c, xmPerson__c, Contact_Role__c from Contacts where xmPerson__c != null'
                      +' AND Contact_Role__c in (\'Event Notification\', \'Maintenance Notification\') ),(select Id from Implemented_Products__r where Status__c =\'Implemented\''
                      +' ) from Account where CG_Disconnect_Date__c = null';
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
                        if(cont.Contact_Role__c.contains('Event Notification')){
                            xmGroupChangeRequest__c grpChangeRequest = new xmGroupChangeRequest__c(
                                    Account__c = act.Id,
                                    Contact__c = cont.Id,
                                    ImplementedProduct__c = imp.Id,
                                    Status__c = 'In Queue',
                                    Action__c = 'Add',
                                    NotificationProfile__c = cont.xmPerson__c
                            );
                            System.debug('grpChangeRequest : ' + grpChangeRequest);
                            groupChangeRequestList.add(grpChangeRequest);
                        }
                       if(cont.Contact_Role__c.contains('Maintenance Notification')){
                            xmGroupChangeRequest__c grpChangeRequestMaint = new xmGroupChangeRequest__c(
                                   Account__c = act.Id,
                                   Contact__c = cont.Id,
                                   ImplementedProduct__c = imp.Id,
                                   Status__c = 'In Queue',
                                   Action__c = 'Add',
                                   Maintenance__c = true,
                                   NotificationProfile__c = cont.xmPerson__c
                           );
                           System.debug('grpChangeRequest : ' + grpChangeRequestMaint);
                           groupChangeRequestList.add(grpChangeRequestMaint);
                       }




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