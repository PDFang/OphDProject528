public with sharing class CaseRedirectExtension {

    
    
    
    private ApexPages.StandardController controller;
    public String retURL {get; set;}
    public String saveNewURL {get; set;}
    public String rType {get; set;}
    public String cancelURL {get; set;}
    public String ent {get; set;}
    public String confirmationToken {get; set;}
    public String accountID {get; set;}
    public String contactID {get; set;}
    public String ccrName {get; set;}
    public String ccrId {get; set;}
    Map<String, String> allParams {get; set;}
    
    public CaseRedirectExtension (ApexPages.StandardController controller) {
    
        this.controller = controller;
    
        retURL = ApexPages.currentPage().getParameters().get('retURL');
        rType = ApexPages.currentPage().getParameters().get('RecordType');
        cancelURL = ApexPages.currentPage().getParameters().get('cancelURL');
        ent = ApexPages.currentPage().getParameters().get('ent');
        confirmationToken = ApexPages.currentPage().getParameters().get('_CONFIRMATIONTOKEN');
        saveNewURL = ApexPages.currentPage().getParameters().get('save_new_url');
        accountID = ApexPages.currentPage().getParameters().get('def_account_id');
        contactID = ApexPages.currentPage().getParameters().get('def_contact_id');
        ccrName = ApexPages.currentPage().getParameters().get('CF00N70000002xwoL');
        ccrId = ApexPages.currentPage().getParameters().get('00N70000002xwoL_lkid');
        
        allParams = ApexPages.currentPage().getParameters();
    
    }
    
    public PageReference redirect() {
    
        PageReference returnURL;
    
        // Redirect if Record Type corresponds to custom VisualForce page
    
        IF(rType == '01270000000LuEp') {
    
            returnURL = new PageReference('/apex/CaseNewIncident');
    
        }
    
        ELSE {
    
            returnURL = new PageReference('/500/e');
    
        }
    /*
        returnURL.getParameters().put('retURL', retURL);
        returnURL.getParameters().put('RecordType', rType);
        returnURL.getParameters().put('cancelURL', cancelURL);
        returnURL.getParameters().put('ent', ent);
        returnURL.getParameters().put('_CONFIRMATIONTOKEN', confirmationToken);
        returnURL.getParameters().put('save_new_url', saveNewURL);
        returnURL.getParameters().put('nooverride', '1');
    
        IF (accountID != null){
    
            returnURL.getParameters().put('def_account_id', accountID);
    
        }
    
        IF (contactID != null){
    
            returnURL.getParameters().put('def_contact_id', contactID);
    
        }
        
        if(ccrId != null)
        {
            returnURL.getParameters().put('CF00N70000002xwoL', ccrName );
            returnURL.getParameters().put('00N70000002xwoL_lkid', ccrId );
            
        }
        */
        
        returnURL.getParameters().putAll(allParams);
        returnURL.getParameters().put('nooverride', '1');
        returnURL.getParameters().remove('save_new');
    
        returnURL.setRedirect(true);
        return returnURL;
    
    }

}