/**
 * Created by ravish.chawla on 10/12/2017.
 */

public class AssetSubscriptionAllocationNewModel {
    public String Asset {get; set;}
    public String AssetName {get; set;}
    public String AssetAllocationId {get; set;}
    public String AssetAllocationName {get; set;}
    public String ProjectNumber {get; set;}
    public String ProjectName {get; set;}
    public String ProjectPhase {get; set;}
    public Decimal AllocatedQuantity {get; set;}
    public Decimal AllocatedPercentage {get; set;}
    public Decimal AllocatedHours {get; set;}
    public String Subscription {get; set;}
    public String SubscriptionName {get; set;}
    public String SubscriptionAllocationId {get; set;}
    public String SubscriptionAllocationName {get; set;}
    public String Product {get; set;}
    public String ProductName {get;set;}
    public decimal Quantity {get;set;}
    public Decimal BudgtedHours {get; set;}
    public Boolean Implemented {get; set;}


    public AssetSubscriptionAllocationNewModel(){

    }

    public AssetSubscriptionAllocationNewModel(Project_Asset_Allocation__c allocation){
        this.Asset = allocation.Asset__c;
        this.AssetName = allocation.Asset__r.Name;
        this.AssetAllocationName = allocation.Name;
        this.AssetAllocationId = allocation.Id;
        this.ProjectNumber = allocation.Project__c;
        this.ProjectName = allocation.Project__r.Name;
        this.ProjectPhase = allocation.ProjectPhase__c;
        this.AllocatedQuantity = allocation.Quantity_Allocation__c;
        this.AllocatedPercentage = allocation.Percent_Allocation__c;
        this.AllocatedHours = allocation.Asset__r.Budgeted_Hours__c == null ? null: allocation.Hours_Allocated__c;
        this.Quantity = allocation.Asset__r.Quantity;
        this.BudgtedHours = allocation.Asset__r.Budgeted_Hours__c;
        this.Implemented = allocation.Implemented__c;

    }

    public AssetSubscriptionAllocationNewModel(Project_Subscription_Allocation__c allocation){
        this.Subscription = allocation.Subscription__c;
        this.SubscriptionAllocationId = allocation.Id;
        this.SubscriptionName = allocation.Subscription__r.Name;
        this.SubscriptionAllocationName = allocation.Name;
        this.ProductName = allocation.Subscription__r.Subscription__r.SBQQ__Product__r.Name;
        this.Product = allocation.Subscription__r.Subscription__r.SBQQ__Product__c;
        this.ProjectNumber = allocation.Project__c;
        this.ProjectName = allocation.Project__r.Name;
        this.ProjectPhase = allocation.ProjectPhase__c;
        this.AllocatedQuantity = allocation.Quantity_Allocation__c;
        this.AllocatedPercentage = allocation.Percent_Allocation__c;
        this.AllocatedHours = allocation.Subscription__r.Budgeted_Hours__c == null ? null : allocation.Hours_Allocated__c;
        this.Quantity = allocation.Subscription__r.Quantity__c;
        this.BudgtedHours = allocation.Subscription__r.Budgeted_Hours__c;
        this.Implemented = allocation.Implemented__c;

    }
}