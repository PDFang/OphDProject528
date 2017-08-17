/**
 * Created by ravish.chawla on 8/14/2017.
 */

global class XMPersonGroupUploadBatch implements Database.Batchable<Sobject>, Database.Stateful, Database.AllowsCallouts  {

    public string queryString;
    public List<xmGroupChangeRequest__c> groupChangeRequestList;
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
             groupChangeRequestList = new List<xmGroupChangeRequest__c>();
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

    global void finish(Database.BatchableContext BC) {

            AsyncApexJob a = [Select Id, Status,ExtendedStatus,NumberOfErrors, JobItemsProcessed,
                              TotalJobItems, CreatedBy.Email   from AsyncApexJob where Id =:BC.getJobId()];
	        String OrgId15Digit = UserInfo.getOrganizationId().left(15);
	        SiteConfiguration__c siteConfig = SiteConfiguration__c.getInstance(OrgId15Digit);
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses;
            if(!test.isRunningTest()){
                toAddresses = new String[]{siteConfig.DeveloperErrorEmail__c};
	            mail.setSenderDisplayName(siteConfig.DeveloperErrorFromName__c);
            }
            else{
            toAddresses = new String[]{'test@test.com'};
	         mail.setSenderDisplayName('Test Sender');
            }

            mail.setToAddresses(toAddresses);
            mail.setSubject('Upload xmGroup Records Batch ' + a.Status);
            mail.setPlainTextBody('Records processed ' + a.TotalJobItems + 'with '+ a.NumberOfErrors + ' failures.');
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }


}