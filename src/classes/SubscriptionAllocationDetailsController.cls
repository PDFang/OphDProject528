/**
 * Created by ravish.chawla on 10/10/2017.
 */

public with sharing class SubscriptionAllocationDetailsController {
    public string projectId{get; set;}
    public Project_Subscription_Allocation__c selSubscriptionAllocation{get; private set;}

    public SubscriptionAllocationDetailsController(ApexPages.StandardController controller) {
        this.selSubscriptionAllocation = (Project_Subscription_Allocation__c) controller.getRecord();
        System.debug('selSubscriptionAllocation ==>' + selSubscriptionAllocation);

        if (selSubscriptionAllocation.Id != null) {
            List<Project_Subscription_Allocation__c> projectSubscriptionAllocations = new List<Project_Subscription_Allocation__c>([
                    SELECT Id, Project__c
                    from Project_Subscription_Allocation__c
                    where Id = :selSubscriptionAllocation.Id
            ]);

            System.debug('projectSubscriptionAllocations[0] ==>' + projectSubscriptionAllocations[0]);
            projectId = projectSubscriptionAllocations[0].Project__c;
            System.debug('projectId ==>' + projectId);
        }
    }
}