@RestResource(urlmapping='/UpdateCommunityRoles/*')
global class UpdateCommunityRolesWebService 
{
	@HTTPPOST
    global static void updateRoles(list<ContactRoles> ContactRolesList)
    {
        if(ContactRolesList == null)
            return;
    
    	set<string> contactIds = new set<string>();
        list<CommunityRoles__c> communityRolesLists = new list<CommunityRoles__c>();
        list<CommunityRoles__c> deleteComRoles = new list<CommunityRoles__c>();
        string errorMessage;
        try
        {
             for(ContactRoles conRole : ContactRolesList)
                    {
                        
                        if(conRole.contactId.startsWith('003'))
                        {
                            contactIds.add(conRole.contactId);
                            for(Roles r : conRole.contactRoles)
                            {
                                CommunityRoles__c cr = new CommunityRoles__c();
                                cr.Contact__c = conRole.contactId;
                                cr.RoleType__c = r.roleCategory;
                                cr.Roles__c = '';
                                for(string assignedRole : r.rolesAssigned)
                                {
                                   
                                    cr.Roles__c += assignedRole + ';'; 
                                }
                                
                                communityRolesLists.add(cr);
                                
                            }
                        }
            
                    }
            		
                    
            		deleteComRoles = [select Id from CommunityRoles__c where Contact__c in :contactIds];
            
            		if(deleteComRoles.size() > 0)
                        delete deleteComRoles;
            
            
            
                    Database.SaveResult[] svrLists = database.insert(communityRolesLists, false);                  
                    boolean isError = false;
                    for( Database.SaveResult svr : svrLists)
                    {
                        if(!svr.isSuccess())
                        {
                            isError = true;
                            for(Database.Error err : svr.getErrors()) 
                            {
                                errorMessage +=  '<br/>&nbsp;&nbsp;&nbsp;The following error has occurred - <br/> <b>Status Code:-</b>'
                                                + err.getStatusCode() + ': ' + err.getMessage()
                                                + '<br/>The fields that affected this error: ' + err.getFields() + '</br>';
                                
                                system.debug('error message ==> ' + errorMessage);
                            }
                        }
                    }
                    
                   if(isError) 
                         doSendEmail(errorMessage); 
        }
        catch(Exception ex)
        {
            errorMessage = '';
            errorMessage = '<br/>&nbsp;&nbsp;&nbsp;The following error has occurred - <br/> ' + ex.getMessage() + ' at line number' + ex.getLineNumber();
            doSendEmail(errorMessage); 
        }
        
       
    }
    
    private static void doSendEmail(string emailBody)
    {   
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {'arnab.karsarkar@incontact.com', 'william.nelson@incontact.com', 'swetha.sankaramanchi@incontact.com'};
        mail.setToAddresses(toAddresses);
        mail.setSubject('There is an unexpected error occured');
        mail.setHtmlBody(emailBody);
        
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });	
 	}
    
    
    
   global class ContactRoles 
   {
       public string contactId;
       public list<Roles> contactRoles;
       
       public ContactRoles()
       {
           contactId = '';
           contactRoles = new list<Roles>();
       }
       
   }
    
   public class Roles
   {
       public string roleCategory;
       public list<string> rolesAssigned;
       
       public Roles()
       {
           roleCategory = '';
           rolesAssigned = new list<string>();
       }
       
   }
    

}