/**
 * Created by william.nelson on 5/9/2017.
 */

public with sharing class XMPersonGroupModel {
        public string id { get; set; }
        public string targetName { get; set; }
        public xmGroupLinkModel links { get; set; }
}