public class CCRControlsClass 
{
    private final String ccrType;
    public final CCRControls__c ccrControlRecords;
    public final static Set<String> openStatuses1 = new Set<String>{'APPROVED','DEPLOYED',
		                                                            'OPENED',
		                                                            'PEER REVIEW','ADMINISTRATOR REVIEW','READY FOR DEPLOYMENT',
		                                                            'BOARD REVIEW','ADMINISTRATOR REJECTED','TECHNICAL RISK REVIEW',
		                                                            'ON_HOLD','TECHNICAL RISK REVIEW REJECTED',
		                                                            'CANCELLED','PEER REVIEW REJECTED','CCR FAILED','CLOSED'};
    public final Set<String> openStatuses = new Set<String>{'Open',
                                                            'CCB Master Review',
                                                            'Peer Review',
                                                            'Board Review',
                                                            'On Hold',
                                                            'OPENED',
                                                            'CCB MASTER REVIEW',
                                                            'PEER REVIEW',
                                                            'BOARD REVIEW',
                                                            'ON HOLD',
                                                            'CANCELLED'};
    
    public CCRControlsClass(String ccrTypeName)
    {
        //ccrType parameter should either be "Network" or "IT"
        ccrType = ccrTypeName;
        
        //pull CCRControls__c records
        ccrControlRecords = CCRControls__c.getInstance(ccrType);
    }

