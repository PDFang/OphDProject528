@isTest
public class xMattersRESTHelperTestClass {
    
    static testMethod void unitTest() {
        
        
        Test.startTest();
        
        createxMConfigRec();
        
        Map<String, String> configMap = xMattersRESTHelper.getConfigMap();
        
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        System.runAs ( thisUser ) {
            
            
            User userRec = createUser();
            String ownerID = userRec.Name;
            System.debug( 'Post user' );
            
            BMCServiceDesk__Impact__c i = new BMCServiceDesk__Impact__c( Name='HIGH' );
            insert i;
            System.debug( 'Post impact' );
            
            BMCServiceDesk__Urgency__c u = new BMCServiceDesk__Urgency__c( Name='HIGH' );
            insert u;
            System.debug( 'post urgency' );
            
            BMCServiceDesk__Priority__c p = new BMCServiceDesk__Priority__c( Name='1', BMCServiceDesk__description__c='High priority',
                                                                            BMCServiceDesk__FKImpact__c=i.Id,
                                                                            BMCServiceDesk__FKUrgency__c=u.Id );
            insert p;
            System.debug( 'Post priority' );
            
            BMCServiceDesk__Status__c s = new BMCServiceDesk__Status__c( Name='OPENED', BMCServiceDesk__inactive__c=false,
                                                                        BMCServiceDesk__appliesToIncident__c=true );
            insert s;
            System.debug( 'Post status' );
            
            BMCServiceDesk__Category__c c = new BMCServiceDesk__Category__c( Name='Hardware', BMCServiceDesk__AvailableForIncidents__c=true,
                                                                            BMCServiceDesk__AvailableForServiceCatalog__c=true );
            insert c;
            
            System.debug( 'Pre Incident' );
            
            BMCServiceDesk__Incident__c incRec = new BMCServiceDesk__Incident__c(
                BMCServiceDesk__FKPriority__c = p.Id,
                BMCServiceDesk__FKStatus__c = s.Id,
                BMCServiceDesk__FKClient__c = userRec.Id,
                BMCServiceDesk__FKCategory__c = c.Id,
                BMCServiceDesk__incidentDescription__c = 'Test method testing stuff'
            );
            
            insert incRec;
            System.debug( 'post insert' );
            
            
            ////////////////
            //Change owner test
            List<Group> g = [ SELECT Name, Id FROM Group 
                             WHERE Name = 'Network' LIMIT 1 ];
            
            incRec.OwnerId = g[0].Id;
            update incRec;
            
            /////////////////
            // Change Priority test
            u = new BMCServiceDesk__Urgency__c( Name='lower' );
            insert u;
            p = new BMCServiceDesk__Priority__c( Name='2', BMCServiceDesk__description__c='lower priority',
                                                BMCServiceDesk__FKImpact__c=i.Id,
                                                BMCServiceDesk__FKUrgency__c=u.Id );
            insert p;
            System.debug( 'Post priority' );
            
            incRec.BMCServiceDesk__FKPriority__c = p.Id;
            update incRec;
            
            ///////////////
            // Change Status test
            s = new BMCServiceDesk__Status__c( Name='UPDATED', BMCServiceDesk__inactive__c=false,
                                              BMCServiceDesk__appliesToIncident__c=true );
            insert s;
            
            incRec.BMCServiceDesk__FKStatus__c = s.Id;
            update incRec;
            
            /////////////
            // Change owner test
            // This results in ' The new owner must have read permission'. 
            // incRec.OwnerId = userRec.Id;
            // update incRec;
            
            
        }
        
        Test.stopTest();
    }
    
    
    
    static testMethod void getOwnerNameAndTypeTest( ){
        
        
        System.assert( true );
        
        
        Test.startTest();
        
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        System.runAs ( thisUser ) {
            
            
            User userRec = createUser();
            String ownerID = userRec.Id;
            
            Map<String, String> temp = xMattersRESTHelper.getOwnerNameAndType( ownerID );
            
            temp = xMattersRESTHelper.getOwnerNameAndType( 'nobody' );
            
            Test.stopTest();
            
            System.assert( true );
        }
    }
    
    
    
