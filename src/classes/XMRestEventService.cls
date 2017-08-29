public class XMRestEventService {
    private XMRestWrapper restWrapper;
    private Map<String, ProductEventMap__c> nodeMap;
    private List<Case_to_xMatters_Field_Mapping__mdt> caseToXMattersFieldMappings;

    static string xmDatetimeDefaultPattern = 'EEEE, MMMM dd, yyyy HH:mm:ss';

    public XMRestEventService(){
        restWrapper = new XMRestWrapper(); //TODO: Allow injection? Not sure yet
        this.nodeMap = ProductEventMap__c.getAll();
        this.caseToXMattersFieldMappings = [select Salesforce_Case_Field__c, xMatters_Form_Field__c, Maintenance__c, Event__c  from Case_to_xMatters_Field_Mapping__mdt];
    }

    /*
     *  Creates an external event in xMatters
     *  Takes a list of clusters, a product and the salesforceCaseId (The unique Id)
     *  Returns back the xMatters processed guid id.  (Use-d for tracking purposes only)
     */
    public String startExternalEventProcessing(XMNotification__c xmNotificationRecord){

        system.debug('startExternalEventProcessing() ===> xmNotificationRecord - ' + xmNotificationRecord);

        Case eventCase = getCaseFromxmNotification(xmNotificationRecord);
        system.debug('startExternalEventProcessing() ===> eventCase - ' + eventCase);

        Map<ID,Schema.RecordTypeInfo> recordTypeMapById = Schema.SObjectType.Case.getRecordTypeInfosByID();

        String caseRecordType = recordTypeMapById.get(eventCase.RecordTypeId).getName();
        Boolean isMaintenance = (caseRecordType == 'Maintenance Notification');

        XMEventData xmEventData = new XMEventData();

        AppConfiguration__c config = AppConfiguration__c.getInstance();

        xmEventData.startEvent = config == null ? true: config.Debug_xMatters_Event_Request__c == false;


        String inboundIntegrationGuid;
        String platformsAffected;

        if(xmNotificationRecord.Request_Type__c == 'Event Platforms Add'){
            platformsAffected = xmNotificationRecord.AddedPlatforms__c;
            inboundIntegrationGuid = (config != null) ? config.XM_Add_Platform_Inbound_GUID__c : null;
        } else if (xmNotificationRecord.Request_Type__c == 'Maintenance Notification'
                || xmNotificationRecord.Request_Type__c == 'Event Initial Confirmation'
                || xmNotificationRecord.Request_Type__c == 'Event Resolved' ){
            platformsAffected = eventCase.PlatformsImpacted__c;
            inboundIntegrationGuid = (config != null) ? config.XM_Event_Notification_Inbound_GUID__c : null;
        }

        if(String.isBlank(inboundIntegrationGuid))
        {
            throw new CalloutException('Inbound Integration GUID not found for Request Type \'' + xmNotificationRecord.Request_Type__c + '\'');
        }

        system.debug('startExternalEventProcessing() ===> inboundIntegrationGuid - ' + inboundIntegrationGuid);

        xmeventData.platformGroups = convertProductAndPlatformToGroupName(platformsAffected, eventCase.ProductImpacted__c, isMaintenance);

        // Build the specific event details needed to process the event.
        XMEventData.EventGroupInfo eventGroupInfo = new XMEventData.EventGroupInfo();

        // PartnerPrefix is a place holder to be replaced by the inbound integration
        eventGroupInfo.eventName = ('Event_' + eventCase.CaseNumber + '_{PartnerPrefix}').replace(' ', '');
        eventGroupInfo.salesforceCaseId = eventCase.Id;
        eventGroupInfo.partnerList = getSupportedPartners();
        eventGroupInfo.xmNotificationId = xmNotificationRecord.Id;
        eventGroupInfo.emergencyMaintenance = (isMaintenance && eventCase.EmergencyMaintenance__c);
        xmEventData.eventGroupInfo = eventGroupInfo;

        //get the picklist API Name to pass as the eventType
        Schema.DescribeFieldResult fieldResult = XMNotification__c.Request_Type__c.getDescribe();
        List<Schema.PicklistEntry> values = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry picklistValue : values) {
            if(picklistValue.getLabel() == xmNotificationRecord.Request_Type__c) {
                eventGroupInfo.eventType = picklistValue.getValue();
                break;
            }
        }

        // Build the properties needed to fill out the email template in xMatters
        Map<String, String> propertyMap = addAdditionalSalesforceDataToFormProperties(eventCase, isMaintenance);
        propertyMap.put('xmNotificationId', xmNotificationRecord.Id);
        XMEventData.templateProperties = propertyMap;

        // Serialize the event information for processing in xMatters Api
        String eventDetailsJson = JSON.serialize(xmEventData);
        system.debug('startExternalEventProcessing() ===> Created Json Event Data: ' + eventDetailsJson);

        // Call out to xMatters and start the event process
        String response = restWrapper.callConfirmedInboundIntegration(eventDetailsJson, inboundIntegrationGuid);
        system.debug('startExternalEventProcessing() ===> Create Response From xMatters' + response);

        return response;
    }


    /*
     *  Finds the properties on the case that we care about and maps them to a property in xMatters and returns
     *  back that map for serialization
     */
    @TestVisible
    private Map<String,String> addAdditionalSalesforceDataToFormProperties(Case caseRecord, Boolean isMaintenance){

        Map<String, String> propertyMap = new Map<String, String>();

        Map<String, Schema.sObjectField> caseFields = Schema.sObjectType.Case.Fields.getMap();

        AppConfiguration__c config = AppConfiguration__c.getInstance();
        String xmDatetimePattern = (config != null && String.isNotBlank(config.XM_Property_Datetime_Pattern__c) )
                ? config.XM_Property_Datetime_Pattern__c : xmDatetimeDefaultPattern;

        for(Case_to_xMatters_Field_Mapping__mdt caseMapping: caseToXMattersFieldMappings){

            // check if the field belonged to the type
            if( (caseMapping.Event__c && !isMaintenance) || (caseMapping.Maintenance__c && isMaintenance) ) {
                system.debug('addAdditionalSalesforceDataToFormProperties() ==> adding property to mapping: ' + caseMapping);
            } else{
                continue;
            }

            String caseField = caseMapping.Salesforce_Case_Field__c;
            if(String.isBlank(caseField) || !caseFields.containsKey(caseField)){
                continue;
            }

            Schema.DescribeFieldResult fieldResult = caseFields.get(caseField).getDescribe();
            String fieldValue = null;
            // format datetime in UTC
            if(fieldResult.getType() == Schema.DisplayType.DATETIME && caseRecord.get(caseField) != null){
                try{
                    fieldValue = ((DateTime)caseRecord.get(caseField)).formatGmt(xmDatetimePattern) + ' UTC';
                }catch(Exception ex){
                    system.debug('addAdditionalSalesforceDataToFormProperties() ==> field value: ' + fieldValue);
                    fieldValue = ((DateTime)caseRecord.get(caseField)).formatGmt(xmDatetimeDefaultPattern) + ' UTC';
                }

            } else if(fieldResult.getType() == Schema.DisplayType.DATE && caseRecord.get(caseField) != null){
                fieldValue = DateTime.newInstance((Date)caseRecord.get(caseField), Time.newInstance(0,0,0,0)).formatGmt('MM/dd/yyyy');
            }else{
                fieldValue = (String)caseRecord.get(caseField);
            }

            system.debug('addAdditionalSalesforceDataToFormProperties() ==> form field: ' + caseMapping.xMatters_Form_Field__c);
            system.debug('addAdditionalSalesforceDataToFormProperties() ==> field value: ' + fieldValue);

            propertyMap.put(caseMapping.xMatters_Form_Field__c, fieldValue);
        }

        return propertyMap;
    }

    /*
     *  Performs a dynamic soql query to lookup a case and get the fields we care about
     */
    private Case getCaseFromxmNotification(XMNotification__c xmNotification){

        Set<String> caseFields = new Set<String>{'PlatformsImpacted__c' ,'Id', 'RecordTypeId', 'EmergencyMaintenance__c'}; // Add default fields that we care about
        system.debug('getCaseFromxmNotification() ===> CaseFields that we care about: ' + caseFields);

        // Loop through the fields in custom data meta data to add fields we care about
        for(Case_to_xMatters_Field_Mapping__mdt caseField : this.caseToXMattersFieldMappings){
            caseFields.add(caseField.Salesforce_Case_Field__c);
        }

        List<String> fieldList = new List<String>(caseFields);
        system.debug('getCaseFromxmNotification() ===> fieldList: ' + fieldList);

        // Dynamic soql query to get the case object
        String dynamicCaseQuery = 'SELECT ' + String.join(fieldList, ',') + ' FROM Case Where Id = \'' + xmNotification.Case__c + '\'' ;
        system.debug('getCaseFromxmNotification() ===> Attempting to run SOQL Query to get Case Record: ' + dynamicCaseQuery);


        Case caseRecord = Database.query(dynamicCaseQuery);
        return caseRecord;
    }

    /*
     * Converts the product and platform to a group name that we can add to the event
     * Example: IP_INC_Dialer_C13
     */
    private String[] convertProductAndPlatformToGroupName(string platforms, string product, boolean isMaintenance){
        String[] groupArray = new List<string>();
        system.debug('convertProductAndPlatformToGroupName() ==> Platforms: ' + platforms + ' Product: ' + product);

        // Get the product map for the specific product in question
        ProductEventMap__c productMap = nodeMap.get(product);

        // If we didn't find the product we will need to notify someone
        if(productMap == null){
            system.debug('convertProductAndPlatformToGroupName() ==> product map is null, this will cause a few problems');
            throw new ProductEventMapException('The product:' + product + ' does not exist in the product event map');
        }

        for(String platform : platforms.split(';')) {

            String productClusterGroupName;
            String cluster;

            // If this is a product with a cluster we can just use the platform from platform imapcted otherwise we use None
            if (productMap.HasClusters__c) {
                cluster = platform;
            } else {
                cluster = 'NONE';
            }

            String groupString = ('IP_{PartnerPrefix}_' + product + '_' + cluster).replace(' ', '').replace('/','-');

            if(isMaintenance){
                groupString += '_MAINT';
            }
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