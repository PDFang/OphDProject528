/**
 * Created by arnab.karsarkar on 9/21/2017.
 */

public class AssociatedContactList {
	public string AccountName{get;set;}
	public string AccountId{get;set;}
	public string ContactFirstName{get;set;}
	Public string ContactLastName{get;set;}
	Public string ContactId{get;set;}
	Public string CadebillAccountNum{get;set;}
	Public string xmPersonId{get;set;}
	public  list<XMGroupProductCluster> ProductClusters{get;set;}
	public AssociatedContactList(){
		ProductClusters = new list<XMGroupProductCluster>();
	}


}