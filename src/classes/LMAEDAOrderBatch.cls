/**
 * Created by william.nelson on 8/21/2017.
 */

global class LMAEDAOrderBatch implements Database.Batchable<Sobject>, Database.Stateful, Database.AllowsCallouts  {

    private string queryString;
    private boolean exceptionOccured;
    global List<String> processedServiceOrderIds = new List<String>();
    //public List<> groupChangeRequestList;
    global LMAEDAOrderBatch(){
        this.queryString = 'SELECT License__c, Service_Order__c from EDA__c where AutoSubmit__c = true and Status__c = \'In Queue\'';
        System.debug('queryString =>' + this.queryString);
        exceptionOccured = false;
    }

    global Database.QueryLocator start(Database.BatchableContext BC)
    {

        return Database.getQueryLocator(this.queryString);

    }

    global void execute(Database.BatchableContext BC, List<EDA__c> scope)
    {

        //try{
            System.debug('scope.size() =>' + scope);

            if(scope.size() > 0){
                for(EDA__c s : scope){
                    try{
                        if(!Test.isRunningTest())
                            CHANNEL_ORDERS.ServiceOrderProcessor.sendOrder(s.Service_Order__c);
                        s.Status__c = 'Processed';
                        processedServiceOrderIds.Add(s.Service_Order__r.Name);
                        System.debug('s.Status__c processed =>' + s.Status__c);
                    }
                   Catch(Exception ex){
                       s.Status__c = 'Failed';
                       System.debug('s.Status__c falied =>' + s.Status__c);

                       System.debug('ex =>' + ex.getMessage());
                   }
                }

                update scope;
            }
//        }Catch(Exception ex){
//            exceptionOccured = true;
//            String body = 'An error occured - ' + ex.getMessage() + ' at the stack ' + ex.getStackTraceString();
//            SendEmail('Error Occured in Batch Class - LMAEDAOrderBatch', body);
//        }
    }

    global void finish(Database.BatchableContext BC)
    {
        if(processedServiceOrderIds.size() > 0){
            String body = 'We have submitted - ' + processedServiceOrderIds.size() + ' orders.  Below are all the service orders \n';
            for(String serviceOrder: processedServiceOrderIds){
                body += serviceOrder + '\n';
            }
            SendEmail('Processed Orders for LMA', body);
        }

    }

    private void SendEmail(string subject, string body){

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String OrgId15Digit = UserInfo.getOrganizationId().left(15);
        SiteConfiguration__c siteConfig = SiteConfiguration__c.getInstance(OrgId15Digit);
        String[] toAddresses = new String[]{};
        if(!Test.isRunningTest())
            toAddresses = new String[]{siteConfig.DeveloperErrorEmail__c};
        else
            toAddresses = new String[]{'test@Test.com'};
        mail.setToAddresses(toAddresses);
        mail.setSubject(subject);
        mail.setHtmlBody(body);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

    }


}