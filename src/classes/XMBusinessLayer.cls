public class XMBusinessLayer  {

    private string guid = null;
    private Set<id> acc = new Set<id>();

    public XMBusinessLayer(){}

    public XMBusinessLayer(string contactId) {

        List<Contact> contacts = [select xmPerson__c, AccountId, xmPerson__r.xmPersonUID__c from contact where id = :contactId];

        if(contacts[0].xmPerson__c != null){
            for (Contact con : [
                    select Id, xmPerson__c, AccountId
                    from Contact
                    Where xmPerson__c = :contacts[0].xmPerson__c
            ]) {
                acc.add(con.AccountId);
            }
        }else{
            acc.add(contacts[0].AccountId);
        }

        guid = contacts[0].xmPerson__r.xmPersonUID__c;
    }

    public Map<String, XMGroupProductCluster> GetGroupListByUserid(){
        return GetGroupListByUserid(guid, acc);
    }

    //Return full list of groups that an account can have
    public Map<String, XMGroupProductCluster> GetGroupListByUserid(string guid, Set<id> acc){

        XMRestGroup xmRest = new XMRestGroup();
        Map<String, XMGroupProductCluster> xmSalesForceGroupMap = GetSalesForceGroupData(acc);
        System.debug('xmSalesForceGroupMap -- >' + xmSalesForceGroupMap);
        List<XMGroupProductCluster> xmFinalList = new List<XMGroupProductCluster>();
        List<XMGroupMemberModel> xmGrouplist = new List<XMGroupMemberModel>();


        if(guid != null){
            xmGrouplist  = xmRest.GetXMPersonGroupsById(guid);
        }

        system.debug('XMGroupList -->' + xmGrouplist);
        if(xmGrouplist != null)
        {
            xmFinalList = GetXMGroupList(xmGrouplist,guid);
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
        System.debug('Final List being returned to SF -->' + xmSalesForceGroupMap);

        XMDeviceWrapper[] newDeviceList = new XMDeviceWrapper[]{};
        newDeviceList = XMPersonManagementHelper.getUserDevices(guid);

        System.debug('new device -->' + ':' + newDeviceList);

        //loop through and add any missing devices to the list mark them as unchecked
        System.debug('PreReturnedToSF -->' + ':' + xmSalesForceGroupMap.values());
        AddMissingDevicesToList(newDeviceList, xmSalesForceGroupMap.values());
        System.debug('ListReturnedToSF -->' + ':' + xmSalesForceGroupMap.values());

        return xmSalesForceGroupMap;
    }

    //Parses ist of XM low level models into one that is used by the business layer
    private List<XMGroupProductCluster> GetXMGroupList(List<XMGroupMemberModel> groupList, string userId)
    {
        try{
            List<XMGroupProductCluster> xmGroupClusterObjList = new List<XMGroupProductCluster>();
            Integer i = 0;
            System.debug('GetXMGroupList --> called');

            System.debug('userid -->' + ':' + userId);



            for (XMGroupMemberModel groupObj : groupList)
            {

                i++;
                boolean isSkipped = false;

                XMGroupProductCluster xmGroupClusterObj = new XMGroupProductCluster();
                if(groupObj.group1 != null)
                {
                    if(groupObj.group1.targetName.substring(0,2) == 'IP')
                    {
                        for(XMGroupProductCluster xmGroupCluster : xmGroupClusterObjList)
                        {
                            if(xmGroupCluster.XmattersGroupName == groupObj.group1.targetName)
                            {
                                if(groupObj.member != null){
                                    groupObj.member.checked = true;
                                    xmGroupCluster.Devices.add(groupObj.member);
                                    isSkipped = true;

                                }
                            }
                        }
                        if(!isSkipped)
                        {
                            List<String> splitTargetName = groupObj.group1.targetName.split('_');
                            xmGroupClusterObj.PartnerPrefix = splitTargetName[1];
                            xmGroupClusterObj.Product = splitTargetName[2];
                            xmGroupClusterObj.Cluster = splitTargetName[3];
                            //xmGroupClusterObj.Devices.add(sdfsf);
                            if(groupObj.member != null){

                                xmGroupClusterObj.Devices.add(groupObj.member);
                            }
                            xmGroupClusterObj.XmattersGroupName = groupObj.group1.targetName;
                            xmGroupClusterObjList.add(xmGroupClusterObj);
                        }

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
        catch(Exception ex)
        {
            System.debug('GetXMGroupList  -->'  + ex.getMessage());
            throw ex;
        }
    }

    public void AddMissingDevicesToList(XMDeviceWrapper[] newDeviceList, List<XMGroupProductCluster> xmGroupClusterObjList) {
        try{
               System.debug('AddMissingDevicesToList --> entered');
               //System.debug('AddMissingDevicesToList --> ' + xmGroupClusterObjList) ;
               for (XMGroupProductCluster xmGroupCluster : xmGroupClusterObjList) {
                   System.debug('AddMissingDevicesToList --> looping through the list');
                   for (XMDeviceWrapper device : newDeviceList) {
                       boolean skip = false;
                       for (xmPersonMemberModel xmModel: xmGroupCluster.Devices) {
                           System.debug('AddMissingDevicesToList compare xmModel Type--> ' + xmModel );
                           System.debug('AddMissingDevicesToList compare device Type--> ' + device );
                           if (xmModel.targetName.contains(device.name)) {
                               skip = true;
                               xmModel.checked = true;
                               System.debug('AddMissingDevicesToList --> record already present');
                            }
                       }
                       if (skip == false) {
                           System.debug('AddMissingDevicesToList --> adding a record');
                           System.debug('Record being added -->' + device);
                           xmPersonMemberModel xmNewModel = new xmPersonMemberModel();
                           xmNewModel.checked = false;
                           xmNewModel.recipientType = device.deviceType;
                           xmNewModel.id = device.deviceId;
                           xmNewModel.targetName = device.name;
                           xmGroupCluster.Devices.add(xmNewModel);
                       }
                   }
               }

       }
       catch(Exception ex)
       {
           System.debug('Error in AddMissingDevicesToList  -->'  + ex.getMessage());
       }
    }

    //Returns a list of salesforce product based groups an account belongs to
    public Map<String, XMGroupProductCluster> GetSalesForceGroupData(Set<id> acc){

        List<XMGroupProductCluster> availableProducts = new List<XMGroupProductCluster>();
        string partnerPrefix;
        Map<String, ProductEventMap__c> nodeMap;
        nodeMap = ProductEventMap__c.getAll();
        //get account assocaited products
        //Get reference to the product map
        //Iterate over the implemented prodcuts
        ImplementedProduct__c[] includedProducts = new ImplementedProduct__c[] {};

        //systXMem.debug (includedProducts);
        Map<String, XMGroupProductCluster> groupListMap = new Map<String, XMGroupProductCluster>();
        for ( ImplementedProduct__c product : [SELECT   Account__c,Product__c,
                                                Account__r.ParentId,
                                                Account__r.inContact_Cluster__c, Account__r.Verint_Cluster__c,
                                                Account__r.NICE_WFM_Cluster__c,Account__r.XMPartnerPrefix__c, Account__r.NICE_QM_Cluster__c,
                                                Account__r.Parent.XMPartnerPrefix__c
                                                FROM ImplementedProduct__c
                                                WHERE Account__c in :acc  and Account__r.CG_Disconnect_Date__c = NULL
                                                AND(GoLiveDate__c <= TODAY
                                                OR(EstimatedGoLiveDate__c <= NEXT_N_DAYS : 14
                                                AND Status__c not in('Canceled', 'Deactivated')))])
         {
             system.debug ( 'product -->' + product);
             ProductEventMap__c productMap = nodeMap.get(product.Product__c);
             system.debug (productMap);
             if (productMap != null) {
                 if (product.Account__r.Parent != null)
                 {
                     partnerPrefix =  product.Account__r.Parent.XMPartnerPrefix__c;
                 }
                 else if ( product.Account__r.XMPartnerPrefix__c !=null)
                 {
                     partnerPrefix =  product.Account__r.XMPartnerPrefix__c;
                 }
                 ProductClusterMapClass prodMap = new ProductClusterMapClass(
                         productMap.Name,
                         product.Account__r.inContact_Cluster__c,
                         product.Account__r.Verint_Cluster__c,
                         product.Account__r.NICE_WFM_Cluster__c,
                         product.Account__r.NICE_QM_Cluster__c,
                         partnerPrefix ,
                         productMap
                        );

                 XMGroupProductCluster groupData = GetGroupDataMap(prodMap);
                 groupListMap.put(groupData.XmattersGroupName,groupData);
                }
                else{
                    system.debug('Warning product not found in the product map!!!');
                }
        }
        return groupListMap;
    }

    public XMGroupProductCluster GetGroupDataMap(ProductClusterMapClass prodMapClass){


        XMGroupProductCluster groupData = new XMGroupProductCluster();

        groupData.Product =  prodMapClass.Product;
        string partnerPrefix;
        if(prodMapClass.InContactCluster != NULL && prodMapClass.ProductMap.Platform__c.startsWith('Cluster'))
            groupData.Cluster =  prodMapClass.ProductMap.Platform__c.replaceFirst('Cluster', prodMapClass.InContactCluster.trim());
        if(prodMapClass.VerintCluster != NULL && prodMapClass.ProductMap.Platform__c.startsWith('Verint')) // arnab
            groupData.Cluster = prodMapClass.ProductMap.Platform__c.replaceFirst('Verint', prodMapClass.VerintCluster.trim());
        if(prodMapClass.NiceWFMCluster != NULL && prodMapClass.ProductMap.Platform__c.startsWith('NWFM')) // arnab
            groupData.Cluster = prodMapClass.ProductMap.Platform__c.replaceFirst('NWFM', prodMapClass.NiceWFMCluster.trim());
        if(prodMapClass.NiceQMCLuster != NULL && prodMapClass.ProductMap.Platform__c.startsWith('NQM')) // arnab
            groupData.Cluster = prodMapClass.ProductMap.Platform__c.replaceFirst('NQM', prodMapClass.NiceQMCLuster.trim());

        groupData.PartnerPrefix = prodMapClass.PartnerPrefix;
        groupData.XmattersGroupName = GetGroupName(groupData);

       return groupData;
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
            system.debug('UpdateXMUserToGroups => ***- Entering -***');

            List<XMGroupMemberModel> xmList  = xmRestGroupObj.GetXMPersonGroupsById(userID);
            system.debug('UpdateXMUserToGroups list of groups by id => ' + xmList );
            List<XMGroupProductCluster> xmCurrentGroupList = GetXMGroupList(xmList,userID);
            system.debug('UpdateXMUserToGroups current list of groups => ' + xmCurrentGroupList );

            for(XMGroupProductCluster groupObj:groupList)
            {
                for(xmPersonMemberModel deviceObj:groupObj.Devices){

                    //List<XMGroupMemberModel> xmList  = xmRestGroupObj.GetXMPersonGroupsById(userID);
                    //system.debug('UpdateXMUserToGroups list of groups by id => ' + xmList );
                    //List<XMGroupProductCluster> xmCurrentGroupList = GetXMGroupList(xmList,userID);
                    //system.debug('UpdateXMUserToGroups current list of groups => ' + xmCurrentGroupList );

                    System.debug('xmCurrentGroupList = >' + xmCurrentGroupList);
                    if (deviceObj.checked == true) {
                        xmGroupModelList = xmRestGroupObj.GetAllGroupsByPrefix(groupObj.XmattersGroupName);
                        system.debug('xmGroupModelList =>' + xmGroupModelList);
                        if (xmGroupModelList[0].id != null) {
                            system.debug ( ' xmGroupModelList =>'  + xmGroupModelList.size());
                            if (isUserMemberofGroup(groupObj.XmattersGroupName, deviceObj,xmCurrentGroupList) == false)
                            {
                                system.debug('** Adding user to group ** ==>' + groupObj.XmattersGroupName );
                                responseBody = xmRestGroupObj.AddUserToGroup(groupObj.XmattersGroupName, deviceObj.id, 'Device');
                            }
                        }
                        else {
                            //build the group on the fly
                            isGroupCreated = xmRestGroupObj.CreateNewGroup(groupObj.XmattersGroupName);
                            if (isGroupCreated) {
                                xmGroupModelList = xmRestGroupObj.GetAllGroupsByPrefix(groupObj.XmattersGroupName);
                                if (xmGroupModelList.size() > 0) {
                                    responseBody = xmRestGroupObj.AddUserToGroup(groupObj.XmattersGroupName, deviceObj.id, 'Device');
                                }
                            }
                        }
                    }
                    else{
                        if (xmCurrentGroupList != null && xmCurrentGroupList.isEmpty() == false)
                        {
                            System.debug('Group List');
                            if(isUserMemberofGroup(groupObj.XmattersGroupName,deviceObj,xmCurrentGroupList) == true) {
                                System.debug('Found in users group list -> ' + groupObj.XmattersGroupName );
                                xmRestGroupObj.RemoveUserFromAGroup(groupObj.XmattersGroupName, deviceObj.id);
                            }
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
    private boolean isUserMemberofGroup (string groupName,xmPersonMemberModel device,  List<XMGroupProductCluster> xmCurrentGroupList ){

        for ( XMGroupProductCluster xm : xmCurrentGroupList ){
            if (xm.XmattersGroupName == groupName){
                    system.debug('*** groupName => ' + groupName);

                for (xmPersonMemberModel currentDevice :xm.Devices){
                    system.debug('***Current Device --> ' + currentDevice);
                    system.debug('***Camparing Device --> ' + device);

                    if (currentDevice.id == device.id && currentDevice.checked == true){
                        system.debug('***returning a true for  --> ' + device);
                        return true;
                    }
                }

            }
        }
        system.debug('***returning a false for  --> ' + device);
        return false;
    }

    public class ProductClusterMapClass{
       public string Product;
       public string InContactCluster;
       Public string VerintCluster;
       Public string NiceWFMCluster;
       Public string NiceQMCLuster;
       Public string PartnerPrefix;
       Public ProductEventMap__c ProductMap;
        public ProductClusterMapClass(string product, string inContactCluster, string verintCluster,
                                      string niceWFMCluster, string niceQMCLuster, string partnerPrefix, ProductEventMap__c productMap){

            this.Product = product;
            this.InContactCluster = inContactCluster;
            this.VerintCluster = verintCluster;
            this.NiceWFMCluster = niceWFMCluster;
            this.NiceQMCLuster = niceQMCLuster;
            this.PartnerPrefix = partnerPrefix;
            this.ProductMap = productMap;

        }
    }


}