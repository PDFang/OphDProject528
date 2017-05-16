
public with sharing class XMBusinessLayer implements XMiBusiness {

    public List<XMGroupProductCluster> GetGroupListByUserid(string guid, Account acc){
        XMRestGroup xmRest = new XMRestGroup();
        List<XMGroupProductCluster> xmSalesForceGroup = GetSalesForceGroupData(acc);
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
                xmGroupClusterObj.PartnerPrefix = splitTargetName[1];
                xmGroupClusterObj.Product = splitTargetName[2];
                xmGroupClusterObj.Cluster = splitTargetName[3];
                xmGroupClusterObj.selected = true;
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

        //system.debug (includedProducts);
        List<XMGroupProductCluster> groupList = new List<XMGroupProductCluster>();
        for (ImplementedProduct__c product : includedProducts ){

            XMGroupProductCluster groupData = new XMGroupProductCluster();
            ProductEventMap__c productMap = nodeMap.get(product.Product__c);
            system.debug (productMap);
            if (productMap != null) {
                groupData.Product = productMap.Name;
                if (productMap.HasClusters__c == true)
                    groupData.Cluster = acc.Cluster__c; else {
                    groupData.Cluster = 'NONE';
                }

                //determine the partner

                groupData.XmattersGroupName = 'IP_INC_' + groupData.Product + '_'  + groupData.Cluster;
                groupList.add(groupData);
            }
            system.debug (groupData);

        }
        return groupList;
    }

}