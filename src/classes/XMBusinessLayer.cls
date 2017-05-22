public with sharing class XMBusinessLayer implements XMiBusiness {

    //Return full list of groups that an account can have
    public Map<String, XMGroupProductCluster> GetGroupListByUserid(string guid, Account acc){
        XMRestGroup xmRest = new XMRestGroup();
        Map<String, XMGroupProductCluster> xmSalesForceGroupMap = GetSalesForceGroupData(acc);
        System.debug('xmSalesForceGroupMap -- >' + xmSalesForceGroupMap);
        List<XMGroupProductCluster> xmFinalList = new List<XMGroupProductCluster>();
        List<XMGroupMemberModel> xmGrouplist  = xmRest.GetXMPersonGroupsById(guid);
        system.debug('XMGroupList -->' + xmGrouplist);
        if(xmGrouplist != null)
        {
            xmFinalList = GetXMGroupList(xmGrouplist);
            System.debug('xmFinalList-->' + xmFinalList);
        }
        List<XMGroupProductCluster> returnXMFinalProductClusterList = new List<XMGroupProductCluster>();
        for(XMGroupProductCluster xmFinalListObj: xmFinalList)
        {
            XMGroupProductCluster returnXMFinalProductCluster = new XMGroupProductCluster();
            String xmFinalListObjKey = 'IP_'+ xmFinalListObj.PartnerPrefix + '_' + xmFinalListObj.Product + '_' + xmFinalListObj.Cluster;
            if(xmSalesForceGroupMap.containsKey(xmFinalListObjKey))
            {
                xmSalesForceGroupMap.put(xmFinalListObjKey, xmFinalListObj);
            }

            System.debug('xmSalesForceGroupMap -->' + xmSalesForceGroupMap);
        }
        return xmSalesForceGroupMap;
    }
    public boolean SetGroupListForUser(string guid, List<XMGroupProductCluster> grouplist){
        throw new CalloutException();
    }

    //Parses ist of XM low level models into one that is used by the business layer
    private List<XMGroupProductCluster> GetXMGroupList(List<XMGroupMemberModel> groupList)
    {
        List<XMGroupProductCluster> xmGroupClusterObjList = new List<XMGroupProductCluster>();
        Integer i = 0;
        for (XMGroupMemberModel groupObj : groupList)
        {
            i++;
            XMGroupProductCluster xmGroupClusterObj = new XMGroupProductCluster();
            if(groupObj.group1 != null)
            {
                if(groupObj.group1.targetName.substring(0,2) == 'IP')
                {
                    List<String> splitTargetName = groupObj.group1.targetName.split('_');
                    xmGroupClusterObj.PartnerPrefix = splitTargetName[1];
                    xmGroupClusterObj.Product = splitTargetName[2];
                    xmGroupClusterObj.Cluster = splitTargetName[3];
                    xmGroupClusterObj.selected = true;
                    xmGroupClusterObjList.add(xmGroupClusterObj);
                }
                String testName = 'xmGroupClusterObj' + String.valueOf(i);

                System.debug(testName + ':' + xmGroupClusterObj);
            }


        }
        return xmGroupClusterObjList;
    }



    //Returns a list of salesforce product based groups an account belongs to
    private Map<String, XMGroupProductCluster> GetSalesForceGroupData(Account acc){

        Map<String, ProductEventMap__c> nodeMap;
        nodeMap = ProductEventMap__c.getAll();
        List<XMGroupProductCluster> availableProducts = new List<XMGroupProductCluster>();
        string partnerPrefix;

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

        //systXMem.debug (includedProducts);
        Map<String, XMGroupProductCluster> groupListMap = new Map<String, XMGroupProductCluster>();
        for (ImplementedProduct__c product : includedProducts ){
            system.debug ( 'product -->' + product);
            XMGroupProductCluster groupData = new XMGroupProductCluster();
            ProductEventMap__c productMap = nodeMap.get(product.Product__c);
            system.debug (productMap);
            if (productMap != null) {
                groupData.Product = productMap.Name;
                if (productMap.HasClusters__c == true){
                    groupData.Cluster = acc.Cluster__c;
                }
                if (groupData.Cluster == null || groupData.Cluster == ''){
                    //default cluster description
                    groupData.Cluster = 'NONE';
                }
                if (acc.Parent != null)
                {
                    groupData.PartnerPrefix =  acc.Parent.XMPartnerPrefix__c;
                }
                if (groupData.PartnerPrefix == null)
                {
                    //default partner designation
                    groupData.PartnerPrefix = 'INC';
                }
                groupData.XmattersGroupName = 'IP_'+ groupData.PartnerPrefix + '_' + groupData.Product + '_'  + groupData.Cluster;
                system.debug(groupData);
                groupListMap.put(groupData.XmattersGroupName,groupData);
            }
        }
        return groupListMap;
    }

    //Update the contacts xmatters group memebership
    public String UpdateXMUserToGrouops(List<XMGroupProductCluster> groupList, String userID)
    {
        List<XMGroupModel> xmGroupModelList = new List<XMGroupModel>();
        XMRestGroup xmRestGroupObj = new XMRestGroup();
        String successMessage;

        for(XMGroupProductCluster groupObj:groupList)
        {
            if (groupObj.selected == true) {
                xmGroupModelList = xmRestGroupObj.GetAllGroupsByPrefix(groupObj.XmattersGroupName);
                if (xmGroupModelList.size() > 0) {
                    xmRestGroupObj.AddUserToGroup(groupObj.XmattersGroupName, userID, 'Person');
                    successMessage = 'User information updated in xMatters.';
                }
                else {
                    //build the group on the fly
                    Boolean isGroupCreated;
                    isGroupCreated = xmRestGroupObj.CreateNewGroup(groupObj.XmattersGroupName);
                    if (isGroupCreated) {
                        xmGroupModelList = xmRestGroupObj.GetAllGroupsByPrefix(groupObj.XmattersGroupName);
                        if (xmGroupModelList.size() > 0) {
                            xmRestGroupObj.AddUserToGroup(groupObj.XmattersGroupName, userID, 'Person');
                            successMessage = 'User has been successfully added to the selected groups.';
                        }
                    }

                }
            }
            else{
                xmRestGroupObj.RemoveUserFromAGroup(groupObj.XmattersGroupName, userID);
            }
        }

        if(successMessage != '' && successMessage != null)
            return successMessage;
        else
            return 'There are some issues in adding user to the selected group, please try again or call administrator.';
    }


}