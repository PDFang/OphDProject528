/**
 * Created by arnab.karsarkar on 8/23/2017.
 */

public with sharing class LMATotalAmountCalcController {

	public date cutOffDate{get;set;}
	public decimal cutOffAmount{get;set;}

	public LMATotalAmountCalcController(){
		list<EDA_Cutoff__mdt> edaCutoffList = new list<EDA_Cutoff__mdt>([select Id, EDACutoffDate__c, EDACutoffLicense__c from EDA_CutOff__mdt where DeveloperName = : 'X2017' limit 1]);
		cutOffDate = edaCutoffList[0].EDACutoffDate__c;
		cutOffAmount = edaCutoffList[0].EDACutoffLicense__c;
	}

	public list<CHANNEL_ORDERS__Service_Order__c> getOrderLists(){
		set<id> serviceOrders = new set<id>();
		list<CHANNEL_ORDERS__Service_Order__c> lstOrders = new list<CHANNEL_ORDERS__Service_Order__c>();
		serviceOrders = LMAHelperClass.orderSubmitDetermination(true);
		for(CHANNEL_ORDERS__Service_Order__c order : [select Id, Name, CHANNEL_ORDERS__Customer_Org_ID__c, CHANNEL_ORDERS__Order_Type__c From CHANNEL_ORDERS__Service_Order__c where Id in : serviceOrders]){
			lstOrders.add(order);
		}

		return lstOrders;
	}
}