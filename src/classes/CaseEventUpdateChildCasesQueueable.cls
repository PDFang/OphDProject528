/**
 * Created by jeremy.sparrell on 5/11/2018.
 */

public class CaseEventUpdateChildCasesQueueable implements Queueable{
    private Id eventId;
    private Set<Id> casesProcessed;
    private final Integer caseLimit = 20;

    public CaseEventUpdateChildCasesQueueable(Id eventCaseId, Set<Id> processedChildCases){
        this.eventId = eventCaseId;
        this.casesProcessed = processedChildCases;
    }

    public void execute(QueueableContext context){
        Case event = [SELECT Reason__c, Releases__c, Status, Disposition__c, Reason, Issue_Product__c, Database__c, Clients__c, OtherJustification__c FROM Case WHERE Id = :eventId];
        Case[] childCases = [SELECT ID, Reason__c, Releases__c, Reason, Disposition__c, Database__c, CaseNumber, Subject, Account.Name, Account.CostGuard_Acct__c, Status, KnownIssue__c FROM Case WHERE ParentId = :eventId AND Id NOT IN :casesProcessed LIMIT :caseLimit ];

        if (!childCases.isEmpty())
        {
            for (Case ic : childCases)
            {
                //don't change status if attached to known issue
                if (ic.KnownIssue__c == NULL)
                {
                    ic.Status = event.Status;
                }

                ic.Database__c = event.Database__c;
                ic.Disposition__c = event.Disposition__c;
                ic.Reason = event.Reason;
                ic.Issue_Product__c = event.Issue_Product__c;
                ic.Clients__c = event.Clients__c;
                ic.Reason__c = event.Reason__c;
                ic.Releases__c = event.Releases__c;

                if (event.Releases__c != null && event.Releases__c.contains('Other'))
                {
                    ic.OtherJustification__c = event.OtherJustification__c;
                }
                casesProcessed.add(ic.Id);
            }

            update childCases;

            if(childCases.size() == caseLimit){
                ID jobID = System.enqueueJob(new CaseEventUpdateChildCasesQueueable(eventId, casesProcessed));
            }
        }
    }

}