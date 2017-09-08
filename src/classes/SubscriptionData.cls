/**
 * Created by william.nelson on 9/7/2017.
 */

public with sharing class SubscriptionData {
    public string AccounId {get;set;}
    public string Id {get;set;}
    public string AccountName {get;set;}
    public string AccountId {get;set;}
    public string ProductName {get;set;}
    public string Name{get;set;}
    public string ProductId{get;set;}
    public string Active{get;set;}
    public boolean Existing{get;set;}
    public boolean Bundled{get;set;}
    public decimal Quantity{get;set;}
    public decimal ListUnitPrice{get;set;}
    public decimal SalesUnitPrice{get;set;}
    public decimal SalesTotal{get;set;}
}