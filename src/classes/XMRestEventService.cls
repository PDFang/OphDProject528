public class XMRestEventService {
    private XMRestWrapper restWrapper;
    private Map<String, ProductEventMap__c> nodeMap;
    private List<Case_to_xMatters_Field_Mapping__mdt> caseToXMattersFieldMappings;

    public XMRestEventService(){
        restWrapper = new XMRestWrapper(); //TODO: Allow injection? Not sure yet
        this.nodeMap = ProductEventMap__c.getAll();
        this.caseToXMattersFieldMappings = [select Salesforce_Case_Field__c, xMatters_Form_Field__c  from Case_to_xMatters_Field_Mapping__mdt];
    }

    /*
     *  Creates an external event in xMatters
     *  Takes a list of clusters, a product and the salesforceCaseId (The unique Id)
     *  Returns back the xMatters processed guid id.  (Used for tracking purposes only)
     */
    public String startExternalEventProcessing(XMNotification__c xmNotificationRecord){

        Case eventCase = getCaseFromxmNotification(xmNotificationRecord);

        XMEventData xmEventData = new XMEventData();
        xmeventData.platformGroups = convertProductAndPlatformToGroupName(eventCase.PlatformsImpacted__c, eventCase.ProductImpacted__c);
        xmEventData.startEvent = true;
        xmEventData.eventType = xmNotificationRecord.Request_Type__c;

        // Build the specific event details needed to process the event.
        XMEventData.EventGroupInfo eventGroupInfo = new XMEventData.EventGroupInfo();

        // PartnerPrefix is a place holder to be replaced by the inbound integration
        eventGroupInfo.eventName = 'Event_' + xmNotificationRecord.Request_Type__c + '_' + eventCase.CaseNumber + '_{PartnerPrefix}';
        eventGroupInfo.salesforceCaseId = eventCase.Id;
        eventGroupInfo.partnerList = getSupportedPartners();
        xmEventData.eventGroupInfo = eventGroupInfo;

        // Build the properties needed to fill out the email template in xMatters
        XMEventData.templateProperties = addAdditionalSalesforceDataToFormProperties(eventCase);

        // Serialize the event information for processing in xMatters Api
        String eventDetailsJson = JSON.serialize(xmEventData);
        system.debug('startExternalEventProcessing() ===> Created Json Event Data: ' + eventDetailsJson);

        // Call out to xMatters and start the event process
        String response = restWrapper.callConfirmedInboundIntegration(eventDetailsJson);
        system.debug('startExternalEventProcessing() ===> Create Response From xMatters' + response);

        return response;
    }


    /*
     *  Finds the properties on the case that we care about and maps them to a property in xMatters and returns
     *  back that map for serialization
     */
    @TestVisible
    private Map<String,String> addAdditionalSalesforceDataToFormProperties(Case caseRecord){
        Map<String, String> propertyMap = new Map<String, String>();

        for(Case_to_xMatters_Field_Mapping__mdt caseMapping: caseToXMattersFieldMappings){
            system.debug('addAdditionalSalesforceDataToFormProperties() ==> adding property to mapping: ' + caseMapping);
            propertyMap.put(caseMapping.xMatters_Form_Field__c, (String)caseRecord.get(caseMapping.Salesforce_Case_Field__c));
        }

        return propertyMap;
    }

    /*
     *  Performs a dynamic soql query to lookup a case and get the fields we care about
     */
    private Case getCaseFromxmNotification(XMNotification__c xmNotification){
        String[] caseFields = new List<String>{'PlatformsImpacted__c' ,'Id'}; // Add default fields that we care about

        // Loop through the fields in custom data meta data to add fields we care about
        for(Case_to_xMatters_Field_Mapping__mdt caseField : this.caseToXMattersFieldMappings){
            caseFields.add(caseField.Salesforce_Case_Field__c);
        }

        system.debug('getCaseFromxmNotification() ===> CaseFields that we care about: ' + caseFields);

        // Dynamic soql query to get the case object
        String dynamicCaseQuery = 'SELECT ' + String.join(caseFields, ',') + ' FROM Case Where Id = \'' + xmNotification.Case__c + '\'' ;
        system.debug('getCaseFromxmNotification() ===> Attempting to run SOQL Query to get Case Record: ' + dynamicCaseQuery);


        Case caseRecord = Database.query(dynamicCaseQuery);
        return caseRecord;
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
            system.debug('convertProductAndPlatformToGroupName() ==> product map is null, this will cause a few problems');
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

            String groupString = ('IP_{PartnerPrefix}_' + product + '_' + platform).replace(' ', '');
            groupArray.add(groupString);

            system.debug('convertProductAndPlatformToGroupName() ==> Adding group to list' + groupString);
        }

        return groupArray;
    }

    /*
     * This will look up the XMPartnerPrefix field to determine the full list of partners we support
     */
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