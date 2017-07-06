/**
 * Created by william.nelson on 7/6/2017.
 */

global class xmGroupChangeRequestBatch implements Database.Batchable<Sobject>, Database.Stateful {
    private string queryString;
     global xmGroupChangeRequestBatch(){
         queryString = 'select    Account__c, Contact__c, ImplementedProduct__c, NotificationProfile__r.xmPersonUID__c,' +
                 ' Account__r.inContact_Cluster__c, Account__r.Verint_Cluster__c,Account__r.NICE_WFM_Cluster__c,Account__r.XMPartnerPrefix__c, ' +
                 'Account__r.NICE_QM_Cluster__c,Account__r.Parent.XMPartnerPrefix__c,ImplementedProduct__r.Product__c  from xmGroupChangeRequest ' +
                 'where status = \'In Queue\'';
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Account> scope)
    {


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