    //check if user is ccb master for specified ccr type
    public Boolean IsCCBMasterMember(Id userId)
    {
        integer mast;
        mast = [SELECT COUNT() FROM GroupMember WHERE GroupId = :ccrControlRecords.CCBMastersQueue__c 
        									    and UserOrGroupID = :userId];
                
        if(mast == 0)
        {
            return false;
        }
        else
        {
            return true;
        }
    }
    
    
    //sends task list email to all assignees
    public void SendTaskEmail(ID ccrId, String subject)
    {
        String[] toAddresses = new String[]{};
        Set<String> toEmails = new Set<String>();
        String eBody = '';
        string urlString;
        List<CCRTask__c> ccrTasks = new List<CCRTask__c>();
        ChangeControlRequest__c ccr = new ChangeControlRequest__c();
        
        //get url for ccr link
        urlString = URL.getSalesforceBaseUrl().toExternalForm();    
        urlString = urlString + '/';
        
        //create message
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        
        //get ccr
        ccr = [SELECT Id, Name, Summary__c, ReleaseDate__c, Status__c FROM ChangeControlRequest__c WHERE ID = :ccrId];
        
        
        //determine if cancelled tasks need to be pulled in
        if(ccr.Status__c == 'Cancelled')
        {
            ccrTasks = [SELECT Description__c, Order__c, TaskDateTime__c, Duration__c, RecordType.Name, Status__c, AssignedTo__r.Name, AssignedTo__r.Email FROM CCRTask__c WHERE ChangeControlRequest__c = :ccr.Id ORDER BY Order__c];
        }
        else
        {
            ccrTasks = [SELECT Description__c, Order__c, TaskDateTime__c, Duration__c, RecordType.Name, Status__c, AssignedTo__r.Name, AssignedTo__r.Email FROM CCRTask__c WHERE ChangeControlRequest__c = :ccr.Id AND Status__c <> 'Cancelled' ORDER BY Order__c];
        }
        
        eBody = '<html><head><title></title></head><body><div link="#fa8c00" text="#464646" vlink="#fa8c00" alink="#fa8c00" bgcolor="#464646" ><table width="790" align="center" border="0" cellpadding="0" cellspacing="0" bgcolor="#464646"><tbody><tr><td width="20" bgcolor="#ffffff"><img src="https://service.incontact.com/Images/Email/ffffff_spcr.png" width="20" height="1"></td><td width="750"><table width="750" border="0" cellpadding="0" cellspacing="0" bgcolor="#555d63"><tbody><tr><td bgcolor="#ffffff" height="20"><img src="https://service.incontact.com/Images/Email/ffffff_spcr.png" width="20" height="20"></td></tr><tr><td><table width="750" border="0" cellpadding="0" cellspacing="0"><tbody><tr><td><a href="http://www.incontact.com">';
        
        //different templates for the different ccrs
        eBody = eBody + '<img src="' + ccrControlRecords.EmailHeaderURL__c + '" width="750" border="0" height="181">';
        
        eBody = eBody + '</a></td><td width="216" align="right"></td></tr></tbody></table></td></tr><tr><td width="0" bgcolor="#B0C4DE" height="0"><table width="750" border="0" cellpadding="0" cellspacing="0"><tbody><tr><td width="0"><table width="750" border="0" cellspacing="0"><tbody><tr><td valign="top" width="100" align="center" bgcolor="#B0C4DE"><img src="https://service.incontact.com/Images/Email/dff0f4_spcr.png" width="100" height="1"></td><td valign="top" width="10" align="center" bgcolor="#ffffff"><img src="https://service.incontact.com/Images/Email/dff0f4_spcr.png" width="10" height="1"></td><td valign="top" align="left" bgcolor="ffffff"><img src="https://service.incontact.com/Images/Email/ffffff_spcr.png" width="1" height="20"><br />';
        
        //display ccr info
        eBody = eBody + '<h3><STRONG><FONT face="Arial, Helvetica, sans-serif">' + subject + ' ';
        eBody = eBody + '<a href="' + urlString + ccr.Id + '">' + ccr.Name + '</a>.</FONT></STRONG></h3><br>';
        eBody = eBody + '<table>';
        eBody = eBody + '<tr><td><FONT face="Arial, Helvetica, sans-serif" size=2><b>Summary:</b> </FONT></td><td><FONT face="Arial, Helvetica, sans-serif" size=2>' + ccr.Summary__c + '</FONT></td></tr>';
        eBody = eBody + '<tr><td><FONT face="Arial, Helvetica, sans-serif" size=2><b>Release Date:</b> </FONT></td><td><FONT face="Arial, Helvetica, sans-serif" size=2>' + ccr.ReleaseDate__c.format() + '</FONT></td></tr>';
        eBody = eBody + '<tr><td><FONT face="Arial, Helvetica, sans-serif" size=2><b>Status:</b> </FONT></td><td><FONT face="Arial, Helvetica, sans-serif" size=2>' + ccr.Status__c + '</FONT></td></tr>';
        eBody = eBody + '</table><br>';
        eBody = eBody + '<table cellpadding="2" border="1">';
        eBody = eBody + '<tr><th><FONT face="Arial, Helvetica, sans-serif" size=2>Task Type</FONT></th><th><FONT face="Arial, Helvetica, sans-serif" size=2>Assigned To</FONT></th><th><FONT face="Arial, Helvetica, sans-serif" size=2>Description</FONT></th><th><FONT face="Arial, Helvetica, sans-serif" size=2>Status</FONT></th><th><FONT face="Arial, Helvetica, sans-serif" size=2>Task Date/Time</FONT></th><th><FONT face="Arial, Helvetica, sans-serif" size=2>Duration</FONT></th></tr>';
        
        //display task info
        for(CCRTask__c t: ccrTasks)
        {
            if(!toEmails.contains(t.AssignedTo__r.Email)){toEmails.add(t.AssignedTo__r.Email);}
            
            eBody = eBody + '<tr>';
            eBody = eBody + '<td><FONT face="Arial, Helvetica, sans-serif" size=2>' + t.RecordType.Name + '</FONT></td>';
            eBody = eBody + '<td><FONT face="Arial, Helvetica, sans-serif" size=2>' + t.AssignedTo__r.Name + '</FONT></td>';
            eBody = eBody + '<td><FONT face="Arial, Helvetica, sans-serif" size=2>' + t.Description__c + '</FONT></td>';
            eBody = eBody + '<td><FONT face="Arial, Helvetica, sans-serif" size=2>' + t.Status__c + '</FONT></td>';
            if(t.TaskDateTime__c != null)
            {
                eBody = eBody + '<td><FONT face="Arial, Helvetica, sans-serif" size=2>' + t.TaskDateTime__c.format('MM/dd/yyyy hh:mm a') + '</FONT></td>';
            }
            else
            {
                eBody = eBody + '<td></td>';
            }
            
            if(t.Duration__c != null)
            {
                eBody = eBody + '<td><FONT face="Arial, Helvetica, sans-serif" size=2>' + t.Duration__c + '</FONT></td>';
            }
            else
            {
                eBody = eBody + '<td></td>';
            }  
            eBody = eBody + '</tr>';
        }
        
        eBody = eBody + '</table>';
        eBody = eBody + '<br /><img src="https://service.incontact.com/Images/Email/ffffff_spcr.png" width="1" height="20"><br /></td><td valign="top" width="10" align="center" bgcolor="#ffffff"><img src="https://service.incontact.com/Images/Email/dff0f4_spcr.png" width="10" height="1"></td><td valign="top" width="20" align="center" bgcolor="#B0C4DE"><img src="https://service.incontact.com/Images/Email/dff0f4_spcr.png" width="20" height="1"></td></tr></tbody></table></td></tr></tbody></table></td></tr><tr><td align="center" bgcolor="#4B6789"><table width="750" border="0" cellspacing="0"><tbody><tr><td width="150" align="right"><font size="1" color="#ffffff" face="Verdana, Geneva, sans-serif">&copy; 2012 inContact, Inc. All rights reserved.</font><img src="https://service.incontact.com/Images/Email/555d63_spcr.png" width="20" height="1"></td></tr></tbody></table></td></tr><tr><td width="750" bgcolor="#ffffff" height="20"><img src="https://service.incontact.com/Images/Email/ffffff_spcr.png" width="750" height="20"></td></tr></tbody></table></td><td width="20" bgcolor="#ffffff"><img src="https://service.incontact.com/Images/Email/ffffff_spcr.png" width="20" height="1"></td></tr></tbody></table></div></body></html>';
        
        toAddresses.addAll(toEmails);
        //set email info
        email.setSubject(subject + ' ' + ccr.Name + '.');
        email.setToAddresses(toAddresses);
        email.setHtmlBody(eBody);
        
        //send mail
        if(!ccrTasks.isEmpty())
        {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        }
    }
    
