public class xMattersRESTHelper {

    
    /**
* Makes the REST call to xMatters
* @param endpoint - the Web Service url to send the request
* @param xMusername - REST user with permissions on the endpoint
* @param xMpassword - REST user password
* @param payload - JSON payload as a string. 
*/ 
    // @future indicates we are allowing the call to happen asynchronously
    // Otherwise, we get a "Callout from triggers are currently not supported"
    @future (callout=true)
    public static void makeRESTCall( String endpoint, String xMusername, String xMpassword, String payload, String method ) {
        
        if( method == null )
            method = 'POST';
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint( endpoint );
        req.setMethod( method );
        
        
        Blob headerValue = Blob.valueOf( xMusername + ':' + xMpassword );
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode( headerValue );
        req.setHeader('Authorization', authorizationHeader);
        
        if( payload != null ) {
            req.setBody( payload );
            req.setHeader( 'Content-Type', 'application/json' );
        }
        // Create a new http object to send the request object
        // A response object is generated as a result of the request  
        
        Http http = new Http();
        if(!Test.isRunningTest())
        {
            // Add some retry/error checking?
            HTTPResponse res = http.send( req );
            System.debug( res.getBody() );
        }
        
        // return res.getBody();
        // 
        
    }
    /**
* Terminate all ACTIVE events for this Incident
* @host - The hostname with protocol (https)
* @user - Username to authenticate
* @pass - Password
* @incNumber - Incident Number to terminate events for
* 
*/
    @future (callout=true)
    public static void terminateEvents( String host, String user, String pass, String incNumber ){
        String endpoint = host + '/reapi/2013-12-01/events?';
        // endpoint += 'status=ACTIVE&properties=Incident%20Number%23en%3D' + incNumber;
        endpoint += 'status=ACTIVE&properties=' + EncodingUtil.urlEncode( 'incident ##en=' + incNumber + '', 'UTF-8' );
            
        System.debug( 'Terminate endpoint: |' + endpoint + '|' );
        
        // Prepare to get the list of ACTIVE event IDs
        HttpRequest req = new HttpRequest();
        req.setEndpoint( endpoint );
        req.setMethod( 'GET' );
        
        Blob headerValue = Blob.valueOf( user + ':' + pass );
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode( headerValue );
        req.setHeader('Authorization', authorizationHeader);
        
        // Send off the request and parse the JSON
        Http http = new Http();
        if(!Test.isRunningTest())
        {
            HTTPResponse respJSON = http.send( req );
            System.debug( 'GET events response: ' + respJSON.getBody() );
                
            xMattersGetEventsResponse obj = xMattersGetEventsResponse.parse( respJSON.getBody() );        
            if( obj == null || obj.records == null ) {
                System.debug( 'Failed parsing response: ' + respJSON.getBody() );
                return;
            }
        
        
        // Prepare to PUT the termination
        HttpRequest req2 = new HttpRequest();
        req2.setMethod( 'PUT' );
        req2.setBody( '{"status":"terminated"}' );
        req2.setHeader('Authorization', authorizationHeader);
        req2.setHeader( 'Content-Type', 'application/json' );
        
        String endpoint2 = null;
        Http http2 = null;
        for( xMattersGetEventsResponse.Records r : obj.records ){
            endpoint2 = host + r.href;
            
            req2.setEndpoint( endpoint2 );
            http2 = new Http();
         
                HTTPResponse res2 = http.send( req2 );
                
                
                //putResponse = makeRESTCall( endpoint2, user, pass, payload2, method2 );
                System.debug( 'PUT response: ' + res2.getBody() );
       
        }
        
        
        }        
    }
    
/*
* This wrapper gets the values from the record passed in. This way, we can still keep the generatePayload
* record agnostic. 
*/
    public static String generatePayloadWrapper( BMCServiceDesk__Incident__c incRec, String recipient, Map<String,String> configMap, Map<String,String> additionalProperties ) {
        Map<String, String> properties = new Map<String, String>();

        String items = configMap.get( 'payloadFields' );
       // System.debug( 'payloadwrapper: items: ' + items );
        
        if( items != null  ){
            Set<Schema.describeFieldResult> names = getFieldNamesfromLabels( items.split(';') );
            // System.debug( 'payloadwrapper: names: ' + names );
            
            // We loop through each name and pass the label and value
            // to the properties map which will be used to build the 
            // payload
            for( Schema.describeFieldResult dfield : names  ) {
                properties.put( dfield.getLabel(), getValue( incRec, dfield ) );
            }
        }
        
        // This is for adding any additional items that will be needed
        // ex 'Trigger Rule' and 'xmatters_url'
        for( String k : additionalProperties.keySet() ) {
            properties.put( k, additionalProperties.get( k ) );
        }
        
        return generatePayload(  properties, recipient, configMap );
    }
    
