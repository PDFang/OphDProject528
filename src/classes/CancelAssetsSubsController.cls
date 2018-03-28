/**
 * Created by arnab.karsarkar on 3/20/2018.
 */

public class CancelAssetsSubsController {

	public string ParentProjectId{get; set;}
	public string selectedDepartment{get; set;}
	public string selectedRootCause{get; set;}
	public boolean isError{get;set;}

	public static Project__c parentProject;

	public static set<string> ParentRecordtypes = new set<string>{'PS Parent Project - Premise', 'PS Parent Project - SaaS'};

	public List<SelectOption> Departments
	{
		get
		{

			Schema.DescribeFieldResult F = Asset.Department_Responsible__c.getDescribe();
			List<SelectOption> options = new List<SelectOption>();
			options.add(new SelectOption('', ''));
			for(Schema.PicklistEntry pl:F.getPicklistValues())
			{
				options.add(new SelectOption(pl.getValue(), pl.getLabel()));
			}

			return options;
		}
	}

	public List<SelectOption> RootCase
	{
		get
		{
			Schema.DescribeFieldResult F = Asset.Root_Cause__c.getDescribe();
			List<SelectOption> options = new List<SelectOption>();
			options.add(new SelectOption('', ''));
			for(Schema.PicklistEntry pl:F.getPicklistValues())
			{
				options.add(new SelectOption(pl.getValue(), pl.getLabel()));
			}

			return options;
		}
	}

	public string AdditionalDetails{get;set;}


	public CancelAssetsSubsController(ApexPages.StandardController controller){
		ParentProjectId = (string)controller.getId();
		isError = false;
		parentProject = [select Id, RecordType.Name from Project__c where Id =: ParentProjectId Limit 1];
		if(!ParentRecordtypes.contains(parentProject.RecordType.Name)){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Only Parent PS projects can be used to cancel the Assets/Subscriptions'));
			isError = true;
		}


	}

	private static Boolean isManager(){
		List<GroupMember> allGroupIDs = [SELECT Id, group.id, group.name FROM GroupMember
									     where UserOrGroupId = :UserInfo.getUserId() AND group.DeveloperName ='PS_Projects_Assets_Management'];
		System.debug('allGroupIDs' + allGroupIDs);
		if(allGroupIDs.size() > 0)
			return true;

		return false;
	}

	public pagereference cancel(){
		return new PageReference('/'+ParentProjectId).setRedirect(true);
	}

	@RemoteAction
	public static string GetAllAssets(string projectId){
		boolean manager = isManager();
		list<GridDetails> lstGridDetails = new list<GridDetails>();
		for(Asset asset : [select Id, Name, RemainingQuantity__c,QuantityCancelled__c, Total_Allocated_Quantity__c,Quantity, Sales_Price__c, Remaining_Hours__c
						   From Asset
						   where Parent_Project__c =: projectId and RemainingQuantity__c >= 1
						   Order by RemainingQuantity__c desc])
		{
			if(asset.Total_Allocated_Quantity__c == 0){
				if(manager)
					lstGridDetails.add(new GridDetails(asset));
			}else{
				lstGridDetails.add(new GridDetails(asset));
			}
		}

		return JSON.serialize(lstGridDetails);
	}

	@RemoteAction
	public static string GetAllSubscriptions(string projectId){
		boolean manager = isManager();
		list<GridDetails> lstGridDetails = new list<GridDetails>();
		for(SubscriptionReplica__c subs: [select Id, Subscription_Name__c,QuantityCancelled__c, RemainingQuantity__c, Total_Allocated_Quantity__c,Quantity__c, SalesUnitPrice__c
										  From SubscriptionReplica__c
										  where ParentProject__c =: projectId and RemainingQuantity__c >= 1
										  Order by RemainingQuantity__c desc	])
		{
			if(subs.Total_Allocated_Quantity__c == 0){
				if(manager)
					lstGridDetails.add(new GridDetails(subs));
			}else{
				lstGridDetails.add(new GridDetails(subs));
			}
		}

		return JSON.serialize(lstGridDetails);
	}

	@RemoteAction
	public static string CancelAllAssets(string jsonAssetLists){
		try{
			system.debug('CancelAllAssets(): jsonAssetLists - '+jsonAssetLists);
			List<Asset> assetList = (List<Asset>)JSON.deserialize(jsonAssetLists, List<Asset>.class);
			system.debug('CancelAllAssets(): assetList - '+assetList);
			if(assetList != null)
				update assetList;
			return 'Success';
		}catch (Exception ex){

			string message = ex.getMessage();

			if (ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
				message = simplyfyErrorMessage(message);
			}
			else {
				message = ex.getMessage();
			}

			return message;
		}

	}

	@RemoteAction
	public static string CancelAllSubs(string jsonSubscriptionList){
		try{
			system.debug('CancelAllAssets(): jsonSubscriptionList - '+jsonSubscriptionList);
			List<SubscriptionReplica__c> subsList = (List<SubscriptionReplica__c>)JSON.deserialize(jsonSubscriptionList, List<SubscriptionReplica__c>.class);
			system.debug('CancelAllAssets(): subsList - '+subsList);
			if(subsList != null)
				update subsList;
			return 'Success';
		}catch (Exception ex){

			string message = ex.getMessage();

			if (ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
				message = simplyfyErrorMessage(message);
			}
			else {
				message = ex.getMessage();
			}

			return message;
		}

	}

	@TestVisible
	private static string simplyfyErrorMessage(string result){
		Integer occurence;
		occurence = result.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION,') + 34;
		result = result.mid(occurence, result.length());
		occurence = result.lastIndexOf(':');
		result = result.mid(0, occurence);
		return result;
	}



	// wrapper class
	public class GridDetails{
		public string RecordId {get;set;}
		public string Name {get;set;}
		public Double RemainingQuantity{get;set;}
		public Double TotalAllocatedQuantity{get;set;}
		public Double ContractQuantity{get;set;}
		public Double SalesPrice{get;set;}
		public Double RemainingHours{get;set;}
		public Double CancelledQuantity{get;set;}

		public GridDetails(Asset asset){
			this.RecordId = asset.Id;
			this.Name = asset.Name;
			this.RemainingQuantity = asset.RemainingQuantity__c;
			this.TotalAllocatedQuantity = asset.Total_Allocated_Quantity__c;
			this.ContractQuantity = asset.Quantity;
			this.SalesPrice = asset.Sales_Price__c;
			this.RemainingHours = asset.Remaining_Hours__c;
			this.CancelledQuantity = asset.QuantityCancelled__c == null ? 0 : asset.QuantityCancelled__c;
		}

		public GridDetails(SubscriptionReplica__c subs){
			this.RecordId = subs.Id;
			this.Name = subs.Subscription_Name__c;
			this.RemainingQuantity = subs.RemainingQuantity__c;
			this.TotalAllocatedQuantity = subs.Total_Allocated_Quantity__c;
			this.ContractQuantity = subs.Quantity__c;
			this.SalesPrice = subs.SalesUnitPrice__c;
			this.CancelledQuantity = subs.QuantityCancelled__c == null ? 0 : subs.QuantityCancelled__c;
		}
	}

}