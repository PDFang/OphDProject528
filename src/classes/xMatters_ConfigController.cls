public class xMatters_ConfigController {
    
    // These are used to hold what the user has selected
    public List<String> leftSelected  { get; set; }
    public List<String> rightSelected { get; set; }
    
    // These are the actual fields available to select
    Set<String> leftFields  = new Set<String>();
    Set<String> rightFields = new Set<String>();
    
    // This is where we'll store the info.
    private final xMatters_Config__c xMConfig;
    
    // Constructor class called when the VF page is first displayed?
    public xMatters_ConfigController(ApexPages.StandardController controller) {
        this.xMConfig = (xMatters_Config__c) controller.getRecord();
        
        leftSelected = new List<String>();
        rightSelected = new List<String>();
        
        leftFields.addAll( getFieldsFromIncident() );
        
        // Check if xMConfig.Payload_Fields__c is populated
        // If so, populate leftFields and rightFields accordingly
        // We're storing the actual field name in the values of the Map,
        // so we have to do sort of a reverse lookup to get the label.
        // It might be easier to store the labels in this field, but too late
        if( xMConfig.Payload_Fields__c != null ) {
            String s = xMConfig.Payload_Fields__c;
            
            Set<String> payloadFields = new Set<String>();
            payloadFields.addAll( s.split( ';' ) );
            
            Set<String> allFields = getFieldsFromIncident();
            
            // loop through map and if we find a match, add the key to rightFields 
            // and remove from leftFields
            for( String i : allFields ) {
               if( payloadFields.contains( i ) )  {
                 rightFields.add( i );
                 leftFields.remove( i );
               }
            }
        }
        
    }
    
    // They clicked the 'selectclick' action >
    public PageReference selectclick(){
        rightSelected.clear();
        for( String s : leftSelected ){
            leftFields.remove( s );
            rightFields.add( s );
        }
        return null;
    }
    
    // They clicked the 'unselectclick' action <
    public PageReference unselectclick(){
        leftSelected.clear();
        for(String s : rightSelected){
            rightFields.remove( s );
            leftFields.add( s );
        }
        return null;
    }
    
    
    // Called directly from the VF page
    // These are the "right" side
    public List<SelectOption> getSelectedFields() {
        
       List<SelectOption> options = new List<SelectOption>();
        List<string> tempList = new List<String>();
        tempList.addAll( rightFields );
        tempList.sort();
        for(string s : tempList)
            options.add(new SelectOption(s,s));
        return options;
    }

    
    
    // This builds the list of available fields from the Incident sObject
    // It is referenced in the Visualforce page as "{!availableFields}"
    // and some magic happens that says 'get'AvailableFields which calls
    // this function to retrieve the available values. 
    public List<SelectOption> getAvailableFields() {
        
       List<SelectOption> options = new List<SelectOption>();
        List<string> tempList = new List<String>();
        tempList.addAll( leftFields );
        tempList.sort();
        for(string s : tempList)
            options.add(new SelectOption(s,s));
        return options;
    }

    
    
    public Set<String> getFieldsFromIncident() {
        
        String fieldLabel, fieldName;
        Schema.DisplayType fieldType;
        
        Set<String> temp = new Set<String>();
        
        // Getting the list of fieldName, fieldLabel, fieldType
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map<String, Schema.SObjectField> fieldMap = schemaMap.get( 'bmcservicedesk__incident__c' ).getDescribe().fields.getMap();
        for( Schema.SObjectField sfield : fieldMap.Values() )
        {
            schema.describeFieldResult dfield = sfield.getDescribe();
            fieldLabel = dfield.getLabel();
            fieldType  = dfield.getType();
            fieldName  = dfield.getName();
            // System.debug( fieldName + '...' + fieldLabel + '...' + fieldType );
            
            if( !fieldLabel.contains( '~' ) && !fieldLabel.contains( '+' ) )
              temp.add(  fieldLabel );
        }
        
        temp.remove( '<BLANK>' );
        return temp;
        
    } 
    
    public void save(){
        
        //System.debug( 'About to save.... rightFields: ' + rightFields );
        String s = '';
        for( String item : rightFields )
            s += item + ';';
        
        xMConfig.Payload_Fields__c = s;
        upsert xMConfig;
    }

}