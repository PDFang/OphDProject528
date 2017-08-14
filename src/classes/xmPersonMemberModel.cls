/**
 * Created by william.nelson on 5/9/2017.
 */

public with sharing class xmPersonMemberModel {
    public string id { get; set; }
    public string targetName { get; set; }
    public string recipientType { get; set; }
    public xmGroupLinkModel links { get; set; }
    public boolean checked {get; set;}
    public string grRecordId {get; set;}

}





