public with sharing class xmNotificationAccountQueueable implements Queueable {
    private xmNotificationGroups__c notificationGroup;

    public xmNotificationAccountQueueable(xmNotificationGroups__c NotificationGroup) {
        this.notificationGroup = NotificationGroup;
    }

    public void execute(QueueableContext context) {

        try {
            Set<String> accountIds = getAssociatedAccounts(notificationGroup.Case__c);
            createNotificationAccounts(accountIds);
            notificationGroup.Status__c = 'Accounts Associated';
        }
        catch(Exception ex) {
            system.debug(ex);
            notificationGroup.Status__c = 'Failed';
        }
        finally {
            update notificationGroup;
        }
    }

    //create the Notification Account records for each selected account
    private void createNotificationAccounts(Set<String> accountIds) {
        List<xmNotificationAccounts__c> accountNotifications = new List<xmNotificationAccounts__c>();

        system.debug('Loaded Associated Accounts ===> ' + accountIds.size());
        for(String id : accountIds) {
            xmNotificationAccounts__c notificationAccount = new xmNotificationAccounts__c(
                Account__c = id,
                Notification_Group__c = notificationGroup.Id
            );

            accountNotifications.add(notificationAccount);
        }

        system.debug('inserting xmNotificationAccounts__c ===> ' + accountNotifications.size());

        insert accountNotifications;
    }

    //load the list of associated accounts that were selected
    private Set<String> getAssociatedAccounts(String caseId) {
        Set<String> accountIds = new Set<String>();
        List<Case> associatedCaseList = [select Id, RecordTypeId from Case where Id = :caseId];
        if(associatedCaseList != null && associatedCaseList.size() == 1) {
            CaseEventClass cec = new CaseEventClass(associatedCaseList[0]);

            List<CaseEventClass.AccountIncident> accountList = cec.AccountIncidentList();

            for(CaseEventClass.AccountIncident acc : accountList) {
                accountIds.add(acc.acct.Id);
            }
        }

        return accountIds;
    }
}