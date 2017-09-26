public class XMBusinessLayer  {

    private string guid = null;
    private Set<id> acc = new Set<id>();
    public string notificationType = null;
    private XMPersonManagementHelper helper;

    public XMBusinessLayer(){}

    public XMBusinessLayer(string contactId, string type) {

        List<Contact> contacts = new list<Contact>([select xmPerson__c, AccountId, xmPerson__r.xmPersonUID__c from contact where id = :contactId]);

        if(contacts.size() > 0 && contacts[0].xmPerson__c != null){
            for (Contact con : [
                    select Id, xmPerson__c, AccountId
                    from Contact
                    Where xmPerson__c = :contacts[0].xmPerson__c
            ]) {
                acc.add(con.AccountId);
            }
            guid = contacts[0].xmPerson__r.xmPersonUID__c;
        }else if(contacts.size() > 0){
            acc.add(contacts[0].AccountId);
        }

        system.debug('acc =>' + acc);

        notificationType = type;
    }

    public Map<String, XMGroupProductCluster> GetGroupListByUserid(){
        return GetGroupListByUserid(guid, acc);
    }

    //Return full list of groups that an account can have
    public Map<String, XMGroupProductCluster> GetGroupListByUserid(string guid, Set<id> acc){

        XMRestGroup xmRest = new XMRestGroup();
        Map<String, XMGroupProductCluster> xmSalesForceGroupMap = GetSalesForceGroupData(acc);
        //System.debug('xmSalesForceGroupMap -- >' + xmSalesForceGroupMap);
        List<XMGroupProductCluster> xmFinalList = new List<XMGroupProductCluster>();
        List<XMGroupMemberModel> xmGrouplist = new List<XMGroupMemberModel>();


        if(guid != null){
            xmGrouplist  = xmRest.GetXMPersonGroupsById(guid, notificationType);
        }

        //system.debug('XMGroupList -->' + xmGrouplist);
        if(xmGrouplist != null)
        {
            xmFinalList = GetFinalGroupList(xmSalesForceGroupMap,xmGrouplist);
            //System.debug('xmFinalList-->' + xmFinalList);
        }
        List<XMGroupProductCluster> returnXMFinalProductClusterList = new List<XMGroupProductCluster>();
        for(XMGroupProductCluster xmFinalListObj: xmFinalList)
        {
            XMGroupProductCluster returnXMFinalProductCluster = new XMGroupProductCluster();
            String xmFinalListObjKey = 'IP_'+ xmFinalListObj.PartnerPrefix + '_' + xmFinalListObj.Product + '_' + xmFinalListObj.Cluster;
            if(notificationType == 'MaintType')
                xmFinalListObjKey += '_MAINT';

            if(xmSalesForceGroupMap.containsKey(xmFinalListObjKey))
            {
                xmSalesForceGroupMap.put(xmFinalListObjKey, xmFinalListObj);
            }
            else{
                //need business rule on this log it to the log for now
                system.debug('Warning! xmatters group not found in salesforce group for this account');
            }

            //System.debug('xmSalesForceGroupMap -->' + xmSalesForceGroupMap);
        }
        //System.debug('Final List being returned to SF -->' + xmSalesForceGroupMap);

        XMDeviceWrapper[] newDeviceList = new XMDeviceWrapper[]{};
        newDeviceList = XMPersonManagementHelper.getUserDevices(guid);

        //System.debug('new device -->' + ':' + newDeviceList);

        //loop through and add any missing devices to the list mark them as unchecked
        //System.debug('PreReturnedToSF -->' + ':' + xmSalesForceGroupMap.values());
        AddMissingDevicesToList(newDeviceList, xmSalesForceGroupMap.values());
        //System.debug('ListReturnedToSF -->' + ':' + xmSalesForceGroupMap.values());

        List<xmGroupChangeRequest__c> groupChangeRequestList = new List<xmGroupChangeRequest__c>();
        string queryString = 'Select Id, Status__c, xMDeviceId__c, Action__c, ImplementedProduct__r.Product__c, Account__r.inContact_Cluster__c, Account__r.Verint_Cluster__c,' +
                'Account__r.NICE_WFM_Cluster__c,Account__r.NICE_QM_Cluster__c from xmGroupChangeRequest__c where Status__c = \'In Queue\'' +
                ' and NotificationProfile__r.xmPersonUID__c =: guid';
        if(notificationType == 'MaintType')
            queryString += ' and Maintenance__c = true';
        else
                queryString += ' and Maintenance__c = false';

        Map<String, ProductEventMap__c> nodeMap;
        nodeMap = ProductEventMap__c.getAll();


        groupChangeRequestList = Database.query(queryString);
        for(XMGroupProductCluster groupProductCluster:xmSalesForceGroupMap.values()){
//            if(!groupProductCluster.Cluster.contains(' - '))
//                groupProductCluster.Cluster = groupProductCluster.Cluster.replace('-',' - ');
            for(xmGroupChangeRequest__c xmGrpChangeRequest :groupChangeRequestList){
                ProductEventMap__c productMap = nodeMap.get(xmGrpChangeRequest.ImplementedProduct__r.Product__c);
                if(productMap != null)
                {
                    ProductClusterMapClass prodMap = new ProductClusterMapClass(
                            productMap.Name,
                            xmGrpChangeRequest.Account__r.inContact_Cluster__c,
                            xmGrpChangeRequest.Account__r.Verint_Cluster__c,
                            xmGrpChangeRequest.Account__r.NICE_WFM_Cluster__c,
                            xmGrpChangeRequest.Account__r.NICE_QM_Cluster__c,
                            '' ,
                            productMap
                    );

                    XMGroupProductCluster groupData = GetGroupDataMap(prodMap);

                    if(groupData.Product == groupProductCluster.Product
                            && groupData.Cluster  == groupProductCluster.Cluster){
                        for(xmPersonMemberModel deviceObj : groupProductCluster.Devices){
                            System.debug('deviceObj.Id -->' + deviceObj.Id);
                            System.debug('xmGrpChangeRequest.xMDeviceId__c -->' + xmGrpChangeRequest.xMDeviceId__c);
                            if(deviceObj.Id == xmGrpChangeRequest.xMDeviceId__c){

                                deviceObj.grRecordId = xmGrpChangeRequest.Id;
                                if(xmGrpChangeRequest.Status__c == 'In Queue' && xmGrpChangeRequest.Action__c == 'Add')
                                    deviceObj.checked = true;
                                else if(xmGrpChangeRequest.Status__c == 'In Queue' && xmGrpChangeRequest.Action__c == 'Remove')
                                    deviceObj.checked = false;
                            }
                        }
                    }
                }
            }
        }
        //System.debug('xmSalesForceGroupMap -->' + ':' + xmSalesForceGroupMap);
        return xmSalesForceGroupMap;
    }

    private List<XMGroupProductCluster> GetFinalGroupList(Map<String, XMGroupProductCluster> xmSalesForceGroupMap, List<XMGroupMemberModel> xmGrouplist)
    {
        for (XMGroupMemberModel xmGroupObj : xmGrouplist){
            if(xmGroupObj.group1 != null){
                string xmGroupTargetName = xmGroupObj.group1.targetName;
                if(xmGroupTargetName.substring(0,2) == 'IP') {
                    if (xmSalesForceGroupMap.containsKey(xmGroupTargetName)) {
                        if (xmGroupObj.member != null) {
                            xmGroupObj.member.checked = true;
                            xmSalesForceGroupMap.get(xmGroupTargetName).Devices.add(xmGroupObj.member);
                        }
                    }
                }
            }
        }

        return xmSalesForceGroupMap.values();
    }



    public void AddMissingDevicesToList(XMDeviceWrapper[] newDeviceList, List<XMGroupProductCluster> xmGroupClusterObjList) {
        try{
            //System.debug('AddMissingDevicesToList --> entered');
            //System.debug('AddMissingDevicesToList --> ' + xmGroupClusterObjList) ;
            for (XMGroupProductCluster xmGroupCluster : xmGroupClusterObjList) {
                //System.debug('AddMissingDevicesToList --> looping through the list');
                for (XMDeviceWrapper device : newDeviceList) {
                    boolean skip = false;
                    for (xmPersonMemberModel xmModel: xmGroupCluster.Devices) {
//                        System.debug('AddMissingDevicesToList compare xmModel Type--> ' + xmModel );
//                        System.debug('AddMissingDevicesToList compare device Type--> ' + device );
                        if (xmModel.targetName.contains(device.name)) {
                            skip = true;
                            xmModel.checked = true;
                            //System.debug('AddMissingDevicesToList --> record already present');
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
        OR EstimatedGoLiveDate__c <= NEXT_N_DAYS : 14)
        AND Status__c not in('Canceled', 'Deactivated')])
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
                groupData.AccountId = product.Account__c;
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
        System.debug('businessLayer.notificationType =>' + notificationType);
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
	    string productName = groupData.product.contains('/')? groupData.product.replace('/', '-') : groupData.product;
        XmattersGroupName = 'IP_'+ groupData.partnerPrefix + '_' + groupData.product + '_'  + groupData.cluster;
        if(notificationType == 'MaintType')
            XmattersGroupName = XmattersGroupName + '_' + 'MAINT';

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

        List<Contact> contactList = [
                Select Id, AccountId, xmPerson__c, XmattersUid__c from Contact where xmPerson__r.xmPersonUID__c = :userID
        ];

        Set<id> accountIds = new Set<id>();
        for(Contact c: contactList){
            accountIds.add(c.AccountId);
        }

        Set<String> products = new Set<String>();
        for(XMGroupProductCluster p: groupList){
//            if(!p.Product.contains(' - '))
//                p.Product = p.Product.replace('-',' - ');

            products.add(p.Product);
        }

        Map<String, ProductEventMap__c> nodeMap;
        nodeMap = ProductEventMap__c.getAll();

        Map<string, ImplementedProduct__c> implementedProduct = new Map<string, ImplementedProduct__c>();
        for(ImplementedProduct__c impl: [SELECT  Id, Product__c, Account__c, Account__r.inContact_Cluster__c, Account__r.Verint_Cluster__c, Account__r.NICE_WFM_Cluster__c,
                Account__r.NICE_QM_Cluster__c from ImplementedProduct__c where Product__c in: products and Account__c in: accountIds]){

            ProductEventMap__c productMap = nodeMap.get(impl.Product__c);
            if(productMap != null)
            {
                ProductClusterMapClass prodMap = new ProductClusterMapClass(
                        productMap.Name,
                        impl.Account__r.inContact_Cluster__c,
                        impl.Account__r.Verint_Cluster__c,
                        impl.Account__r.NICE_WFM_Cluster__c,
                        impl.Account__r.NICE_QM_Cluster__c,
                        '' ,
                        productMap
                );

                XMGroupProductCluster grpData = GetGroupDataMap(prodMap);
                implementedProduct.put(impl.Product__c + grpData.Cluster, impl);
            }


        }

        List<xmGroupChangeRequest__c> groupChangeRequestList = new List<xmGroupChangeRequest__c>();
        Set<string> grRecorIdList = new Set<String>();
        xmPerson__c xmPerson ;



        try
        {

            for(XMGroupProductCluster groupObj:groupList)
            {

                for(xmPersonMemberModel deviceObj:groupObj.Devices){

                    grRecorIdList.add(deviceObj.grRecordId);

                    if(deviceObj.id != null && deviceObj.id != ''){
//                        if(!groupObj.Product.contains(' - '))
//                            groupObj.Product = groupObj.Product.replace('-',' - ');

                        xmGroupChangeRequest__c grpChangeRequest = new xmGroupChangeRequest__c(
                                Account__c = implementedProduct.get(groupObj.Product + groupObj.Cluster).Account__c,
                                Contact__c = contactList[0].Id,
                                ImplementedProduct__c = implementedProduct.get(groupObj.Product + groupObj.Cluster).Id,
                                NotificationProfile__c = contactList[0].xmPerson__c,
                                xMDeviceId__c = deviceObj.Id,
                                Status__c = 'In Queue',
                                Device_Type__c = deviceObj.targetName.contains('|') ? deviceObj.targetName.split('\\|')[1] : deviceObj.targetName
                        );

                        if(notificationType == 'MaintType')
                            grpChangeRequest.Maintenance__c = true;

                        if (deviceObj.checked == true) {
                            grpChangeRequest.Action__c = 'Add';
                        }
                        else
                                grpChangeRequest.Action__c = 'Remove';

                        groupChangeRequestList.add(grpChangeRequest);
                    }
                }

            }

            if(grRecorIdList.size() > 0){
                List<xmGroupChangeRequest__c> delGroupChangeRequests = [SELECT Id from xmGroupChangeRequest__c where Id in: grRecorIdList and Status__c = 'In Queue'];
                delete  delGroupChangeRequests;

            }

            if(groupChangeRequestList.size() >0){
                insert groupChangeRequestList;
            }
        }
        catch(XMCalloutException xmCalloutException)
        {
            throw xmCalloutException;
        }

        catch(Exception ex)
        {

            XMCalloutException xmCalloutException = new XMCalloutException(ex.getMessage());
            system.debug ('***  xmCalloutException.Message ==> ' + xmCalloutException.Message);
            xmCalloutException.Message = ex.getMessage();

            throw xmCalloutException;
        }

        successMessage = 'User has been successfully added to the selected groups.';
        if(successMessage != '' && successMessage != null)
            return successMessage;
        else
                return 'There are some issues in adding user to the selected group, please try again or call administrator.';
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