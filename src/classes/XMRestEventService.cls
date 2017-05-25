public class XMRestEventService {
    private XMRestWrapper restWrapper;

    public XMRestEventService(){
        restWrapper = new XMRestWrapper(); //TODO: Allow injection? Not sure yet
    }

    /*
     *  Creates an external event in xMatters
     *  Takes a list of clusters, a product and the salesforceCaseId (The unique Id)
     *  Returns back the xMatters processed guid id.  (Used for tracking purposes only)
     */
    public String startExternalEventProcessing(Case eventCase){

        XMEventData xmEventData = new XMEventData();
        xmeventData.platformGroups = convertProductAndPlatformToGroupName(eventCase.PlatformsImpacted__c, eventCase.ProductImpacted__c);
        xmEventData.startEvent = false;

        // Build the specific event details needed to process the event.
        XMEventData.EventGroupInfo eventGroupInfo = new XMEventData.EventGroupInfo();
        eventGroupInfo.eventName = 'This is a test Event from salesforce';
        eventGroupInfo.salesforceCaseId = eventCase.Id;
        eventGroupInfo.partnerList = getSupportedPartners();
        xmEventData.eventGroupInfo = eventGroupInfo;

        // Build the properties needed to fill out the email template in xMatters
        XMEventData.TemplateProperties templateProperties = new XMEventData.TemplateProperties();
        templateProperties.caseNumber = eventCase.CaseNumber;
        xmEventData.templateProperties = templateProperties;

        // Serialize the event information for processing in xMatters Api
        String eventDetailsJson = JSON.serialize(xmEventData);
        system.debug('startExternalEventProcessing() ===> Created Json Event Data: ' + eventDetailsJson);

        // Call out to xMatters and start the event process
        String response = restWrapper.callConfirmedInboundIntegration(eventDetailsJson);
        system.debug('startExternalEventProcessing() ===> Create Response From xMatters' + response);

        return response;
    }

    private String[] convertProductAndPlatformToGroupName(string platforms, string product){
        String[] groupArray = new List<string>();

        // TODO: There was mention of having "None" for the platform, figure out that use case
        for(String platform : platforms.split(';')){
            groupArray.add('IP_INC_' + product + '_' + platform);
    }

        return groupArray;
    }

    // This will look up the XMPartnerPrefix field to determine the full list of partners we support
    private String[] getSupportedPartners(){
        String [] partnerArray = new List<String>();

        Schema.DescribeFieldResult fieldResult = Account.XMPartnerPrefix__c.getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();

        for(Schema.PicklistEntry picklistEntry : picklistEntries){
            partnerArray.add(picklistEntry.getLabel());
        }

        return partnerArray;
    }
}