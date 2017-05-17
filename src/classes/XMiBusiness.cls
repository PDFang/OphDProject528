public interface XMiBusiness {
    Map<String, XMGroupProductCluster> GetGroupListByUserid(string guid, Account acc);
    boolean SetGroupListForUser(string guid, List<XMGroupProductCluster> grouplist);
}