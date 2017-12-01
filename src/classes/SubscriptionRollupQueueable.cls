/**
 * Created by mohandaas.rangaswamy on 12/1/2017.
 */

// summarize and rollup subscription MRR's to related phase project
public class SubscriptionRollupQueueable implements Queueable{

    final Set<Id> projectIds;

    // constructor
    public SubscriptionRollupQueueable(List<SBQQ__Subscription__c> subscriptions){

        system.debug('**** SubscriptionRollupQueueable(): subscriptions - ' + subscriptions);

        projectIds = new Set<Id>();
        for(SBQQ__Subscription__c sub : subscriptions){
            if(sub.Project_Phase__c != null){
                projectIds.add(sub.Project_Phase__c);
            }
        }

        system.debug('**** SubscriptionRollupQueueable(): projectIds - ' + projectIds);

        if(projectIds.isEmpty()){
            return;
        }

    }

    // interface method
    public void execute(QueueableContext context){

        AssetSubscriptionRollupHelper helper = new AssetSubscriptionRollupHelper(projectIds);

        List<Project__c> phaseProjects = helper.rollupSubscriptionFinancials();

        if(phaseProjects.size() > 0){

            Database.SaveResult[] srList = Database.update(phaseProjects, false);
            for(Integer i=0; i < srList.size(); i++){
                if(!srList[i].isSuccess()){
                    Database.Error[] errors = srList[i].getErrors();
                    if(errors.size() > 0){
                        system.debug('**** execute(): save error - ' + errors.get(0));
                        system.debug('**** execute(): record id - ' + phaseProjects[i].Id);
                    }
                }
            }

        }

    }

}