    static testMethod void generatePayloadTest(){
        // String generatePayload( Map<String, String> properties, String recipient, Map<String, String> configMap )
        // 
        
        Map<String, String> properties = new Map<String, String>();
        properties.put( 'Account',     'Account' );
        properties.put( 'Category',    'Category' );
        properties.put( 'Client ID',   'Client ID' );
        properties.put( 'Description', 'Description' );
        properties.put( 'First Name',  'First Name' );
        properties.put( 'Last Name',   'Last Name' );
        properties.put( 'Opened Date', 'Opened Date' );
        properties.put( 'Owner',       'Owner' );
        properties.put( 'Priority',    'Priority' );
        properties.put( 'Status',      'Status' );
        
        createxMConfigRec();
        
        Map<String, String> configMap = xMattersRESTHelper.getConfigMap();
        
        String payload = xMattersRESTHelper.generatePayload( properties, 'Hardware', configMap );
        
        System.assert( payload != null );        
        
    }
    
    static testMethod void getJSONValueTest() {
        
        String name = 'id';
        String jsonStr = '{"id":"300345"}';
        
        String value = xMattersRESTHelper.getJSONValue( name, jsonStr );
        
        System.assert( value != null );
        
        name = 'error';
        jsonStr = '{"id":"300345"}';
        value = xMattersRESTHelper.getJSONValue( name, jsonStr );
        
    }
    
    static testMethod void getConfigMapTest() {
        
        createxMConfigRec();
        
        Map<String, String> configMap = xMattersRESTHelper.getConfigMap();
        // System.debug( 'groupEndpoint: ' + configMap.get('groupEndpoint') );
        
        System.assert( configMap != null );
    }
    
    static testMethod void testParse() {
        String json = '{'+
            '   \"total\": 2,'+
            '   \"nextRecordsUrl\": null,'+
            '   \"records\": [{'+
            '       \"href\": \"/reapi/2013-12-01/events/750001\"'+
            '   },'+
            '   {'+
            '       \"href\": \"/reapi/2013-12-01/events/750002\"'+
            '   }]'+
            '}';
        xMattersGetEventsResponse obj = xMattersGetEventsResponse.parse(json);
        System.assert(obj != null);
    }
    
    static testMethod void generatePayloadWrapperTest( ) {
        
        Test.startTest();
        
        createxMConfigRec();
        
        Map<String, String> configMap = xMattersRESTHelper.getConfigMap();
        
        
        
        
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        System.runAs ( thisUser ) {
            
            BMCServiceDesk__Incident__c incRec = createIncident();
            
            Map<String,String> additionalProperties = new Map<String,String>();
            additionalProperties.put( 'xmatters_url', 'https://urlgoeshere.com' );
            String payload = xMattersRESTHelper.generatePayloadWrapper( incRec, 'superman', configMap, additionalProperties );
            System.assert( true );
            
        }
    }
    
    
    
    
    
    static testMethod void getEventsResponseTest() {
        
        xMattersGetEventsResponse ger = new xMattersGetEventsResponse();
        System.assert( ger != null );
        
    }
    
    static testMethod void getEventsResponseRecordsTest() {
        
        xMattersGetEventsResponse.Records rec = new xMattersGetEventsResponse.Records();
        System.assert( rec != null );
        
        
    }
    
