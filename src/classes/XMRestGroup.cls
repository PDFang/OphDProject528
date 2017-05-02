public with sharing class XMRestGroup {

    private final String GroupUrl = 'groups/';

    public List<XMGroupModel> GetAllGroups() {

        XMRestWrapper wrapper = new XMRestWrapper();
        string jsonList = wrapper.performCallOut(this.GroupUrl, 'GET', null);

        List<XMGroupModel> groupList = new List<XMGroupModel>();

        JSONParser parser = JSON.createParser(jsonList);
        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                while (parser.nextToken() != null) {
                    if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                        groupList.Add((XMGroupModel) parser.readValueAs(XMGroupModel.class));
                        system.debug('GetAllGroups(): groupList - ' + groupList);
                    }

                }
            }
        }

        return groupList;
    }
}