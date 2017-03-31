/**
 * Created by mohandaas.rangaswamy on 3/28/2017.
 */

@IsTest
private class AccountImpactCalculationBatchTest {

    static testMethod void testAccountImpactCalculationBatch() {

        test.startTest();
        Id asyncJobId = Database.executeBatch(new AccountImpactCalculationBatch());
        test.stopTest();
        AsyncApexJob job = [Select Id, Status From AsyncApexJob where Id = :asyncJobId];
        system.assertEquals('Completed', job.Status);

        for(Account acct : [Select Age_of_Customer_in_Months__c, Account_Net_Score__c from Account]){
            system.assert(acct.Age_of_Customer_in_Months__c > 0);
            system.assert(acct.Account_Net_Score__c > 0);
        }

    }

    static testMethod void testAccountImpactCalculationBatchScheduler() {

        Datetime nextRun = system.now().addSeconds(5);
        String dateTimeFormat = '{0} {1} {2} {3} {4} ? {5}';
        String scheduledTime = string.format(
                dateTimeFormat,
                new String[]{
                        nextRun.second().format(),
                        nextRun.minute().format(),
                        nextRun.hour().format(),
                        nextRun.day().format(),
                        nextRun.month().format(),
                        nextRun.year().format().remove(',')
                }
        );
        system.debug('scheduleJob(): scheduledTime - ' + scheduledTime);

        test.startTest();
        String scheduledJobId = system.schedule('AccountImpactCalculationBatchScheduler Test', scheduledTime, new AccountImpactCalculationBatchScheduler());
        test.stopTest();

        CronTrigger job = [Select Id, State, NextFireTime, CronExpression From CronTrigger where Id = :scheduledJobId];
        system.assertEquals(scheduledTime, job.CronExpression);

    }

    @TestSetup
    static void createTestData(){

        // create accounts
        Map<String,Schema.RecordTypeInfo> accountRecordTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Account[] accountList = new Account[]{};
        for(Integer i=0; i<100; i++){
            Account testAccount = new Account(
                    Name = 'AccountImpactCalculationBatch Account '+ i,
                    Type = 'Customer',
                    RecordTypeId = accountRecordTypeMap.get('Customers').getRecordTypeId(),
                    IsPartner__c = false,
                    CustomerSegment__c = 'Strategic',
                    Brand_Visibility__c = 'No',
                    Industry_Leadership_Vocality__c = 'Yes',
                    Social_Media_Presence__c = 'Yes',
                    Risk_of_Leaving__c = '1',
                    Referenceable__c = false,
                    GYRStatus__c = 'Green'
            );
            accountList.add(testAccount);
        }
        insert accountList;

        Map<String,Schema.RecordTypeInfo> oppRecordTypeMap = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        Opportunity[] oppList = new Opportunity[]{};
        for(Integer i=0; i<accountList.size(); i++){
            Opportunity testOpp = new Opportunity(
                    Name = 'AccountImpactCalculationBatch Opp 1',
                    AccountId = accountList[i].Id,
                    RecordTypeId = oppRecordTypeMap.get('New Opportunity').getRecordTypeId(),
                    StageName = '1 - Identification / Qualification',
                    CloseDate = Date.today().addDays(30),
                    Probability = 25,
                    Partner_Deal__c = 'NO',
                    Contract_Type__c = 'New Customer'
            );
            oppList.add(testOpp);
        }
        insert oppList;

        ImplementedProduct__c[] impProductList = new ImplementedProduct__c[]{};
        for(Integer i=0; i<oppList.size(); i++){
            ImplementedProduct__c product = new ImplementedProduct__c(
                    Account__c = oppList[i].AccountId,
                    EstimatedGoLiveDate__c = Date.today().addMonths(-6),
                    GoLiveDate__c = Date.today().addMonths(-6),
                    Opportunity__c = oppList[i].Id,
                    Product__c = 'inContact',
                    Status__c = 'Implemented'
            );
            impProductList.add(product);
        }
        insert impProductList;


    }
}