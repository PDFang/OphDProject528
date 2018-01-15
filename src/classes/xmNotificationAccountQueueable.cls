public without sharing class xmNotificationAccountQueueable implements Queueable {
    private xmNotificationGroups__c notificationGroup;

    public xmNotificationAccountQueueable(xmNotificationGroups__c NotificationGroup) {
        this.notificationGroup = NotificationGroup;
    }

    public void execute(QueueableContext context) {

        try {
            List<CaseEventClass.AccountIncident> accountList = getAssociatedAccounts(notificationGroup.Case__c);
            createNotificationAccounts(accountList);
            notificationGroup.Status__c = 'Accounts Associated';

            system.debug('Added Notification Account records ==> ' + accountList.size());

            //kick off the batch
            system.debug('triggering the XMNotificationGroupBatch');
            XMNotificationGroupBatch batch = new XMNotificationGroupBatch(notificationGroup);

            //get the batch size
            Integer batchSize;
            List<AppConfiguration__c> configurations = [select XM_Notification_Group_Batch_Size__c from AppConfiguration__c];

            if(configurations != null) {
                batchSize = (Integer)configurations[0].XM_Notification_Group_Batch_Size__c;
                System.debug(batchSize);
            }
            else {
                batchSize = 50;
            }
            Database.executeBatch(batch, batchSize);
        }
        catch(Exception ex) {
            system.debug(ex);
            notificationGroup.Status__c = 'Failed';
            inContactBaseClass.SendErrorEmail(ex, 'Error in xmNotificationAccountQueueable while processing Notification Group ' + notificationGroup.Id);
        }
        finally {
            update notificationGroup;
        }
    }

    //create the Notification Account records for each selected account
    private void createNotificationAccounts(List<CaseEventClass.AccountIncident> accountList) {
        List<xmNotificationAccounts__c> accountNotifications = new List<xmNotificationAccounts__c>();

        system.debug('Loaded Associated Accounts ===> ' + accountList.size());
        for(CaseEventClass.AccountIncident acct : accountList) {
            xmNotificationAccounts__c notificationAccount = new xmNotificationAccounts__c(
                Account__c = acct.acct.Id,
                Notification_Group__c = notificationGroup.Id
            );

            accountNotifications.add(notificationAccount);
        }

        system.debug('inserting xmNotificationAccounts__c ===> ' + accountNotifications.size());

        insert accountNotifications;
    }

    //load the list of associated accounts that were selected
    private List<CaseEventClass.AccountIncident> getAssociatedAccounts(String caseId) {
        List<CaseEventClass.AccountIncident> accountList = new List<CaseEventClass.AccountIncident>();
        List<Case> associatedCaseList = [select Id, RecordTypeId, ProductImpacted__c, PlatformsImpacted__c from Case where Id = :caseId];
        if(associatedCaseList != null && associatedCaseList.size() == 1) {
            CaseEventClass cec = new CaseEventClass(associatedCaseList[0]);

            accountList = cec.AccountIncidentList();
        }

        return accountList;
    }
}