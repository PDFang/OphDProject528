/**
 * Created by william.nelson on 7/19/2017.
 */

public with sharing class AssetSubscriptionAllocation {
    Id PhaseProjectId {get;set;}
    string PhaseProjectName {get;set;}
    Id AssetSubscriptionId {get;set;}
    Integer Quantity;
    Double Percentage {get;set;}

}