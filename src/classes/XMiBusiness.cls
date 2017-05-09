public interface XMiBusiness {
    List<XMGroupProductCluster> GetGroupListByUserid(string guid);
    boolean SetGroupListForUser(string guid, List<XMGroupProductCluster> grouplist);
}