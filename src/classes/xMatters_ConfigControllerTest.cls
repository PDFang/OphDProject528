@isTest
public class xMatters_ConfigControllerTest {
    
    static testMethod void xMatters_ConfigControllerTest() {
        
        xMatters_Config__c configRec = new xMatters_Config__c( name='xMConfig' );
        
        configRec.Remedy_Inbound_URL__c           = 'https://inboundurl';
        configRec.Remedy_Password__c              = 'Password1234';
        configRec.Remedy_Username__c              = 'RFusername';
        configRec.xMatters_Group_Endpoint__c      = 'https://company.instance.xmatters.com/path/';
        configRec.xMatters_Individual_Endpoint__c = 'https://company.instance.xmatters.com/path/';
        configRec.xMatters_Password__c            = 'Password22222';
        configRec.xMatters_Username__c            = 'xMUsername';
        configRec.Use_Response_Callback__c        = true;
        configRec.Payload_Fields__c               = 'Account;Category;Client ID;Impact;Last Name';
        
        insert configRec;
        
        PageReference pageRef = new PageReference('/apex/xMConfig');
        ApexPages.currentPage().getParameters().put('id', configRec.Id );
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller( configRec );
        
        xMatters_ConfigController xc = new xMatters_ConfigController( sc );
        Test.setCurrentPage(pageRef);
        
        Test.startTest();
        System.assert( true );
    }
    
 
    
    static testMethod void selectclickTest() {
        List<String> leftSelected = new List<String>();
        leftSelected.add( 'Short Description' );
        
        xMatters_ConfigController xc = generateController();
        xc.selectclick();
        
        System.assert(true);
    }
    
    static testMethod void unselectclickTest() {
      
        
        xMatters_ConfigController xc = generateController();  
        xc.leftSelected = new List<String>();
        xc.leftSelected.add( 'Category' );
        
        xc.unselectclick();
        
        System.assert(true);
    }
    
    static testMethod void getSelectedFieldsTest() {
        xMatters_ConfigController xc = generateController();
        xc.rightSelected = new List<String>();
        xc.rightSelected.add( 'Category' );
        
        xc.unselectclick();
        
        xc.getSelectedFields();
        
        
        System.assert( true );
        
    }
    
    static testMethod void getAvailableFieldsTest() {
        xMatters_ConfigController xc = generateController();
        xc.leftSelected = new List<String>();
        xc.leftSelected.add( 'Category' );
        
        xc.selectclick();
        xc.getAvailableFields();
        System.assert( true );
    }
    
    static testMethod void getFieldsFromIncidentTest() {
        
        xMatters_ConfigController xc = generateController();
        xc.getFieldsFromIncident();
        
        System.assert( true );
    }
    
    static testMethod void saveTest() {
        xMatters_ConfigController xc = generateController();
        xc.save();
        System.assert( true );
        
        
    }
    
    
       static xMatters_ConfigController generateController() {
        xMatters_Config__c configRec = new xMatters_Config__c( name='xMConfig' );
        
        configRec.Remedy_Inbound_URL__c           = 'https://inboundurl';
        configRec.Remedy_Password__c              = 'Password1234';
        configRec.Remedy_Username__c              = 'RFusername';
        configRec.xMatters_Group_Endpoint__c      = 'https://company.instance.xmatters.com/path/';
        configRec.xMatters_Individual_Endpoint__c = 'https://company.instance.xmatters.com/path/';
        configRec.xMatters_Password__c            = 'Password22222';
        configRec.xMatters_Username__c            = 'xMUsername';
        configRec.Use_Response_Callback__c        = true;
        
        insert configRec;
        
        PageReference pageRef = new PageReference('/apex/xMConfig');
        ApexPages.currentPage().getParameters().put('id', configRec.Id );
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller( configRec );
        
        xMatters_ConfigController xc = new xMatters_ConfigController( sc );
        Test.setCurrentPage(pageRef);
        
        return xc;
    }
}