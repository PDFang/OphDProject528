/**
 * Created by mohandaas.rangaswamy on 11/30/2017.
 */

public class AssetRollupQueueable implements Queueable{

    List<Asset> assets;

    public AssetRollupQueueable(List<Asset> assets){

        this.assets = assets;
        system.debug('**** AssetRollupQueueable(): assets - ' + assets);

    }

    public void execute(QueueableContext context){

        List<Project__c> phaseProjects = new List<Project__c>();

        for(Asset a : assets){
            if(a.Project_Phase__c != null){
                Project__c p = new Project__c(
                        Id = a.Project_Phase__c,
                        Contracted_NRR__c = 100
                );

                phaseProjects.add(p);
            }
        }


        if(phaseProjects.size() > 0)
            update phaseProjects;

    }

}