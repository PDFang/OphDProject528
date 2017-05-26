public class XMGroupProductCluster {
    public string Product {get;set;}
    public string Cluster {get;set;}
    public string PartnerPrefix {get;set;}
    public string XmattersGroupName {get;set;}
    public boolean selected {get;set;}

    public XMGroupProductCluster(){
        this.selected = false;
    }
}