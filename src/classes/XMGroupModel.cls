public with sharing class XMGroupModel {
        public string id { get; set; }
        public string targetName { get; set; }
        public string recipientType {get;set;}
        public string status {get;set;}
        public boolean externallyOwned {get;set;}
        public boolean allowDuplicates {get;set;}
        public boolean useDefaultDevices {get;set;}
        public boolean observedByAll {get;set;}
        public string description {get;set;}
}

