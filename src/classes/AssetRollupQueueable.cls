/**
 * Created by mohandaas.rangaswamy on 11/30/2017.
 */

// summarize and rollup asset NRR's to related phase project
public class AssetRollupQueueable implements Queueable{

    final Set<Id> projectIds;

    // constructor
    public AssetRollupQueueable(Set<Id> projectIds) {

        system.debug('**** AssetRollupQueueable(): projectIds - ' + projectIds);

        this.projectIds = projectIds;
        
    }

    // constructor
    public AssetRollupQueueable(List<Asset> assets){

        system.debug('**** AssetRollupQueueable(): assets - ' + assets);

        projectIds = new Set<Id>();
        for(Asset a : assets){
            if(a.Project_Phase__c != null){
                projectIds.add(a.Project_Phase__c);
            }
        }

        system.debug('**** AssetRollupQueueable(): projectIds - ' + projectIds);

        if(projectIds.isEmpty()){
            return;
        }

    }

    // interface method
    public void execute(QueueableContext context){

        AssetSubscriptionRollupHelper helper = new AssetSubscriptionRollupHelper(projectIds);

        List<Project__c> phaseProjects = helper.rollupAssetFinancials();

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