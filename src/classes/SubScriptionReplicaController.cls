/**
 * Created by william.nelson on 9/6/2017.
 */

public with sharing class SubScriptionReplicaController {
    public List<SubscriptionData> Replicas {get;set;}


    public SubScriptionReplicaController(ApexPages.StandardController controller){
        string accountId = (string)controller.getId();
        Account acc = new Account();
        acc.id = accountId;
        this.Replicas = GetSubscriptionReplicas(acc);
    }

    public List<SubscriptionData> GetSubscriptionReplicas(Account acc){
        SubScriptionReplicaHelper helper = new SubScriptionReplicaHelper();
        return helper.GetSubscriptionReplicas(acc);
    }

}