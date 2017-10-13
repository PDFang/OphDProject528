/**
 * Created by ravish.chawla on 10/12/2017.
 */

public class AssetSubscriptionAllocationNewModel {
    public String Asset {get; set;}
    public String AssetAllocationId {get; set;}
    public String ProjectNumber {get; set;}
    public String ProjectPhase {get; set;}
    public Decimal AllocatedQuantity {get; set;}
    public Decimal AllocatedPercentage {get; set;}
    public Decimal AllocatedHours {get; set;}
    public String Subscription {get; set;}
    public String SubscriptionAllocationId {get; set;}
    public String Product {get; set;}

    public AssetSubscriptionAllocationNewModel(Project_Asset_Allocation__c allocation){
        this.Asset = allocation.Asset__c;
        this.AssetAllocationId = allocation.Id;
        this.ProjectNumber = allocation.Project__c;
        this.ProjectPhase = allocation.ProjectPhase__c;
        this.AllocatedQuantity = allocation.Quantity_Allocation__c;
        this.AllocatedPercentage = allocation.Percent_Allocation__c;
        this.AllocatedHours = allocation.Hours_Allocated__c;
    }

    public AssetSubscriptionAllocationNewModel(Project_Subscription_Allocation__c allocation){
        this.Subscription = allocation.Subscription__c;
        this.SubscriptionAllocationId = allocation.Id;
        this.Product = allocation.Product__c;
        this.ProjectNumber = allocation.Project__c;
        this.ProjectPhase = allocation.ProjectPhase__c;
        this.AllocatedQuantity = allocation.Quantity_Allocation__c;
        this.AllocatedPercentage = allocation.Percent_Allocation__c;
        this.AllocatedHours = allocation.Hours_Allocated__c;
    }
}