public class XMRestEventService {
    private XMRestWrapper restWrapper;
    private Map<String, ProductEventMap__c> nodeMap;

    public XMRestEventService(){
        restWrapper = new XMRestWrapper(); //TODO: Allow injection? Not sure yet
        this.nodeMap = ProductEventMap__c.getAll();
    }

    /*
     *  Creates an external event in xMatters
     *  Takes a list of clusters, a product and the salesforceCaseId (The unique Id)
     *  Returns back the xMatters processed guid id.  (Used for tracking purposes only)
     */
    public String startExternalEventProcessing(Case eventCase){

        XMEventData xmEventData = new XMEventData();
        xmeventData.platformGroups = convertProductAndPlatformToGroupName(eventCase.PlatformsImpacted__c, eventCase.ProductImpacted__c);
        xmEventData.startEvent = true;

        // Build the specific event details needed to process the event.
        XMEventData.EventGroupInfo eventGroupInfo = new XMEventData.EventGroupInfo();

        // PartnerPrefix is a place holder to be replaced by the inbound integration
        eventGroupInfo.eventName = 'Event_' + eventCase.CaseNumber + '_{PartnerPrefix}';
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

    /*
     * Converts the product and platform to a group name that we can add to the event
     * Example: IP_INC_Dialer_C13
     */
    private String[] convertProductAndPlatformToGroupName(string platforms, string product){
        String[] groupArray = new List<string>();
        system.debug('convertProductAndPlatformToGroupName() ==> Platforms: ' + platforms + ' Product: ' + product);

        // Get the product map for the specific product in question
        ProductEventMap__c productMap = nodeMap.get(product);

        // If we didn't find the product we will need to notify someone
        if(productMap == null){
            // TODO: Throw a fit?
        }

        // TODO: Add check for null
        for(String platform : platforms.split(';')){

            String productClusterGroupName;
            String cluster;

            // If this is a product with a cluster we can just use the platform from platform imapcted otherwise we use None
            if(productMap.HasClusters__c){
                cluster = platform;
            } else{
                cluster = 'NONE';
            }

            groupArray.add('IP_{PartnerPrefix}_' + product + '_' + platform);
        }

        return groupArray;
    }


    // This will look up the XMPartnerPrefix field to determine the full list of partners we support
    private static String[] getSupportedPartners(){
        String [] partnerArray = new List<String>();

        Schema.DescribeFieldResult fieldResult = Account.XMPartnerPrefix__c.getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();

        for(Schema.PicklistEntry picklistEntry : picklistEntries){
            partnerArray.add(picklistEntry.getLabel());
        }

        return partnerArray;
    }
}