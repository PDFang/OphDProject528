trigger CaseBeforeInsert on Case (before insert) 
{
    if(TriggerHandler.isBypassed('CaseTriggerHandler')){
        system.debug('By passed CaseBeforeInsert trigger');
        return;
    }
    new CaseTriggerHandler().run();
    Schema.DescribeSObjectResult d = Schema.SObjectType.Case; 
    Map<String,Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();
    Map<ID,Schema.RecordTypeInfo> recordTypeMapById = d.getRecordTypeInfosByID();

    //Get Event record type id
    Id eventRecordType = rtMapByName.get('Event').getRecordTypeId();
    Id maintenanceRecordType = rtMapByName.get('Maintenance Notification').getRecordTypeId();
    Id incidentRecordType = rtMapByName.get('Incident').getRecordTypeId();
    String nOCProfileId = '00e700000017HEk';
    Id techSupportProfileId = '00e700000017dPo';
    String userProfile = UserInfo.getProfileId();
    
    // Get account IDs to look up CSAM
    // Use a Set, as add() method will only add an item if it is not already in the set, hence no duplicates
    Set<ID> accountIds = new Set< Id >();
    Set<ID> recordTypeIds = new Set< Id >();
    Set<ID> contactIDs = new Set<Id>();
    
    
    
    for(Case c : trigger.new)
    {
        
        //add accounts to set
        //system.debug('Account ID:' + c.AccountId);
        if(c.AccountId != null)
        {
            accountIds.add(c.AccountId);
        } 
        
        //add contacts to set
        //system.debug('Contact ID:' + c.ContactId);
        contactIds.add(c.ContactId);
    }
    
    //get a list off all contacts from the cases
    List<Contact> contacts = new List<Contact>([SELECT Id, AccountId FROM Contact WHERE Id IN :contactIDs]);
    Map<Id, Contact> ctMap = new Map<Id, Contact>(); 
    
    
    //loop through contacts and add the account id if is null on the case
    for(Contact ct:contacts)
    {
        system.debug('Contact Account ID:' + ct.AccountId);
        if(!accountIds.contains(ct.AccountId))
        {
            accountIds.add(ct.AccountId);
        }
        ctMap.put(ct.Id,ct);
    }
    
    // Create Map objects for all accounts and RecordTypes using our Sets from above
    Map<ID,Account> accounts = new Map<ID,Account>([SELECT Id, CS_AM__c, CS_AM__r.LastName, CSM__c, CS_AM__r.ManagerId, CostGuard_Acct__c,  (Select Id From Entitlements WHERE Status = 'Active' LIMIT 1) FROM Account WHERE Id IN : accountIds]);
    //Map<ID,RecordType> recordTypes = new Map<ID,RecordType>([SELECT Id, Name FROM RecordType WHERE Id IN :recordTypeIds]);
    
    //get the Basic Support business hours
    ID busHrs = [SELECT Id From BusinessHours WHERE Name = 'Basic Support' LIMIT 1].Id;
    
    //loop through cases
    for (Case c : trigger.new)
    {
        
        //add Basic Support business hours to non-SILVER, GOLD, or PLATINUM customers
        if(c.ServicePackage__c != null)
        {
            if(!(c.ServicePackage__c.toUppercase().Contains('SILVER') || c.ServicePackage__c.toUppercase().Contains('GOLD') || c.ServicePackage__c.toUppercase().Contains('PLATINUM')))
            {
                c.BusinessHoursId = busHrs;         
            }
        } 
     
        //get contact info
        if(c.AccountId == null)
        {
            Contact bCt = new Contact();
            bCt = ctMap.get(c.ContactId);
            if(bCT != null)
            {
                c.AccountId = bCt.AccountId;
            }   
            system.debug('Blank Account New Account ID:' + c.AccountId);
            
        }
        
        Account a = accounts.get(c.AccountId);
        //when case is not service request or help desk
        if(c.RecordTypeId != '01270000000LuEoAAK' && c.RecordTypeId != '01270000000LuEqAAK')
        {
            // Set the acknowledged by field
            c.Acknowledge_By__c = System.now().addHours(2);
            //Set Case Priority
            if(c.RecordTypeId == '01270000000LuEp' || c.RecordTypeId == '01270000000MzcW' )
            {
                //Web origin is for service site only
                //if(c.Origin != 'Web')
                //{
                    CaseAssignmentClass.setCasePriority(c,false);
                //}
                
                //GET ENTITLEMENT FROM ACCOUNT
                if(c.AccountId != null)
                {
                    Entitlement[] ents = a.Entitlements;
                    if(!ents.isEmpty())
                    {
                        for(Entitlement e:ents)
                        {
                            c.EntitlementId = e.Id;
                        }
                    }
                }
                
            }
            // Set Escalation Time
            if(c.Priority == 'P1' || c.Priority == 'P2')
                c.Escalation_Date_Time__c = System.now().addMinutes(10);
            else
                c.Escalation_Date_Time__c = System.now().addMinutes(60);
            // Assigned to CS-AM if needed
            if(c.RecordTypeId != '012S00000000J5V' && accounts.containsKey(c.AccountID))
            {
                CaseAssignmentClass.AssignToCsAm(c, recordTypeMapById.get(c.RecordTypeId).getName(), a);
            }
        }
        
        //add CostGuard Account Number
        if(accounts.containsKey(c.AccountID))
        {
            //c.CostGuard_Acct__c = a.CostGuard_Acct__c;
            
            if(a.CS_AM__c != null)
            {
                c.SdsAm__c = a.CS_AM__c;
            }
            
            if(a.CSM__c != null)
            {
                c.SDM__c = a.CSM__c;
            }
        }
        
        //maintenance time zone conversion
        if(c.RecordTypeId == maintenanceRecordType && c.TimeZone__c == 'UTC/GMT')
        {
            datetime sd = c.EventStartDateTime__c;
            datetime ed = c.EventEndDateTime__c;
            
            c.EventStartDateTime__c = datetime.newInstanceGmt(sd.year(),sd.month(),sd.day(),sd.hour(),sd.minute(),sd.second());
            c.EventEndDateTime__c = datetime.newInstanceGmt(ed.year(),ed.month(),ed.day(),ed.hour(),ed.minute(),ed.second());
            
        }
        
        
        
        // Update case status
        // INGORE IF COLUMBUS MIGRATION IF STATEMENT CAN BE REMOVED
        if(c.Columbus_Case_Number__c == null)
        {
        	c.Status = CaseAssignmentClass.SetDefaultCaseStatus(c, rtMapByName);
        
            //clear out in case cloned
            c.ResolvedDate__c = null;
            c.EntitlementStatus__c = 'New';
            c.ReBillReviewer__c = UserInfo.getUserId();
        }
        
    }   
}