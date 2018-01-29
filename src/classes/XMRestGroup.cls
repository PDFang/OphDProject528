public with sharing class XMRestGroup {

    private final String GroupUrl = 'groups/';
    private final String GroupURLWithSearch = 'groups?search=';

    public Integer httpRequestTimeout { get; set; }

    public XMRestGroup() {
        httpRequestTimeout = -1;
    }

    public List<XMGroupModel> GetAllGroupsByPrefix(string prefix) {

        XMRestWrapper wrapper = new XMRestWrapper();

        if(httpRequestTimeout > 0) {
            wrapper.httpRequestTimeout = httpRequestTimeout;
        }

        string jsonList;
        if (prefix.length() > 0){
            String encodedPrefix = EncodingUtil.urlEncode(prefix,'UTF-8');
            jsonList = wrapper.performCallOut(this.GroupURLWithSearch + encodedPrefix, 'GET', null);
        }
        else{
            jsonList = wrapper.performCallOut(this.GroupUrl, 'GET', null);
        }
        system.debug('raw data -> ' + jsonList);
        List<XMGroupModel> groupList = new List<XMGroupModel>();
        JSONParser parser = JSON.createParser(jsonList);
        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                while (parser.nextToken() != null) {
                    if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                        //XMGroupModel model = (XMGroupModel) parser.readValueAs(XMGroupModel.class);
                        groupList.Add((XMGroupModel) parser.readValueAs(XMGroupModel.class));
                        system.debug(grouplist);
                    }
                }
            }
        }
        return groupList;
    }
    public List<XMPersonGroupData> GetMyCustomerGroups(Account acc)
    {
        XMRestGroupHelper helper = new XMRestGroupHelper();
        List<ImplementedProduct__c>  products =  helper.getImplementedProducts(acc);
        //need to get a friendly name for these defaulting to product name
        return null;
    }
    //
    public List<XMGroupMemberModel> GetXMPersonGroupsById (string personId, string type){
        XMRestWrapper wrapper = new XMRestWrapper();

        if(httpRequestTimeout > 0) {
            wrapper.httpRequestTimeout = httpRequestTimeout;
        }

        string jsonList;

        string url = 'people/' + personId + '/group-memberships?offset=0&limit=1000';
        system.debug ( 'url --> ' + url);

        jsonList = wrapper.performCallOut(url, 'GET', null);
        system.debug('PreTestData ->' + jsonList);
        jsonList = jsonList.replace('"group"', '"group1"');
        system.debug('TestData ->' + jsonList);

        List<XMGroupMemberModel> groupList = new List<XMGroupMemberModel>();
        JSONParser parser = JSON.createParser(jsonList);
        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                while (parser.nextToken() != null) {
                    if (parser.getCurrentToken() == JSONToken.START_OBJECT) {

                        XMGroupMemberModel model = (XMGroupMemberModel) parser.readValueAs(XMGroupMemberModel.class);

                        if(model.member != null){
                            model.member.checked = true;
                        }
                        system.debug('model  =>' + model);

                        if(model != null && model.group1 != null){
                            if(type == 'MaintType' && model.group1.targetName.contains('MAINT'))
                                groupList.Add(model);
                            else if(type != 'MaintType' && !model.group1.targetName.contains('MAINT'))
                                groupList.Add(model);
                        }


                        system.debug('groupList' + groupList);

                    }
                }
            }
        }
        system.debug('GetAllGroups(): groupList - ' + groupList);
        return groupList;
    }

    //***  need to determine the reponse object and replace the void responses ***


    //Remove person from a group
    public void RemoveUserFromAGroup(string groupName, string PersonId){
        string url;
        string jsonResponse;
        XMRestWrapper wrapper = new XMRestWrapper();

        if(httpRequestTimeout > 0) {
            wrapper.httpRequestTimeout = httpRequestTimeout;
        }

        //body = '{"id": "'+ PersonId +'", "recipientType": "PERSON"}';
        url = this.GroupUrl +  groupName +  '/members/' + PersonId;
        jsonResponse = wrapper.performCallOut(url, 'DELETE', '');
        System.Debug(jsonResponse);
    }

    //need to modify this to support devices and shifts -- this method needs to be heavily modified see adding user to shifts
    //remove hardcoded person type
    //need to change the response from void to some response object.

    public string AddUserToGroup(string groupName, string PersonId, string type){
        string body;
        string url;
        string jsonResponse;
        XMRestWrapper wrapper = new XMRestWrapper();

        if(httpRequestTimeout > 0) {
            wrapper.httpRequestTimeout = httpRequestTimeout;
        }

        body =  '{"position" : 1,"recipient":{"id": "'+ PersonId +'", "recipientType":"' + type +'"}}';
        System.Debug('body = ' + body);
        String encodedgroupName = EncodingUtil.urlEncode(groupName,'UTF-8');
        url = this.GroupUrl + encodedgroupName +  '/shifts/24x7/members';  //always add to the default 24x7 shift for now
        System.Debug('url = ' + url);
        jsonResponse = wrapper.performCallOut(url, 'POST', body);
        System.Debug(jsonResponse);
        return jsonResponse;
    }

    public boolean CreateNewGroup(string groupName){
        string body  = '{"recipientType": "GROUP",  "status": "ACTIVE", "allowDuplicates" : false,"useDefaultDevices" : true,"observedByAll" : true, "description": "inContact Product Cluster Group","targetName": "' + groupName +'"}';
        string url;
        string jsonResponse;
        url = this.GroupUrl;
        System.Debug('body = ' + body);
        System.Debug(url);
        XMRestWrapper wrapper = new XMRestWrapper();

        if(httpRequestTimeout > 0) {
            wrapper.httpRequestTimeout = httpRequestTimeout;
        }

        jsonResponse = wrapper.performCallOut(url, 'POST', body);
        return true;
    }

    public XMGroupModel CreateNewGroupWithResponseDetail(string groupName){
        string body  = '{"recipientType": "GROUP",  "status": "ACTIVE", "allowDuplicates" : false,"useDefaultDevices" : true,"observedByAll" : true, "description": "inContact Product Cluster Group","targetName": "' + groupName +'"}';
        string url;
        string jsonResponse;
        url = this.GroupUrl;
        System.Debug('body = ' + body);
        System.Debug(url);
        XMRestWrapper wrapper = new XMRestWrapper();

        if(httpRequestTimeout > 0) {
            wrapper.httpRequestTimeout = httpRequestTimeout;
        }

        jsonResponse = wrapper.performCallOut(url, 'POST', body);
        XMGroupModel newGroup = null;
        newGroup = (XMGroupModel) JSON.deserialize(jsonResponse, XMGroupModel.class);
        return newGroup;
    }

    public boolean AddShiftToGroup(string groupName, string shiftName) {
        string body = '{ "name": "' + shiftName + '" }';
        string jsonResponse;
        String encodedGroupName = EncodingUtil.urlEncode(groupName,'UTF-8');

        String url = GroupUrl + '/' + encodedGroupName + '/shifts';

        System.debug('body = ' + body);
        System.debug('url = ' + url);

        XMRestWrapper wrapper = new XMRestWrapper();

        if(httpRequestTimeout > 0) {
            wrapper.httpRequestTimeout = httpRequestTimeout;
        }

        jsonResponse = wrapper.performCallOut(url, 'POST', body);

        if(jsonResponse != null) {
            return true;
        }
        else {
            return false;
        }
    }

    //Delete a group
    public boolean DeleteAGroup(string groupName){
        string url;
        string jsonResponse;
        XMRestWrapper wrapper = new XMRestWrapper();

        if(httpRequestTimeout > 0) {
            wrapper.httpRequestTimeout = httpRequestTimeout;
        }

        url = this.GroupUrl +  groupName;
        jsonResponse = wrapper.performCallOut(url, 'DELETE', '');
        System.Debug(jsonResponse);
        return true;
    }



}