    //sends email for single task changes
    public void SendSingleTaskEmail(ID taskId, String subject)
    {
        String[] toAddresses = new String[]{};
        Set<String> toEmails = new Set<String>();
        String eBody = '';
        string urlString;
        CCRTask__c ccrTask = new CCRTask__c();
        ChangeControlRequest__c ccr = new ChangeControlRequest__c();
        
        //get url for ccr link
        urlString = URL.getSalesforceBaseUrl().toExternalForm();    
        urlString = urlString + '/';
        
        //create message
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        
        //get task and ccr info     
        ccrTask = [SELECT ChangeControlRequest__c, Description__c, Order__c, TaskDateTime__c, Duration__c, RecordType.Name, Status__c, AssignedTo__r.Name, AssignedTo__r.Email FROM CCRTask__c WHERE Id = :taskId ORDER BY Order__c];
        ccr = [SELECT Id, Name, Summary__c, ReleaseDate__c, Status__c FROM ChangeControlRequest__c WHERE ID = :ccrTask.ChangeControlRequest__c];
        
        //get email address
        if(!toEmails.contains(ccrTask.AssignedTo__r.Email)){toEmails.add(ccrTask.AssignedTo__r.Email);}
        
        eBody = '<html><head><title></title></head><body><div link="#fa8c00" text="#464646" vlink="#fa8c00" alink="#fa8c00" bgcolor="#464646" ><table width="790" align="center" border="0" cellpadding="0" cellspacing="0" bgcolor="#464646"><tbody><tr><td width="20" bgcolor="#ffffff"><img src="https://service.incontact.com/Images/Email/ffffff_spcr.png" width="20" height="1"></td><td width="750"><table width="750" border="0" cellpadding="0" cellspacing="0" bgcolor="#555d63"><tbody><tr><td bgcolor="#ffffff" height="20"><img src="https://service.incontact.com/Images/Email/ffffff_spcr.png" width="20" height="20"></td></tr><tr><td><table width="750" border="0" cellpadding="0" cellspacing="0"><tbody><tr><td><a href="http://www.incontact.com">';
        
        //different templates for the different ccrs
        eBody = eBody + '<img src="' + ccrControlRecords.EmailHeaderURL__c + '" width="750" border="0" height="181">';
        
        eBody = eBody + '</a></td><td width="216" align="right"></td></tr></tbody></table></td></tr><tr><td width="0" bgcolor="#B0C4DE" height="0"><table width="750" border="0" cellpadding="0" cellspacing="0"><tbody><tr><td width="0"><table width="750" border="0" cellspacing="0"><tbody><tr><td valign="top" width="100" align="center" bgcolor="#B0C4DE"><img src="https://service.incontact.com/Images/Email/dff0f4_spcr.png" width="100" height="1"></td><td valign="top" width="10" align="center" bgcolor="#ffffff"><img src="https://service.incontact.com/Images/Email/dff0f4_spcr.png" width="10" height="1"></td><td valign="top" align="left" bgcolor="ffffff"><img src="https://service.incontact.com/Images/Email/ffffff_spcr.png" width="1" height="20"><br />';
        
        
        //ccr and task info
        eBody = eBody + '<h3><STRONG><FONT face="Arial, Helvetica, sans-serif">' + subject + ' ';
        eBody = eBody + '<a href="' + urlString + ccr.Id + '">' + ccr.Name + '</a>.</FONT></STRONG></h3><br>';
        eBody = eBody + '<table>';
        eBody = eBody + '<tr><td><FONT face="Arial, Helvetica, sans-serif" size=2><b>Summary:</b> </FONT></td><td><FONT face="Arial, Helvetica, sans-serif" size=2>' + ccr.Summary__c + '</FONT></td></tr>';
        eBody = eBody + '<tr><td><FONT face="Arial, Helvetica, sans-serif" size=2><b>Release Date:</b> </FONT></td><td><FONT face="Arial, Helvetica, sans-serif" size=2>' + ccr.ReleaseDate__c.format() + '</FONT></td></tr>';
        eBody = eBody + '<tr><td><FONT face="Arial, Helvetica, sans-serif" size=2><b>Status:</b> </FONT></td><td><FONT face="Arial, Helvetica, sans-serif" size=2>' + ccr.Status__c + '</FONT></td></tr>';
        eBody = eBody + '</table><br>';
        
        eBody = eBody + '<table cellpadding="2" border="0">';
        eBody = eBody + '<tr><td><FONT face="Arial, Helvetica, sans-serif" size=2><b>Task Type:</b></FONT></td><td><FONT face="Arial, Helvetica, sans-serif" size=2>' + ccrTask.RecordType.Name + '</FONT></td></tr>';
        eBody = eBody + '<tr><td><FONT face="Arial, Helvetica, sans-serif" size=2><b>Assigned To:</b></FONT></td><td><FONT face="Arial, Helvetica, sans-serif" size=2>' + ccrTask.AssignedTo__r.Name + '</FONT></td></tr>';
        eBody = eBody + '<tr><td><FONT face="Arial, Helvetica, sans-serif" size=2><b>Description:</b></FONT></td><td><FONT face="Arial, Helvetica, sans-serif" size=2>' + ccrTask.Description__c + '</FONT></td></tr>';
        eBody = eBody + '<tr><td><FONT face="Arial, Helvetica, sans-serif" size=2><b>Status:</b></FONT></td><td><FONT face="Arial, Helvetica, sans-serif" size=2>' + ccrTask.Status__c + '</FONT></td></tr>';
        eBody = eBody + '<tr><td><FONT face="Arial, Helvetica, sans-serif" size=2><b>Task Date/Time:</b></FONT></td>';
        if(ccrTask.TaskDateTime__c != null)
        {
            eBody = eBody + '<td><FONT face="Arial, Helvetica, sans-serif" size=2>' + ccrTask.TaskDateTime__c.format('MM/dd/yyyy hh:mm a') + '</FONT></td></tr>';
        }
        else
        {
            eBody = eBody + '<td></td></tr>';
        }
        
        eBody = eBody + '<tr><td><FONT face="Arial, Helvetica, sans-serif" size=2><b>Duration:</b></FONT></td>';
        if(ccrTask.Duration__c != null)
        {
            eBody = eBody + '<td><FONT face="Arial, Helvetica, sans-serif" size=2>' + ccrTask.Duration__c + '</FONT></td>';
        }
        else
        {
            eBody = eBody + '<td></td></tr>';
        }   
        
        eBody = eBody + '</table>';
        eBody = eBody + '<br /><img src="https://service.incontact.com/Images/Email/ffffff_spcr.png" width="1" height="20"><br /></td><td valign="top" width="10" align="center" bgcolor="#ffffff"><img src="https://service.incontact.com/Images/Email/dff0f4_spcr.png" width="10" height="1"></td><td valign="top" width="20" align="center" bgcolor="#B0C4DE"><img src="https://service.incontact.com/Images/Email/dff0f4_spcr.png" width="20" height="1"></td></tr></tbody></table></td></tr></tbody></table></td></tr><tr><td align="center" bgcolor="#4B6789"><table width="750" border="0" cellspacing="0"><tbody><tr><td width="150" align="right"><font size="1" color="#ffffff" face="Verdana, Geneva, sans-serif">&copy; 2012 inContact, Inc. All rights reserved.</font><img src="https://service.incontact.com/Images/Email/555d63_spcr.png" width="20" height="1"></td></tr></tbody></table></td></tr><tr><td width="750" bgcolor="#ffffff" height="20"><img src="https://service.incontact.com/Images/Email/ffffff_spcr.png" width="750" height="20"></td></tr></tbody></table></td><td width="20" bgcolor="#ffffff"><img src="https://service.incontact.com/Images/Email/ffffff_spcr.png" width="20" height="1"></td></tr></tbody></table></div></body></html>';
        
        toAddresses.addAll(toEmails);
        //set mail info
        email.setSubject(subject + ' ' + ccr.Name + '.');
        email.setToAddresses(toAddresses);
        email.setHtmlBody(eBody);
        
        //send message
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }
    