    /**
* Translates the Java Map into a JSON payload and adds the recipient, priority and callbacks
* @param properties - a Java Map<String, String> of field names and field values. 
* @param recipient - the target of the notificaiton (group or user)
*/  
    public static String generatePayload( Map<String, String> properties, String recipient, Map<String, String> configMap ) {
        
        
        boolean emitResponse = false;
        boolean emitDeliveryStatus = false;
        boolean emitEventStatus = false;
        
        String p = properties.get( 'Priority' );
        // Accepted values: LOW, MEDIUM, HIGH
        String event_priority = (p != null && p == '1' ? 'high' : 'medium');
        String val;
        
        // Build payload
        // Reference for Generator: 
        // https://www.salesforce.com/us/developer/docs/apexcode/Content/apex_class_System_JsonGenerator.htm#apex_class_System_JsonGenerator
        
        JSONGenerator gen = JSON.createGenerator(true); // true indicates to make it 'pretty'
        gen.writeStartObject();
        // Write properties
        gen.writeFieldName('properties');  gen.writeStartObject();
        for( String key : properties.keySet() ) {
            val = properties.get( key );
            if( val != null )
                gen.writeStringField( key, val );  
        }
        gen.writeEndObject();
        
        // Add recipients
        gen.writeFieldName('recipients'); gen.writeStartArray(); gen.writeStartObject();
        gen.writeStringField( 'targetName', recipient );
        gen.writeEndObject(); gen.writeEndArray();
        
        // Add priority
        gen.writeStringField( 'priority', event_priority );
        
        // Add conferences (not enabled out of the box)
        /*
gen.writeFieldName('conferences'); gen.writeStartArray(); gen.writeStartObject();
gen.writeStringField( 'name', 'conference name here' );
gen.writeEndObject(); gen.writeEndArray();
*/
        
        // Add callbacks
        // This was built out before the inbound endpoint. So keeping here
        // for phase 2
        gen.writeFieldName('callbacks'); gen.writeStartArray(); 
        // if responses
/*
        if( false && configMap.get('emitResponse') == 'true' ) {
            gen.writeStartObject();
            gen.writeStringField( 'url', configMap.get( 'inboundUrl' ) );
            gen.writeStringField( 'type', 'response' );
            gen.writeStringField( 'authType', 'basic' );
            gen.writeStringField( 'authUserName', configMap.get( 'rfusername' ) );
            gen.writeStringField( 'authPassword', configMap.get( 'rfpassword' ) );
            gen.writeEndObject();
        }
        
        // if event status updates
        if( emitEventStatus ) {
            gen.writeStartObject();
            gen.writeStringField( 'url', configMap.get( 'inboundUrl' ) );
            gen.writeStringField( 'type', 'status' );
            gen.writeStringField( 'authType', 'basic' );
            gen.writeStringField( 'authUserName', configMap.get( 'rfusername' ) );
            gen.writeStringField( 'authPassword', configMap.get( 'rfpassword' ) );
            gen.writeEndObject();
        }
        // if delivery updates
        if( emitDeliveryStatus ) {
            
            gen.writeStartObject();
            gen.writeStringField( 'url', configMap.get( 'inboundUrl' ) );
            gen.writeStringField( 'type', 'deliveryStatus' );
            gen.writeStringField( 'authType', 'basic' );
            gen.writeStringField( 'authUserName', configMap.get( 'rfusername' ) );
            gen.writeStringField( 'authPassword', configMap.get( 'rfpassword' ) );
            gen.writeEndObject();
        }
*/
        gen.writeEndArray();
        
        // Close payload
        gen.writeEndObject();
        
        return gen.getAsString();
        
    }
    
/**
* Get the xMatters config items. We make one query and pass this around 
*   as we need it in different places
* returns Map of config fields.  
*/
    public static Map<String, String> getConfigMap( ){
        String configName = 'xMConfig';
        List<xMatters_Config__c> config = [ SELECT Payload_Fields__c,
                                           xMatters_Group_Endpoint__c,
                                           xMatters_Individual_Endpoint__c,
                                           xMatters_Hostname__c,                                            
                                           xMatters_Password__c, 
                                           xMatters_Username__c,
                                           Use_Response_Callback__c,
                                           Notifiable_Priorities__c,
                                           Notifiable_Statuses__c
                                           FROM xMatters_Config__c 
                                           WHERE Name = :( configName )
                                           LIMIT 1 ];
        
        
        Map<String, String> configMap = null;
        
        
        if (!config.isEmpty()) {
            configMap = new Map<String, String>();
            
            
            // Inbound items
            // configMap.put( 'inboundUrl', (config[0].Remedy_Inbound_URL__c != null ? config[0].Remedy_Inbound_URL__c : '' ) ); 
            // configMap.put( 'rfusername', (config[0].Remedy_Username__c != null    ? config[0].Remedy_Username__c    : '' ) );
            // configMap.put( 'rfpassword', (config[0].Remedy_Password__c != null    ? config[0].Remedy_Password__c    : '' ) ); 
            // 
            // Outbound items
            //configMap.put( 'xMhostname',         (config[0].xMatters_Hostname__c != null ? config[0].xMatters_Hostname__c : '' ));
            //Fix for xM ticket 111054
            //if (config[0].xMatters_Group_Endpoint__c != null)
            //    configMap.put( 'xMhostname', config[0].xMatters_Group_Endpoint__c.substring(0, config[0].xMatters_Group_Endpoint__c.indexOf('/reapi')));
            //else
            //    configMap.put( 'xMhostname', config[0].xMatters_Individual_Endpoint__c.substring(0, config[0].xMatters_Individual_Endpoint__c.indexOf('/reapi')));
            if (config[0].xMatters_Group_Endpoint__c != null && config[0].xMatters_Group_Endpoint__c.indexOf('/reapi') > 0)
                configMap.put( 'xMhostname', config[0].xMatters_Group_Endpoint__c.substring(0, config[0].xMatters_Group_Endpoint__c.indexOf('/reapi')));
            else if (config[0].xMatters_Individual_Endpoint__c!= null && config[0].xMatters_Individual_Endpoint__c.indexOf('/reapi') > 0)
                configMap.put( 'xMhostname', config[0].xMatters_Individual_Endpoint__c.substring(0, config[0].xMatters_Individual_Endpoint__c.indexOf('/reapi')));
            configMap.put( 'groupEndpoint',      (config[0].xMatters_Group_Endpoint__c != null ? config[0].xMatters_Group_Endpoint__c : '' ));
            configMap.put( 'individualEndpoint', (config[0].xMatters_Individual_Endpoint__c != null ? config[0].xMatters_Individual_Endpoint__c : '' ));
            configMap.put( 'xMusername',         (config[0].xMatters_Username__c != null            ? config[0].xMatters_Username__c            : '' ) );
            configMap.put( 'xMpassword',         (config[0].xMatters_Password__c != null            ? config[0].xMatters_Password__c            : '' ) ); 
            
            configMap.put( 'payloadFields',        (config[0].Payload_Fields__c != null        ? config[0].Payload_Fields__c        : '' ) );
            configMap.put( 'notifiableStatuses',   (config[0].Notifiable_Statuses__c != null   ? config[0].Notifiable_Statuses__c   : '' ) );
            configMap.put( 'notifiablePriorities', (config[0].Notifiable_Priorities__c != null ? config[0].Notifiable_Priorities__c : '' ) );
            
            // Callback settings
            configMap.put( 'emitResponse', (config[0].Use_Response_Callback__c + '') );
            //configMap.put( 'emitDeliveryStatus', config[0] );
            // configMap.put( 'emitEventStatus', config[0] );
            
            
            
        }
        
        return configMap;
    }
    
/**
* Extracts a JSON value from a JSON formatted string. Can be used
* to get the EventID from a response. 
* name - the name of the json value to extract
* jsonStr - the json string to extract from
*/
    public static String getJSONValue( String name, String jsonStr ) {
        JSONParser parser = JSON.createParser( jsonStr );
        
        while( parser.nextToken() != null ) {
            if ( parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() == name ) {
                parser.nextToken();
                return parser.getText();
            }
        }
        return null;
    }
/**
* Returns the human readable name of the owner. It will query and determine
*   if the owner is a user or a queue. 
* 
*/
    public static Map<String, String> getOwnerNameAndType( String ownerID ) {
        Map<String, String> temp = new Map<String, String>();
        
        List<User> ownerRecU = new List<User>();
        ownerRecU = [ SELECT Name, Username FROM User WHERE Id=:ownerID ];
        if( !ownerRecU.isEmpty() ) {
            temp.put( 'Owner Name', ownerRecU[0].Username );
            temp.put( 'Owner Type', 'User' );
            return temp;
        }
        
        List<Group> ownerRecG = new List<Group>();
        ownerRecG = [ SELECT Name, Type FROM Group WHERE Id=:ownerID ];
        if( !ownerRecG.isEmpty() ){
            temp.put( 'Owner Name', ownerRecG[0].Name );
            temp.put( 'Owner Type', 'Group' );
            return temp;
        }
        
        return temp;   
    }
    
/**
* The xMConfig record will store the Field Labels, but we have to reference them by Field Name
* to get the value. So this turns a list of field labels into a list of field objects, which 
* we can then extract the name and type from. 
* 
*/
    public static Set<Schema.describeFieldResult> getFieldNamesfromLabels( List<String> tempList ) {
        String fieldLabel, fieldName;
        Schema.DisplayType fieldType;
        Set<String> labelList = new Set<String>();
        labelList.addAll( tempList );
        
        Set<Schema.describeFieldResult> relevantFields = new Set<Schema.describeFieldResult>();
        
        // Getting the list of fieldName, fieldLabel, fieldType
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map<String, Schema.SObjectField> fieldMap = schemaMap.get( 'bmcservicedesk__incident__c' ).getDescribe().fields.getMap();
        for( Schema.SObjectField sfield : fieldMap.Values() )
        {
            // We don't use these variables, but might be good for debugging?
            Schema.describeFieldResult dfield = sfield.getDescribe();
            fieldLabel = dfield.getLabel();
            fieldType  = dfield.getType();
            fieldName  = dfield.getName();
            // System.debug( fieldName + '|' + fieldLabel + '|' + fieldType );
            
            if( labelList.contains( fieldLabel ) ) {
                relevantFields.add( dfield );
            }
        }
        return relevantFields;
    }
    
/**
* This gets the value of the named field from the record passed in
* 
*/
/*    public static String getValue( BMCServiceDesk__Incident__c rec, Schema.describeFieldResult dfield ) {
        
        System.debug( 'getValue Val: |' + rec.get( dfield.getName() ) + '|' );
        
        // Make sure the value isn't null
        if( rec.get( dfield.getName() ) == null )
            return '';
        
        // Now deal with reference fields (priority, status, etc)
        if( dfield.getType() == Schema.DisplayType.REFERENCE ) {
            String recId = (String)rec.get( dfield.getName() );
            String qry = 'SELECT Id, Name FROM ' + dfield.getReferenceTo()[0] + ' WHERE Id = :recId';
            
            System.debug( 'getValue qry: ' + qry );
            
            //System.debug( 'qry: ' + qry );
            List<sObject> refRec = Database.query( qry );
            return (refRec.isEmpty() ? '' : (String)refRec[0].get( 'Name' ) );
        }
        
        
        if( dfield.getType() == Schema.DisplayType.DATETIME ){
            Datetime d = (Datetime)rec.get( dfield.getName() );
            return d.format();
        }
        
        if( dfield.getType() == Schema.DisplayType.BOOLEAN ||
            dfield.getType() == Schema.DisplayType.DOUBLE  ||
            dfield.getType() == Schema.DisplayType.INTEGER ) {
                
            return ('' + rec.get( dfield.getName() ) );
        }
        
        return (String)rec.get( dfield.getName() );
    }
    
}*/

public static String getValue( BMCServiceDesk__Incident__c rec, Schema.describeFieldResult dfield ) {
        
        System.debug( 'getValue Val: |' + rec.get( dfield.getName() ) + '|' );
        
        // Make sure the value isn't null
        if( rec.get( dfield.getName() ) == null )
            return '';
        
        // Now deal with reference fields (priority, status, etc)
        if( dfield.getType() == Schema.DisplayType.REFERENCE ) {
            String recId = (String)rec.get( dfield.getName() );
            String sObjectType = String.valueOf( dfield.getReferenceTo()[0] );
            if( Schema.getGlobalDescribe().get( sObjectType ).getDescribe().fields.getMap().containsKey( 'name' ) ) {
                String qry = 'SELECT Id, Name FROM ' + dfield.getReferenceTo()[0] + ' WHERE Id = :recId';
                
                System.debug( 'getValue qry: ' + qry );
                
                //System.debug( 'qry: ' + qry );
                List<sObject> refRec = Database.query( qry );
                return (refRec.isEmpty() ? '' : (String)refRec[0].get( 'Name' ) );
            } else {
                return recId;
            }
        }
        
        if( dfield.getType() == Schema.DisplayType.DATETIME ){
            Datetime d = (Datetime)rec.get( dfield.getName() );
            return d.format();
        }
        
        if( dfield.getType() == Schema.DisplayType.BOOLEAN ||
            dfield.getType() == Schema.DisplayType.DOUBLE  ||
            dfield.getType() == Schema.DisplayType.INTEGER ) {
                
            return ('' + rec.get( dfield.getName() ) );
        }
        
        return (String)rec.get( dfield.getName() );
    }
}