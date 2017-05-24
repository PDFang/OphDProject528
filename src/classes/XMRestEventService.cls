public class XMRestEventService {

    private XMRestWrapper restWrapper;
    private final String XmattersInBoundIntegrationUrl = 'integration/1/functions/1066c0f9-d182-4b60-97be-e5fa60eb651f/triggers';

    public XMRestEventService(){
        restWrapper = new XMRestWrapper(); //TODO: Allow injection? Not sure yet
    }

    /*
     *  Creates an external event in xMatters
     *  Takes a list of clusters, a product and the salesforceCaseId (The unique Id)
     *  Returns back the xMatters processed guid id.  (Used for tracking purposes only)
     */
    public String startExternalEventProcessing(String salesforceCaseId, string productImpacted, List<string> clusterList){

        XMEventData xmEventData = new XMEventData();
        xmeventData.platformGroups = new String[]{'Test1', 'Test2'};
        xmEventData.startEvent = false;

        // 1. Convert product and clusters to group names
        // 2. Build up object for Serialization
        // 3. Call into the xMatters Rest Wrapper

        // Build the specific event details needed to process the event. TODO: should put this in a helper method?
        XMEventData.EventGroupInfo eventGroupInfo = new XMEventData.EventGroupInfo();
        eventGroupInfo.eventName = 'This is a test Event from salesforce';
        eventGroupInfo.salesforceCaseId = '123455677898';
        xmEventData.eventGroupInfo = eventGroupInfo;

        // Build the properties needed to fill out the email template in xMatters TODO: Move to helper method
        XMEventData.TemplateProperties templateProperties = new XMEventData.TemplateProperties();
        templateProperties.caseNumber = '1235';
        xmEventData.templateProperties = templateProperties;

        // Serialize the event information for processing in xMatters Api
        String eventDetailsJson = JSON.serialize(xmEventData);
        system.debug('startExternalEventProcessing() ===> Created Json Event Data: ' + eventDetailsJson);

        // Call out to xMatters and start the event process
        String response = restWrapper.performCallOut(XmattersInBoundIntegrationUrl, 'POST', eventDetailsJson);
        system.debug('startExternalEventProcessing() ===> Create Response From xMatters' + response);

        return 'Something';
    }

    private void convertProductAndPlatformToGroupName(){
            // TODO: Figure out what I want to return here. Should I do a single group or add all Does this include partner?
    }

    private void addPartnerGroups(){
        // TODO: Figure out what to return for the partner groups and where to get the partner list?
    }
}