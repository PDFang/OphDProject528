/**
 * Created by ravish.chawla on 10/10/2017.
 */

public with sharing class AssetAllocationDetailsController {
    private string currentId;
    public string projectId{get; set;}

    public Project_Asset_Allocation__c selAssetAllocation{get; private set;}
    public AssetAllocationDetailsController(ApexPages.StandardController controller){

        this.selAssetAllocation = (Project_Asset_Allocation__c)controller.getRecord();
        System.debug('selAsset ==>' + selAssetAllocation);

        if(selAssetAllocation.Id != null){
            List<Project_Asset_Allocation__c> projectAssetAllocations = new List<Project_Asset_Allocation__c>([
                    SELECT Id, Asset__r.Parent_Project__c from Project_Asset_Allocation__c where Id =: selAssetAllocation.Id
            ]);

            System.debug('projectAssetAllocations[0] ==>' + projectAssetAllocations[0]);
            projectId = projectAssetAllocations[0].Asset__r.Parent_Project__c;
            System.debug('projectId ==>' + projectId);
        }
    }
}