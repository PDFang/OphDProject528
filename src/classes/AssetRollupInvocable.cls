/**
 * Created by mohandaas.rangaswamy on 11/30/2017.
 */

public class AssetRollupInvocable {

    @InvocableMethod
    public static void AssetRollupToPhaseProject(List<Asset> assets){

        system.debug('**** AssetRollupToPhaseProject(): assets - ' + assets);

        Id assetRollupQueueableId = System.enqueueJob(new assetRollupQueueable(assets));
        system.debug('**** AssetRollupToPhaseProject(): assetRollupQueueableId - ' + assetRollupQueueableId);

    }


}