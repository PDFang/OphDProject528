trigger xMattersNewIncident on BMCServiceDesk__Incident__c (after insert) {
// Get the configuration stuff
    Map<String, String> configMap = xMattersRESTHelper.getConfigMap();
        if (configMap.get( 'xMhostname') == null) {
        System.debug( 'xMatters Endpoints are not confiigured. Exiting...' );
        return;
    }
    
    System.debug( 'Current user: |' + UserInfo.getUserId() + '| Owner: |' + Trigger.new[0].OwnerId + '|' );
       
    // Check status
    // notifiableStatuses
    Set<String> notifiableStatuses = new Set<String>();
    String s = configMap.get('notifiableStatuses');
    
    if( s != null )
        notifiableStatuses.addAll( s.split(';') );
    
    // Check priorities
    // notifiablePriorities
    Set<String> notifiablePriorities = new Set<String>();
    s = configMap.get( 'notifiablePriorities' );
    if( s != null )
        notifiablePriorities.addAll( s.split(';') );
    
    System.debug( 'By ID: new: |' + Trigger.new[0].BMCServiceDesk__Priority_ID__c + '|' );
    System.debug( 'By FK: new: |' + Trigger.new[0].BMCServiceDesk__FKPriority__c + '|' );
    
    // Get the ownerName and Type to figure out if we are
    // notifying a user or a group and update the endpoint
    // accordingly
    Map<String, String> temp = xMattersRESTHelper.getOwnerNameAndType( Trigger.new[0].OwnerID );
    String ownerName = temp.get( 'Owner Name' );
    String ownerType = temp.get( 'Owner Type' );
    
    String triggerRule = null;
    if( ownerType == 'Group' )
        triggerRule = 'Assigned to Group';
    else
        triggerRule = 'Assigned to User';
    
    // When the user changes the value, they change the FKPriority__c field, and
    // then a trigger gets the display value and stores it in Priority_ID__c. 
    // That trigger must run after this one, so we go get it ourselves so we
    // can compare with the notifiablePriorities list. 
    List<BMCServiceDesk__Priority__c> p = [ SELECT Name, Id FROM BMCServiceDesk__Priority__c
                                           WHERE Id = :( Trigger.new[0].BMCServiceDesk__FKPriority__c ) LIMIT 1 ];
    if( p.isEmpty() ) {
        System.debug( 'Priority with Id |' + Trigger.new[0].BMCServiceDesk__FKPriority__c + '| not found!' );
        return;
    }
    System.debug( 'Current Priority Display Value: |' +  p[0].Name + '|' );
    
    
    System.debug( 'TriggerRule: |' + triggerRule + '|' );
    System.debug( '|' + Trigger.new[0].BMCServiceDesk__Status_ID__c + '| is in |' + notifiableStatuses + '|? ' + notifiableStatuses.contains( Trigger.new[0].BMCServiceDesk__Status_ID__c ) );
    System.debug( '|' + p[0].Name + '| is in |' + notifiablePriorities + '|? ' + notifiablePriorities.contains( p[0].Name ) );
    
    if( notifiablePriorities.contains( p[0].Name ) &&
        notifiableStatuses.contains( Trigger.new[0].BMCServiceDesk__Status_ID__c ) &&
        UserInfo.getUserId() != Trigger.new[0].OwnerId &&
        triggerRule != null ) {
           
           String recipient = ownerName;
           
           String endpoint = '';
           if( ownerType == 'Group' )
               endpoint = configMap.get( 'groupEndpoint' );     
           if( ownerType == 'User' )
               endpoint = configMap.get( 'individualEndpoint' );
           
           Map<String,String> additionalProperties = new Map<String,String>();
           additionalProperties.put( 'Trigger Rule', triggerRule );
           additionalProperties.put( 'xmatters_url', endpoint.substringBefore( '/reapi/' ) );
           additionalProperties.put( 'annotate_delivery', configMap.get('enableDeliveryUpdates') );
           additionalProperties.put( 'Incident #', Trigger.new[0].Name );
           additionalProperties.put( 'ID', Trigger.new[0].Id );
           
           // String payload  = xMattersRESTHelper.generatePayload( properties, recipient, configMap );
           String payload = xMattersRESTHelper.generatePayloadWrapper( Trigger.new[0], recipient, configMap, additionalProperties );
           System.debug( 'Payload: ' + payload );
           
           // This is an asynchronous call, so we can't capture the eventID here. 
           xMattersRESTHelper.makeRESTCall( endpoint, configMap.get('xMusername'), configMap.get('xMpassword'), payload, 'POST' );
           
           // Now add the Note
           String message = 'Incident notifications requested from xMatters On-Demand.';
           Note n = new note();
           n.parentId = Trigger.new[0].Id;
           n.title = message;    
           n.body = message + ' Recipient: "' + recipient + '"';
           n.isPrivate = true; 
           insert n;
       }
}