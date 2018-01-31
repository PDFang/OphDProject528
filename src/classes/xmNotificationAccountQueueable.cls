public without sharing class xmNotificationAccountQueueable implements Queueable {
    private xmNotificationGroups__c notificationGroup;

    public xmNotificationAccountQueueable(xmNotificationGroups__c NotificationGroup) {
        this.notificationGroup = NotificationGroup;
    }

    public void execute(QueueableContext context) {

        try {
            List<CaseEventClass.AccountIncident> accountList = getAssociatedAccounts(notificationGroup.Case__c);
            system.debug('Added Notification Account records ==> ' + accountList.size());

            if(accountList.size() > 0) {
                createNotificationAccounts(accountList);

                //kick off the batch
                system.debug('triggering the XMNotificationGroupBatch');
                XMNotificationGroupBatch batch = new XMNotificationGroupBatch(notificationGroup);

                //get the batch size
                Integer batchSize;
                AppConfiguration__c config = AppConfiguration__c.getInstance();
                if (config != null) {
                    batchSize = (Integer) config.XM_Notification_Group_Batch_Size__c;
                } else {
                    batchSize = 50;
                }

                System.debug('BatchSize = ' + batchSize);

                //update the notification group status
                notificationGroup.Status__c = 'Accounts Associated';
                update notificationGroup;

                Database.executeBatch(batch, batchSize);
            }
            else {
                notificationGroup.Status__c = 'Failed';
                update notificationGroup;
            }
        }
        catch(Exception ex) {
            system.debug(ex);
            notificationGroup.Status__c = 'Failed';
            inContactBaseClass.SendErrorEmail(ex, 'Error in xmNotificationAccountQueueable while processing Notification Group ' + notificationGroup.Id);
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
            system.debug('getting associated accounts for Case ');
            system.debug(associatedCaseList[0]);
            CaseEventClass cec = new CaseEventClass(associatedCaseList[0]);

            //set the list size to get the
            cec.listSize = 10000;

            accountList = cec.AccountIncidentList();
        }

        return accountList;
    }
}