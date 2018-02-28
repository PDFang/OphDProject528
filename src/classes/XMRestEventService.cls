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
        Boolean isMaintenance = (caseRecordType == 'Maintenance Notification' || caseRecordType == 'Maintenance Preview');
        Boolean isMaintenanceForSpecificAccounts = isMaintenance && xmNotificationRecord.Notification_Group__r.xmGroupUID__c != null;

        XMEventData xmEventData = new XMEventData();

        AppConfiguration__c config = AppConfiguration__c.getInstance();

        xmEventData.startEvent = config == null ? true: config.Debug_xMatters_Event_Request__c == false;


        String inboundIntegrationGuid;
        String platformsAffected;
        String xMattersGroupName;

        if(xmNotificationRecord.Request_Type__c == 'Event Platforms Add'){
            platformsAffected = xmNotificationRecord.AddedPlatforms__c;
            inboundIntegrationGuid = (config != null) ? config.XM_Add_Platform_Inbound_GUID__c : null;
        } else if (isMaintenanceForSpecificAccounts) {
            platformsAffected = null;
            inboundIntegrationGuid = (config != null) ? config.XM_Event_Notification_Inbound_GUID__c : null;

            //set a value indicating the xMatters Group for this Maintenance is already created
            xMattersGroupName = xmNotificationRecord.Notification_Group__r.xmGroupUID__c;

            system.debug('xMatters Group for Specific Accounts Maintenance ==> ' + xMattersGroupName);
        } else if (xmNotificationRecord.Request_Type__c == 'Maintenance Notification'
                || xmNotificationRecord.Request_Type__c == 'Event Initial Confirmation'
                || xmNotificationRecord.Request_Type__c == 'Event Resolved'
                || xmNotificationRecord.Request_Type__c == 'Maintenance Preview'){
            platformsAffected = eventCase.PlatformsImpacted__c;
            inboundIntegrationGuid = (config != null) ? config.XM_Event_Notification_Inbound_GUID__c : null;
        }

        if(String.isBlank(inboundIntegrationGuid))
        {
            throw new CalloutException('Inbound Integration GUID not found for Request Type \'' + xmNotificationRecord.Request_Type__c + '\'');
        }

        system.debug('startExternalEventProcessing() ===> inboundIntegrationGuid - ' + inboundIntegrationGuid);

        if(!isMaintenanceForSpecificAccounts) {
            xmeventData.platformGroups = convertProductAndPlatformToGroupName(platformsAffected, eventCase.ProductImpacted__c, isMaintenance);
        }

        // add internal distribution as default group
        string MaintenanceNotificationsInternalDistribution = (config != null) ? config.XM_Maintenance_Notifications_Internal__c : null;
        string EventNotificationsInternalDistribution = (config != null) ? config.XM_Event_Notifications_Internal__c : null;
        string defaultGroup = (caseRecordType == 'Maintenance Notification') ? MaintenanceNotificationsInternalDistribution : EventNotificationsInternalDistribution;
        if (xmeventData.platformGroups == null)
        {
            xmeventData.platformGroups = new List<string>();
        }
        if (defaultGroup != null)
        {
            xmeventData.platformGroups.add(defaultGroup);
        }

        // Build the specific event details needed to process the event.
        XMEventData.EventGroupInfo eventGroupInfo = new XMEventData.EventGroupInfo();

        // PartnerPrefix is a place holder to be replaced by the inbound integration
        eventGroupInfo.eventName = ('Event_' + eventCase.CaseNumber + '_{PartnerPrefix}').replace(' ', '');
        eventGroupInfo.salesforceCaseId = eventCase.Id;

        eventGroupInfo.xmNotificationId = xmNotificationRecord.Id;
        eventGroupInfo.xmGroupName = xMattersGroupName;
        xmEventData.eventGroupInfo = eventGroupInfo;


        if(isMaintenanceForSpecificAccounts) {
            //maintenance events for selected accounts will currently only support 1 partner 'INC'
            //this will be improved in a future story
            eventGroupInfo.partnerDetails = new List<XMEventData.PartnerInfo>();
            XMEventData.PartnerInfo info = new XMEventData.PartnerInfo();
            info.partnerPrefix = 'INC';
            info.xmFormId = null;
            eventGroupInfo.partnerDetails.add(info);
        }
        else {
            eventGroupInfo.partnerDetails = getSupportedPartners();
        }

        // xMatters form ID
        if(isMaintenance){
            List<xMatters_Forms__mdt> mdtList = [
                    Select Form_Name__c, Form_ID__c, (Select Partner_Prefix__c, Form_ID__c from xMatters_Form_Partner_Versions__r) from xMatters_Forms__mdt where Form_Name__c = :xmNotificationRecord.xMatters_Form__c
            ];
            if(mdtList.isEmpty()){
                throw new CalloutException('Form \'' + xmNotificationRecord.xMatters_Form__c + '\' not found.');
            }

            List<xMatters_Form_Partner_Versions__mdt> partnerVersions = mdtList[0].getSObjects('xMatters_Form_Partner_Versions__r');
            if(partnerVersions == null){
                partnerVersions = new List<xMatters_Form_Partner_Versions__mdt>();
            }
            xMatters_Forms__mdt formsDetail = mdtList[0];
            //set the form ids for each partner
            for(XMEventData.PartnerInfo info : eventGroupInfo.partnerDetails) {
                for(xMatters_Form_Partner_Versions__mdt partnerVersion : partnerVersions){
                    if(info.partnerPrefix == partnerVersion.Partner_Prefix__c){
                        info.xmFormId = partnerVersion.Form_ID__c;
                    }
                }
                info.xmFormId = String.isBlank(info.xmFormId) ? mdtList[0].Form_ID__c : info.xmFormId;
            }
        }

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
        if((xmNotificationRecord.Request_Type__c == 'Event Platforms Add' || xmNotificationRecord.Request_Type__c == 'Event Initial Confirmation')
                && eventCase.CaseComments.size() > 0){
            String lastComment = eventCase.CaseComments[0].CommentBody;
            propertyMap.put('comment', lastComment);
        }
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

        String caseCommentQuery = ', (select CommentBody from CaseComments where IsPublished = true order by createddate desc limit 1) ';
        // Dynamic soql query to get the case object
        String dynamicCaseQuery = 'SELECT ' + String.join(fieldList, ',') + caseCommentQuery
                + ' FROM Case Where Id = \'' + xmNotification.Case__c + '\'' ;
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

        if(productMap == null) {
            for(ProductEventMap__c mapping : nodeMap.values()) {
                if(mapping.Product__c == product) {
                    productMap = mapping;
                    break;
                }
            }
        }

        product = productMap.ImplementedProduct__c;

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
    private static List<XMEventData.PartnerInfo> getSupportedPartners(){
        List<XMEventData.PartnerInfo> partnerArray = new List<XMEventData.PartnerInfo>();

        Schema.DescribeFieldResult fieldResult = Account.XMPartnerPrefix__c.getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();

        for(Schema.PicklistEntry picklistEntry : picklistEntries){
            XMEventData.PartnerInfo info = new XMEventData.PartnerInfo();

            info.partnerPrefix = picklistEntry.getLabel();

            //this is set to null because it will be used at some future time for Events
            //it is currently used only for Maintenance notifications
            info.xmFormId = null;

            partnerArray.add(info);
        }

        return partnerArray;
    }
}