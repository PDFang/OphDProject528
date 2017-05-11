
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


}