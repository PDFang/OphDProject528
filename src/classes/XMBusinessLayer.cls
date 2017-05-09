
public with sharing class XMBusinessLayer implements XMiBusiness {

    public List<XMGroupProductCluster> GetGroupListByUserid(string guid){
        XMRestGroup xmRest = new XMRestGroup();
        List<XMGroupMemberModel> xmGrouplist  = xmRest.GetXMPersonGroupsById(guid);
        system.debug(xmGrouplist);


        return null;
    }
    public boolean SetGroupListForUser(string guid, List<XMGroupProductCluster> grouplist){
        throw new CalloutException();
    }

}