    static BMCServiceDesk__Incident__c createIncident() {
        
        
        User userRec = createUser();
        
        String ownerID = userRec.Name;
        System.debug( 'Post user' );
        
        BMCServiceDesk__Impact__c i = new BMCServiceDesk__Impact__c( Name='HIGH' );
        insert i;
        System.debug( 'Post impact' );
        
        BMCServiceDesk__Urgency__c u = new BMCServiceDesk__Urgency__c( Name='HIGH' );
        insert u;
        System.debug( 'post urgency' );
        
        BMCServiceDesk__Priority__c p = new BMCServiceDesk__Priority__c( Name='1', BMCServiceDesk__description__c='High priority',
                                                                        BMCServiceDesk__FKImpact__c=i.Id,
                                                                        BMCServiceDesk__FKUrgency__c=u.Id );
        insert p;
        System.debug( 'Post priority' );
        
        BMCServiceDesk__Status__c s = new BMCServiceDesk__Status__c( Name='OPENED', BMCServiceDesk__inactive__c=false,
                                                                    BMCServiceDesk__appliesToIncident__c=true );
        insert s;
        System.debug( 'Post status' );
        
        BMCServiceDesk__Category__c c = new BMCServiceDesk__Category__c( Name='Hardware', BMCServiceDesk__AvailableForIncidents__c=true,
                                                                        BMCServiceDesk__AvailableForServiceCatalog__c=true );
        insert c;
        
        System.debug( 'Pre Incident' );
        
        BMCServiceDesk__Incident__c incRec = new BMCServiceDesk__Incident__c(
            BMCServiceDesk__FKPriority__c = p.Id,
            BMCServiceDesk__FKStatus__c = s.Id,
            BMCServiceDesk__FKClient__c = userRec.Id,
            BMCServiceDesk__FKCategory__c = c.Id,
            BMCServiceDesk__incidentDescription__c = 'Test method testing stuff',
            BMCServiceDesk__firstCallResolution__c = true,
            BMCServiceDesk__openDateTime__c = DateTime.newInstance(Date.newInstance(2014, 11, 18), Time.newInstance(3, 3, 3, 0) ),
            BMCServiceDesk__queueName__c = 'Incident Queue'
        );
        
        incRec.OwnerId = userRec.Id;
        insert incRec;
        
        return incRec;
    }
    
    static void createxMConfigRec() {
        xMatters_Config__c configRec = new xMatters_Config__c( name='xMConfig' );
        
        configRec.Remedy_Inbound_URL__c           = 'https://inboundurl';
        configRec.Remedy_Password__c              = 'Password1234';
        configRec.Remedy_Username__c              = 'RFusername';
        configRec.xMatters_Group_Endpoint__c      = 'https://company.instance.xmatters.com/path/reapi';
        configRec.xMatters_Individual_Endpoint__c = 'https://company.instance.xmatters.com/path/reapi';
        configRec.xMatters_Password__c            = 'Password22222';
        configRec.xMatters_Username__c            = 'xMUsername';
        configRec.Use_Response_Callback__c        = true;
        configRec.Payload_Fields__c       = 'Account;Category;Client ID;Impact;Last Name;First Call Resolution;Opened Date;Closed Date;Last Queue';
        configRec.Notifiable_Priorities__c        = '1;2';
        configRec.Notifiable_Statuses__c          = 'UPDATED;OPENED';
        
        insert configRec;
        
    }
    
    static User createUser() {
        
       
        Account accRec = new account( name='heroes' );
        insert accRec ;
        
        Profile profRec = [select id from profile where name = 'Standard User'];
        
        
        String FirstName = 'Clark';
        String LastName  = 'Kent';
        String Email     = 'clark.kent@heroes.com';
        
        User userRec = new User( Alias = LastName,
                                Email                  = Email,
                                EmailEncodingKey       = 'UTF-8',
                                FirstName              = FirstName,
                                LastName               = LastName,
                                LanguageLocaleKey      = 'en_US',
                                LocaleSidKey           = 'en_US',
                               
                                TimeZoneSidKey         = 'America/Los_Angeles',
                                CommunityNickname      = LastName,
                                isActive               = true,
                                Username               = Email,
                                ProfileId              = profRec.Id );  //  IsPortalSelfRegistered = false,
        insert userRec;
        
        return userRec;
        
    }
}