    public static map<String,Id> StatusName(){
    	map<String,Id> statusWithId = new map<String,Id>();
        For(BMCServiceDesk__Status__c statusvalue : [Select Id,Name from BMCServiceDesk__Status__c where Name IN:openStatuses1]){
        	statusWithId.put(statusvalue.Name,statusvalue.Id);
        }
        system.debug('statusWithIdconstructor...........'+statusWithId);
        return statusWithId;
        
    }
    
    public static Id ImpactName(String ImpactName){
    	if(ImpactName != null){
    		BMCServiceDesk__Impact__c impactvalue = [Select Id,Name from BMCServiceDesk__Impact__c where Name =:ImpactName];
        	return impactvalue.Id;
    	}
    	else{
    		return null;
    	}
    }
    public static Id urgencyName(String urgencyName){
    	if(urgencyName != null){
    		system.debug('urgencyName&&&&&&&&&&'+urgencyName);
    		BMCServiceDesk__Urgency__c urgencyvalue = [Select Id,Name from BMCServiceDesk__Urgency__c where Name =:urgencyName];
        	return urgencyvalue.Id;
    	}
    	else{
    		return null;
    	}
    }
    
    public static Id ChangeControlRequestId(){
    	ChangeControlRequest__c chngeOld = [Select Id from ChangeControlRequest__c where Summary__c = 'Testing CCRs'];
    	return chngeOld.Id;
    }
    
