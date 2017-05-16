public interface XMiBusiness {
    List<XMGroupProductCluster> GetGroupListByUserid(string guid, Account acc);
    boolean SetGroupListForUser(string guid, List<XMGroupProductCluster> grouplist);
}