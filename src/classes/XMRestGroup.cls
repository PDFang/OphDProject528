public with sharing class XMRestGroup {

    private final String GroupUrl = 'groups/';
    private final String GroupURLWithSearch = 'groups?search = ';


    //***  need to determine the reponse object and replace the void responses ***

    public List<XMGroupModel> GetAllGroupsByPrefix(string prefix) {

        XMRestWrapper wrapper = new XMRestWrapper();
        string jsonList;
        if (prefix.length() > 0){
            jsonList = wrapper.performCallOut(this.GroupURLWithSearch + prefix, 'GET', null);
        }
        else{
            jsonList = wrapper.performCallOut(this.GroupUrl + prefix, 'GET', null);
        }
        List<XMGroupModel> groupList = new List<XMGroupModel>();
        JSONParser parser = JSON.createParser(jsonList);
        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                while (parser.nextToken() != null) {
                    if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                        XMGroupModel model = (XMGroupModel) parser.readValueAs(XMGroupModel.class);
                        //groupList.Add((XMGroupModel) parser.readValueAs(XMGroupModel.class));
                        groupList.Add((model));
                        system.debug(model);
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
    //need to add support for devices -- so type of subscription
    public List<XMGroupModel> GetXMPersonGroupsById (string personId){
        XMRestWrapper wrapper = new XMRestWrapper();
        string jsonList;

        string url = 'people/' + personId + '/group-memberships';
        system.debug ( 'url --> ' + url);

        jsonList = wrapper.performCallOut(url, 'GET', null);

        List<XMGroupModel> groupList = new List<XMGroupModel>();
        JSONParser parser = JSON.createParser(jsonList);
        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                while (parser.nextToken() != null) {
                    if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                        XMGroupModel model = (XMGroupModel) parser.readValueAs(XMGroupModel.class);
                        groupList.Add(model);
                        system.debug(model);
                    }
                }
            }
        }
        system.debug('GetAllGroups(): groupList - ' + groupList);
        return groupList;
    }
    //remove person from a group
    public void RemoveUserFromAGroup(string groupName, string PersonId){
        string url;
        string jsonResponse;
        XMRestWrapper wrapper = new XMRestWrapper();
        //body = '{"id": "'+ PersonId +'", "recipientType": "PERSON"}';
        url = this.GroupUrl +  groupName +  '/members/' + PersonId;
        jsonResponse = wrapper.performCallOut(url, 'DELETE', '');
        System.Debug(jsonResponse);
    }
    //need to modify this to support devices and shifts -- this method needs to be heavily modified see adding user to shifts
    //remove hardcoded person type
    public void AddUserToGroup(string groupName, string PersonId, string type){
       string body;
       string url;
       string jsonResponse;
       XMRestWrapper wrapper = new XMRestWrapper();
       body = '{"id": "'+ PersonId +'", "recipientType":"' + type +'"}';
        System.Debug('body = ' + body);
       url = this.GroupUrl + groupName +  '/members';
       System.Debug('url = ' + url);
       jsonResponse = wrapper.performCallOut(url, 'POST', body);
       System.Debug(jsonResponse);
    }
    //delete a group
    public void DeleteAGroup(string groupName){
        string url;
        string jsonResponse;
        XMRestWrapper wrapper = new XMRestWrapper();
        //body = '{"id": "'+ PersonId +'", "recipientType": "PERSON"}';
        url = this.GroupUrl + 'groups/' + groupName;
        jsonResponse = wrapper.performCallOut(url, 'DELETE', '');
        System.Debug(jsonResponse);
    }

 }