    public static Id ChangeRequestId(){
    	BMCServiceDesk__Change_Request__c chngeOld = [Select Id from BMCServiceDesk__Change_Request__c where RF_Summary__c = 'Testing CCRs'];
    	return chngeOld.Id;
    }
    
    
    //sends task list email to all assignees
    public void SendTaskEmailForRfChangeRequest(ID ccrId, String subject)
    {
        String[] toAddresses = new String[]{};
        Set<String> toEmails = new Set<String>();
        String eBody = '';
        string urlString;
        List<BMCServiceDesk__Task__c> ccrTasks = new List<BMCServiceDesk__Task__c>();
        BMCServiceDesk__Change_Request__c ccr = new BMCServiceDesk__Change_Request__c();
        
        //get url for ccr link
        urlString = URL.getSalesforceBaseUrl().toExternalForm();    
        urlString = urlString + '/';
        
        //create message
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        
        //get ccr
        ccr = [SELECT Id, Name, RF_Summary__c, RF_Release_Date__c, BMCServiceDesk__FKStatus__c,BMCServiceDesk__FKStatus__r.Name FROM BMCServiceDesk__Change_Request__c WHERE ID = :ccrId];
        
        
        //determine if cancelled tasks need to be pulled in
        if(ccr.BMCServiceDesk__FKStatus__r.Name.EqualsIgnoreCase('Cancelled'))
        {
            ccrTasks = [SELECT BMCServiceDesk__taskDescription__c, BMCServiceDesk__templateOrder__c, BMCServiceDesk__dueDateTime__c, RF_Task_Type__c,
            					BMCServiceDesk__duration__c,BMCServiceDesk__FKStatus__c, BMCServiceDesk__FKStatus__r.Name,BMCServiceDesk__FKOpenBy__r.Name, BMCServiceDesk__FKOpenBy__r.Email 
            			FROM BMCServiceDesk__Task__c 
            			WHERE BMCServiceDesk__FKChange__c = :ccr.Id ORDER BY BMCServiceDesk__templateOrder__c];
        }
        else
        {
            ccrTasks = [SELECT BMCServiceDesk__taskDescription__c, BMCServiceDesk__templateOrder__c, BMCServiceDesk__dueDateTime__c,RF_Task_Type__c, 
            				   BMCServiceDesk__duration__c, BMCServiceDesk__FKStatus__c, BMCServiceDesk__FKStatus__r.Name,BMCServiceDesk__FKOpenBy__r.Name, BMCServiceDesk__FKOpenBy__r.Email
            		    FROM BMCServiceDesk__Task__c 
            		    WHERE BMCServiceDesk__FKChange__c = :ccr.Id AND BMCServiceDesk__FKStatus__r.Name <> 'CANCELLED' ORDER BY BMCServiceDesk__templateOrder__c];
        }
        
        eBody = '<html><head><title></title></head><body><div link="#fa8c00" text="#464646" vlink="#fa8c00" alink="#fa8c00" bgcolor="#464646" ><table width="790" align="center" border="0" cellpadding="0" cellspacing="0" bgcolor="#464646"><tbody><tr><td width="20" bgcolor="#ffffff"><img src="https://service.incontact.com/Images/Email/ffffff_spcr.png" width="20" height="1"></td><td width="750"><table width="750" border="0" cellpadding="0" cellspacing="0" bgcolor="#555d63"><tbody><tr><td bgcolor="#ffffff" height="20"><img src="https://service.incontact.com/Images/Email/ffffff_spcr.png" width="20" height="20"></td></tr><tr><td><table width="750" border="0" cellpadding="0" cellspacing="0"><tbody><tr><td><a href="http://www.incontact.com">';
        
        //different templates for the different ccrs
        eBody = eBody + '<img src="' + ccrControlRecords.EmailHeaderURL__c + '" width="750" border="0" height="181">';
        
        eBody = eBody + '</a></td><td width="216" align="right"></td></tr></tbody></table></td></tr><tr><td width="0" bgcolor="#B0C4DE" height="0"><table width="750" border="0" cellpadding="0" cellspacing="0"><tbody><tr><td width="0"><table width="750" border="0" cellspacing="0"><tbody><tr><td valign="top" width="100" align="center" bgcolor="#B0C4DE"><img src="https://service.incontact.com/Images/Email/dff0f4_spcr.png" width="100" height="1"></td><td valign="top" width="10" align="center" bgcolor="#ffffff"><img src="https://service.incontact.com/Images/Email/dff0f4_spcr.png" width="10" height="1"></td><td valign="top" align="left" bgcolor="ffffff"><img src="https://service.incontact.com/Images/Email/ffffff_spcr.png" width="1" height="20"><br />';
        
        //display ccr info
        eBody = eBody + '<h3><STRONG><FONT face="Arial, Helvetica, sans-serif">' + subject + ' ';
        eBody = eBody + '<a href="' + urlString + ccr.Id + '">' + ccr.Name + '</a>.</FONT></STRONG></h3><br>';
        eBody = eBody + '<table>';
        eBody = eBody + '<tr><td><FONT face="Arial, Helvetica, sans-serif" size=2><b>Summary:</b> </FONT></td><td><FONT face="Arial, Helvetica, sans-serif" size=2>' + ccr.RF_Summary__c + '</FONT></td></tr>';
        eBody = eBody + '<tr><td><FONT face="Arial, Helvetica, sans-serif" size=2><b>Release Date:</b> </FONT></td><td><FONT face="Arial, Helvetica, sans-serif" size=2>' + ccr.RF_Release_Date__c.format() + '</FONT></td></tr>';
        eBody = eBody + '<tr><td><FONT face="Arial, Helvetica, sans-serif" size=2><b>Status:</b> </FONT></td><td><FONT face="Arial, Helvetica, sans-serif" size=2>' + ccr.BMCServiceDesk__FKStatus__r.Name + '</FONT></td></tr>';
        eBody = eBody + '</table><br>';
        eBody = eBody + '<table cellpadding="2" border="1">';
        eBody = eBody + '<tr><th><FONT face="Arial, Helvetica, sans-serif" size=2>Task Type</FONT></th><th><FONT face="Arial, Helvetica, sans-serif" size=2>Assigned To</FONT></th><th><FONT face="Arial, Helvetica, sans-serif" size=2>Description</FONT></th><th><FONT face="Arial, Helvetica, sans-serif" size=2>Status</FONT></th><th><FONT face="Arial, Helvetica, sans-serif" size=2>Task Date/Time</FONT></th><th><FONT face="Arial, Helvetica, sans-serif" size=2>Duration</FONT></th></tr>';
        
        //display task info
        for(BMCServiceDesk__Task__c t: ccrTasks)
        {
            if(!toEmails.contains(t.BMCServiceDesk__FKOpenBy__r.Email)){toEmails.add(t.BMCServiceDesk__FKOpenBy__r.Email);}
            
            eBody = eBody + '<tr>';
            eBody = eBody + '<td><FONT face="Arial, Helvetica, sans-serif" size=2>' + t.RF_Task_Type__c + '</FONT></td>';
            eBody = eBody + '<td><FONT face="Arial, Helvetica, sans-serif" size=2>' + t.BMCServiceDesk__FKOpenBy__r.Name + '</FONT></td>';
            eBody = eBody + '<td><FONT face="Arial, Helvetica, sans-serif" size=2>' + t.BMCServiceDesk__taskDescription__c + '</FONT></td>';
            eBody = eBody + '<td><FONT face="Arial, Helvetica, sans-serif" size=2>' + t.BMCServiceDesk__FKStatus__r.Name + '</FONT></td>';
	            if(t.BMCServiceDesk__dueDateTime__c != null)
            {
                eBody = eBody + '<td><FONT face="Arial, Helvetica, sans-serif" size=2>' + t.BMCServiceDesk__dueDateTime__c.format('MM/dd/yyyy hh:mm a') + '</FONT></td>';
            }
            else
            {
                eBody = eBody + '<td></td>';
            }
            
            if(t.BMCServiceDesk__duration__c != null)
            {
                eBody = eBody + '<td><FONT face="Arial, Helvetica, sans-serif" size=2>' + t.BMCServiceDesk__duration__c + '</FONT></td>';
            }
            else
            {
                eBody = eBody + '<td></td>';
            }  
            eBody = eBody + '</tr>';
        }
        
        eBody = eBody + '</table>';
        eBody = eBody + '<br /><img src="https://service.incontact.com/Images/Email/ffffff_spcr.png" width="1" height="20"><br /></td><td valign="top" width="10" align="center" bgcolor="#ffffff"><img src="https://service.incontact.com/Images/Email/dff0f4_spcr.png" width="10" height="1"></td><td valign="top" width="20" align="center" bgcolor="#B0C4DE"><img src="https://service.incontact.com/Images/Email/dff0f4_spcr.png" width="20" height="1"></td></tr></tbody></table></td></tr></tbody></table></td></tr><tr><td align="center" bgcolor="#4B6789"><table width="750" border="0" cellspacing="0"><tbody><tr><td width="150" align="right"><font size="1" color="#ffffff" face="Verdana, Geneva, sans-serif">&copy; 2012 inContact, Inc. All rights reserved.</font><img src="https://service.incontact.com/Images/Email/555d63_spcr.png" width="20" height="1"></td></tr></tbody></table></td></tr><tr><td width="750" bgcolor="#ffffff" height="20"><img src="https://service.incontact.com/Images/Email/ffffff_spcr.png" width="750" height="20"></td></tr></tbody></table></td><td width="20" bgcolor="#ffffff"><img src="https://service.incontact.com/Images/Email/ffffff_spcr.png" width="20" height="1"></td></tr></tbody></table></div></body></html>';
        
        toAddresses.addAll(toEmails);
        //set email info
        email.setSubject(subject + ' ' + ccr.Name + '.');
        email.setToAddresses(toAddresses);
        email.setHtmlBody(eBody);
        
        //send mail
        if(!ccrTasks.isEmpty())
        {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        }
    }
    
