
public with sharing class XMBusinessLayer implements XMiBusiness {

    public List<XMGroupProductCluster> GetGroupListByUserid(string guid){
        XMRestGroup xmRest = new XMRestGroup();
        List<XMGroupProductCluster> xmFinalList = new List<XMGroupProductCluster>();
        List<XMGroupMemberModel> xmGrouplist  = xmRest.GetXMPersonGroupsById(guid);
        system.debug(xmGrouplist);
        xmFinalList = GetXMGroupList(xmGrouplist);
        return xmFinalList;
    }
    public boolean SetGroupListForUser(string guid, List<XMGroupProductCluster> grouplist){
        throw new CalloutException();
    }

    private List<XMGroupProductCluster> GetXMGroupList(List<XMGroupMemberModel> groupList)
    {
        List<XMGroupProductCluster> xmGroupClusterObjList = new List<XMGroupProductCluster>();
        for (XMGroupMemberModel groupObj : groupList)
        {
            XMGroupProductCluster xmGroupClusterObj = new XMGroupProductCluster();
            if(groupObj.group1.targetName.substring(0,2) == 'IP')
            {
                List<String> splitTargetName = groupObj.group1.targetName.split('_');
                xmGroupClusterObj.Product = splitTargetName[2];
                xmGroupClusterObj.Cluster = splitTargetName[3];
                xmGroupClusterObjList.add(xmGroupClusterObj);
            }
        }
        return xmGroupClusterObjList;
    }

    public List<XMGroupProductCluster> GetSalesForceGroupData(Account acc){

        Map<String, ProductEventMap__c> nodeMap;
        nodeMap = ProductEventMap__c.getAll();
        List<XMGroupProductCluster> availableProducts = new List<XMGroupProductCluster>();

        //get account assocaited products
        //Get reference to the product map
        //Iterate over the implemented prodcuts
        ImplementedProduct__c[] includedProducts = new ImplementedProduct__c[] {};

        includedProducts = [SELECT Account__c,Product__c
        FROM ImplementedProduct__c
        WHERE Account__c =: acc.id  and Account__r.CG_Disconnect_Date__c = NULL
        AND(GoLiveDate__c <= TODAY
        OR(EstimatedGoLiveDate__c <= NEXT_N_DAYS : 14
        AND Status__c != 'Canceled'))];

        system.debug (includedProducts);

        for (ImplementedProduct__c product : includedProducts ){
            ProductEventMap__c productMap = nodeMap.get(product.Product__c);
            system.debug (productMap);

        }
        return null;
    }

}