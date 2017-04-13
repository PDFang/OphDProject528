/**
 * Created by arnab.karsarkar on 3/21/2017.
 */

global class KnownIssuesImpactScoreCalcBatch implements Database.Batchable<sObject>, Database.Stateful {

    private string queryString = '';
    private boolean exceptionOccured;
    private integer numOfKI = 0;
    //constructor
    global KnownIssuesImpactScoreCalcBatch(string query){
        this.queryString = query;
        exceptionOccured = false;
        CaseTriggerHandler.callActionHub = false;
    }

    //
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(queryString);
    }

    global void execute(Database.BatchableContext BC, List<Case> scope) {
      try{
          if(scope.size() > 0){
              numOfKI += scope.size();
              KnownIssuesImpactCalcImplementation KIImpactCalc = new KnownIssuesImpactCalcImplementation();
              KnownIssueImpactCalculationClass KICalc = new KnownIssueImpactCalculationClass(KIImpactCalc);
              KICalc.CalculateKnownIssueScore(scope);
          }
      }Catch(Exception ex){
          exceptionOccured = true;
          String body = 'An error occured - ' + ex.getMessage() + ' at the stack ' + ex.getStackTraceString();
          SendEmail('Error Occured in Batch Class - Known Issue Impact Score', body);
      }

    }

    global void finish(Database.BatchableContext BC) {
        if(!exceptionOccured){
            String body = 'Batch updated successfully for - ' + numOfKI + ' Known Issue records.';
            SendEmail('Batch Update - Known Issue Impact score', body);
        }
    }

    private void SendEmail(string subject, string body){
        try
        {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String OrgId15Digit = UserInfo.getOrganizationId().left(15);
            SiteConfiguration__c siteConfig = SiteConfiguration__c.getInstance(OrgId15Digit);
            String[] toAddresses = new String[]{siteConfig.DeveloperErrorEmail__c};
            mail.setToAddresses(toAddresses);
            mail.setSubject(subject);
            mail.setHtmlBody(body);
            if(!Test.isRunningTest())
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }

        catch (Exception ex)
        {

        }
    }


}