    //sends email for single task changes
    public void SendSingleTaskEmailForRfChangeRequest(ID taskId, String subject)
    {
        String[] toAddresses = new String[]{};
        Set<String> toEmails = new Set<String>();
        String eBody = '';
        string urlString;
        BMCServiceDesk__Task__c ccrTask = new BMCServiceDesk__Task__c();
        BMCServiceDesk__Change_Request__c ccr = new BMCServiceDesk__Change_Request__c();
        
        //get url for ccr link
        urlString = URL.getSalesforceBaseUrl().toExternalForm();    
        urlString = urlString + '/';
        
        //create message
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        
        //get ccr
        ccrTask = [SELECT BMCServiceDesk__taskDescription__c, BMCServiceDesk__templateOrder__c, BMCServiceDesk__dueDateTime__c, RF_Task_Type__c,BMCServiceDesk__FKChange__c,
    					  BMCServiceDesk__duration__c,BMCServiceDesk__FKStatus__c, BMCServiceDesk__FKStatus__r.Name,BMCServiceDesk__FKOpenBy__r.Name, BMCServiceDesk__FKOpenBy__r.Email 
    			   FROM BMCServiceDesk__Task__c 
    			   WHERE Id = :taskId ORDER BY BMCServiceDesk__templateOrder__c];
		ccr = [SELECT Id, Name, RF_Summary__c, RF_Release_Date__c, BMCServiceDesk__FKStatus__c,BMCServiceDesk__FKStatus__r.Name 
			   FROM BMCServiceDesk__Change_Request__c 
			   WHERE ID = :ccrTask.BMCServiceDesk__FKChange__c];
        //get email address
        if(!toEmails.contains(ccrTask.BMCServiceDesk__FKOpenBy__r.Email)){
        	toEmails.add(ccrTask.BMCServiceDesk__FKOpenBy__r.Email);
    	}
        
        eBody = '<html><head><title></title></head><body><div link="#fa8c00" text="#464646" vlink="#fa8c00" alink="#fa8c00" bgcolor="#464646" ><table width="790" align="center" border="0" cellpadding="0" cellspacing="0" bgcolor="#464646"><tbody><tr><td width="20" bgcolor="#ffffff"><img src="https://service.incontact.com/Images/Email/ffffff_spcr.png" width="20" height="1"></td><td width="750"><table width="750" border="0" cellpadding="0" cellspacing="0" bgcolor="#555d63"><tbody><tr><td bgcolor="#ffffff" height="20"><img src="https://service.incontact.com/Images/Email/ffffff_spcr.png" width="20" height="20"></td></tr><tr><td><table width="750" border="0" cellpadding="0" cellspacing="0"><tbody><tr><td><a href="http://www.incontact.com">';
        
        //different templates for the different ccrs
        eBody = eBody + '<img src="' + ccrControlRecords.EmailHeaderURL__c + '" width="750" border="0" height="181">';
        
        eBody = eBody + '</a></td><td width="216" align="right"></td></tr></tbody></table></td></tr><tr><td width="0" bgcolor="#B0C4DE" height="0"><table width="750" border="0" cellpadding="0" cellspacing="0"><tbody><tr><td width="0"><table width="750" border="0" cellspacing="0"><tbody><tr><td valign="top" width="100" align="center" bgcolor="#B0C4DE"><img src="https://service.incontact.com/Images/Email/dff0f4_spcr.png" width="100" height="1"></td><td valign="top" width="10" align="center" bgcolor="#ffffff"><img src="https://service.incontact.com/Images/Email/dff0f4_spcr.png" width="10" height="1"></td><td valign="top" align="left" bgcolor="ffffff"><img src="https://service.incontact.com/Images/Email/ffffff_spcr.png" width="1" height="20"><br />';
        
        
        //ccr and task info
        eBody = eBody + '<h3><STRONG><FONT face="Arial, Helvetica, sans-serif">' + subject + ' ';
        eBody = eBody + '<a href="' + urlString + ccr.Id + '">' + ccr.Name + '</a>.</FONT></STRONG></h3><br>';
        eBody = eBody + '<table>';
        eBody = eBody + '<tr><td><FONT face="Arial, Helvetica, sans-serif" size=2><b>Summary:</b> </FONT></td><td><FONT face="Arial, Helvetica, sans-serif" size=2>' + ccr.RF_Summary__c + '</FONT></td></tr>';
        eBody = eBody + '<tr><td><FONT face="Arial, Helvetica, sans-serif" size=2><b>Release Date:</b> </FONT></td><td><FONT face="Arial, Helvetica, sans-serif" size=2>' + ccr.RF_Release_Date__c.format() + '</FONT></td></tr>';
        eBody = eBody + '<tr><td><FONT face="Arial, Helvetica, sans-serif" size=2><b>Status:</b> </FONT></td><td><FONT face="Arial, Helvetica, sans-serif" size=2>' + ccr.BMCServiceDesk__FKStatus__r.Name + '</FONT></td></tr>';
        eBody = eBody + '</table><br>';
        
        eBody = eBody + '<table cellpadding="2" border="0">';
        eBody = eBody + '<tr><td><FONT face="Arial, Helvetica, sans-serif" size=2><b>Task Type:</b></FONT></td><td><FONT face="Arial, Helvetica, sans-serif" size=2>' + ccrTask.RF_Task_Type__c + '</FONT></td></tr>';
        eBody = eBody + '<tr><td><FONT face="Arial, Helvetica, sans-serif" size=2><b>Assigned To:</b></FONT></td><td><FONT face="Arial, Helvetica, sans-serif" size=2>' + ccrTask.BMCServiceDesk__FKOpenBy__r.Name + '</FONT></td></tr>';
        eBody = eBody + '<tr><td><FONT face="Arial, Helvetica, sans-serif" size=2><b>Description:</b></FONT></td><td><FONT face="Arial, Helvetica, sans-serif" size=2>' + ccrTask.BMCServiceDesk__taskDescription__c + '</FONT></td></tr>';
        eBody = eBody + '<tr><td><FONT face="Arial, Helvetica, sans-serif" size=2><b>Status:</b></FONT></td><td><FONT face="Arial, Helvetica, sans-serif" size=2>' + ccrTask.BMCServiceDesk__FKStatus__r.Name + '</FONT></td></tr>';
        eBody = eBody + '<tr><td><FONT face="Arial, Helvetica, sans-serif" size=2><b>Task Date/Time:</b></FONT></td>';
        if(ccrTask.BMCServiceDesk__dueDateTime__c != null)
        {
            eBody = eBody + '<td><FONT face="Arial, Helvetica, sans-serif" size=2>' + ccrTask.BMCServiceDesk__dueDateTime__c.format('MM/dd/yyyy hh:mm a') + '</FONT></td></tr>';
        }
        else
        {
            eBody = eBody + '<td></td></tr>';
        }
        
        eBody = eBody + '<tr><td><FONT face="Arial, Helvetica, sans-serif" size=2><b>Duration:</b></FONT></td>';
        if(ccrTask.BMCServiceDesk__duration__c != null)
        {
            eBody = eBody + '<td><FONT face="Arial, Helvetica, sans-serif" size=2>' + ccrTask.BMCServiceDesk__duration__c + '</FONT></td>';
        }
        else
        {
            eBody = eBody + '<td></td></tr>';
        }   
        
        eBody = eBody + '</table>';
        eBody = eBody + '<br /><img src="https://service.incontact.com/Images/Email/ffffff_spcr.png" width="1" height="20"><br /></td><td valign="top" width="10" align="center" bgcolor="#ffffff"><img src="https://service.incontact.com/Images/Email/dff0f4_spcr.png" width="10" height="1"></td><td valign="top" width="20" align="center" bgcolor="#B0C4DE"><img src="https://service.incontact.com/Images/Email/dff0f4_spcr.png" width="20" height="1"></td></tr></tbody></table></td></tr></tbody></table></td></tr><tr><td align="center" bgcolor="#4B6789"><table width="750" border="0" cellspacing="0"><tbody><tr><td width="150" align="right"><font size="1" color="#ffffff" face="Verdana, Geneva, sans-serif">&copy; 2012 inContact, Inc. All rights reserved.</font><img src="https://service.incontact.com/Images/Email/555d63_spcr.png" width="20" height="1"></td></tr></tbody></table></td></tr><tr><td width="750" bgcolor="#ffffff" height="20"><img src="https://service.incontact.com/Images/Email/ffffff_spcr.png" width="750" height="20"></td></tr></tbody></table></td><td width="20" bgcolor="#ffffff"><img src="https://service.incontact.com/Images/Email/ffffff_spcr.png" width="20" height="1"></td></tr></tbody></table></div></body></html>';
        
        toAddresses.addAll(toEmails);
        //set mail info
        email.setSubject(subject + ' ' + ccr.Name + '.');
        email.setToAddresses(toAddresses);
        email.setHtmlBody(eBody);
        
        //send message
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }

}