/*
 * This class is used to pass Salesforce Case Data over to xMatters to start an xMatters event
 * This should only be used when calling the xMatters inbound integration
 */
public class XMEventData {

    public Boolean startEvent {get;set;}
    public EventGroupInfo eventGroupInfo {get;set;}
    public TemplateProperties templateProperties {get;set;}

    public String[] platformGroups {get;set;}

    // This subclass is used to identify any event related Data that might need to be used in xMatters
    public class EventGroupInfo{
        public String eventName {get;set;}
        public String salesforceCaseId {get;set;}
        public String[] partnerList {get;set;}
    }

    // These are template fields that are used in the xMatters form
    public class TemplateProperties{
        public String caseNumber {get;set;}
    }
}