public class XMBusinessLayer implements XMiBusiness {

    private string guid = null;
    private Account acc = null;

    public XMBusinessLayer(){}

    public XMBusinessLayer(String contactId){

        Contact[] contactList = [
                Select Id, xmPerson__c, xmPerson__r.xmPersonUID__c, accountId, account.ParentId,
                        account.inContact_Cluster__c, account.Verint_Cluster__c,account.XMPartnerPrefix__c,
                        account.NICE_WFM_Cluster__c, account.NICE_QM_Cluster__c, account.RecordType.Name,
                        account.Parent.XMPartnerPrefix__c
                From Contact
                where Id = :contactId
        ];

        acc = contactList[0].Account;
        guid = contactList[0].xmPerson__r.xmPersonUID__c;

    }

    public Map<String, XMGroupProductCluster> GetGroupListByUserid(){
        return GetGroupListByUserid(guid, acc);
    }

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
            else{
                //need business rule on this log it to the log for now
                system.debug('Warning! xmatters group not found in salesforce group for this account');
            }

            System.debug('xmSalesForceGroupMap -->' + xmSalesForceGroupMap);
        }
        return xmSalesForceGroupMap;
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
                    xmGroupClusterObj.XmattersGroupName = groupObj.group1.targetName;
                    xmGroupClusterObjList.add(xmGroupClusterObj);
                }
                String testName = 'xmGroupClusterObj' + String.valueOf(i);

                System.debug(testName + ':' + xmGroupClusterObj);
            }
            else{
                System.debug('Warning empty group name');
            }


        }
        return xmGroupClusterObjList;
    }



    //Returns a list of salesforce product based groups an account belongs to
    public Map<String, XMGroupProductCluster> GetSalesForceGroupData(Account acc){

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

                if(acc.inContact_Cluster__c != NULL && productMap.Platform__c.startsWith('Cluster'))
                    groupData.Cluster = productMap.Platform__c.replaceFirst('Cluster', acc.inContact_Cluster__c.trim());
                if(acc.Verint_Cluster__c != NULL && productMap.Platform__c.startsWith('Verint')) // arnab
                    groupData.Cluster = productMap.Platform__c.replaceFirst('Verint', acc.Verint_Cluster__c.trim());
                if(acc.NICE_WFM_Cluster__c != NULL && productMap.Platform__c.startsWith('NWFM')) // arnab
                    groupData.Cluster = productMap.Platform__c.replaceFirst('NWFM', acc.NICE_WFM_Cluster__c.trim());
                if(acc.NICE_QM_Cluster__c != NULL && productMap.Platform__c.startsWith('NQM')) // arnab
                    groupData.Cluster = productMap.Platform__c.replaceFirst('NQM', acc.NICE_QM_Cluster__c.trim());
                if (acc.Parent != null)
                {
                    groupData.PartnerPrefix =  acc.Parent.XMPartnerPrefix__c;
                }else if(acc.XMPartnerPrefix__c != null){
                    groupData.PartnerPrefix =  acc.XMPartnerPrefix__c;
                }
                groupData.XmattersGroupName = GetGroupName(groupData);
                system.debug( 'groupData -->' + groupData);
                groupListMap.put(groupData.XmattersGroupName,groupData);
            }
            else{
                system.debug('Warning product not found in the product map!!!');
            }
        }
        return groupListMap;
    }

    public string GetGroupName(XMGroupProductCluster groupData){

        string XmattersGroupName;
        if (groupData.Cluster == null || groupData.Cluster == ''){
            //default cluster description
            groupData.Cluster = 'NONE';
        }
        if (groupData.PartnerPrefix == null || groupData.PartnerPrefix == '')
        {
            //default partner designation
            groupData.PartnerPrefix = 'INC';
        }
        XmattersGroupName = 'IP_'+ groupData.partnerPrefix + '_' + groupData.product + '_'  + groupData.cluster;
        return XmattersGroupName.replace(' ','');
    }

    //Update the contacts xmatters group memebership
    public String UpdateXMUserToGroups(List<XMGroupProductCluster> groupList, String userID)
    {
        List<XMGroupModel> xmGroupModelList = new List<XMGroupModel>();
        XMRestGroup xmRestGroupObj = new XMRestGroup();
        String responseBody;
        String successMessage;
        Boolean isGroupCreated;

        try
        {

            List<XMGroupMemberModel> xmList  = xmRestGroupObj.GetXMPersonGroupsById(userID);
            List<XMGroupProductCluster> xmCurrentGroupList = GetXMGroupList(xmList);

            System.debug(xmCurrentGroupList);

            for(XMGroupProductCluster groupObj:groupList)
            {
                if (groupObj.selected == true) {
                    xmGroupModelList = xmRestGroupObj.GetAllGroupsByPrefix(groupObj.XmattersGroupName);
                    system.debug('xmGroupModelList =>' + xmGroupModelList);
                    if (xmGroupModelList[0].id != null) {
                        system.debug ( ' xmGroupModelList =>'  + xmGroupModelList.size());
                        if (isUserMemberofGroup(groupObj.XmattersGroupName,xmCurrentGroupList) == false)
                        {
                            system.debug('** Adding user to group ** ==>' + groupObj.XmattersGroupName );
                            responseBody = xmRestGroupObj.AddUserToGroup(groupObj.XmattersGroupName, userID, 'Person');
                        }
                    }
                    else {
                        //build the group on the fly
                        isGroupCreated = xmRestGroupObj.CreateNewGroup(groupObj.XmattersGroupName);
                        if (isGroupCreated) {
                            xmGroupModelList = xmRestGroupObj.GetAllGroupsByPrefix(groupObj.XmattersGroupName);
                            if (xmGroupModelList.size() > 0) {
                                responseBody = xmRestGroupObj.AddUserToGroup(groupObj.XmattersGroupName, userID, 'Person');
                            }
                        }
                    }
                }
                else{
                    if (xmCurrentGroupList != null && xmCurrentGroupList.isEmpty() == false)
                    {
                        System.debug('Group List');
                        if(isUserMemberofGroup(groupObj.XmattersGroupName,xmCurrentGroupList) == true) {
                            System.debug('Found in users group list -> ' + groupObj.XmattersGroupName );
                            xmRestGroupObj.RemoveUserFromAGroup(groupObj.XmattersGroupName, userID);
                        }
                    }
                }
            }
        }
        catch(XMCalloutException xmCalloutException)
        {
            throw xmCalloutException;
        }

        catch(Exception ex)
        {
            XMCalloutException xmCalloutException = new XMCalloutException(ex.getMessage());
            xmCalloutException.Message = ex.getMessage();

            throw xmCalloutException;
        }

        successMessage = 'User has been successfully added to the selected groups.';
        if(successMessage != '' && successMessage != null)
            return successMessage;
        else
            return 'There are some issues in adding user to the selected group, please try again or call administrator.';
    }
    private boolean isUserMemberofGroup (string groupName, List<XMGroupProductCluster> xmCurrentGroupList ){

        for ( XMGroupProductCluster xm : xmCurrentGroupList ){
            if (xm.XmattersGroupName == groupName){
                return true;
            }
        }
        return false;
    }


}