public class XMGroupProductCluster {
    public string Product {get;set;}
    public string Cluster {get;set;}
    public string PartnerPrefix {get;set;}
    public boolean selected {get;set;}
    public string XmattersGroupName {get;set;}
    public string AccountId{get;set;}
    public List<xmPersonMemberModel> Devices{get;set;}

    public XMGroupProductCluster(){
        this.Devices = new  List<xmPersonMemberModel>();
    }

}