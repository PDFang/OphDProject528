public class AccountTriggerHelper {

//update contracts sds/sdm/sales rep if changed
public static void updateContract(Map<Id, Account> mpNewAccts){
	  Boolean conUpd;
	  List<Contract> updatedContracts = new List<Contract>();
	  for(Contract c:[SELECT ActiveSalesRep__c, SDSAM__c, SDM__c, TSA__c, AccountId 
					  FROM Contract WHERE AccountId IN :mpNewAccts.keySet()]){
					 
			conUpd = false;

            if(mpNewAccts.get(c.AccountId).CS_AM__c != c.SDSAM__c)
            {
                c.SDSAM__c = mpNewAccts.get(c.AccountId).CS_AM__c;
                conUpd = true;
            }
            
            if(mpNewAccts.get(c.AccountId).CSM__c != c.SDM__c)
            {
                c.SDM__c = mpNewAccts.get(c.AccountId).CSM__c;
                conUpd = true;
            }
            
            if(mpNewAccts.get(c.AccountId).Active_Sales_Rep__c != c.ActiveSalesRep__c)
            {
                c.ActiveSalesRep__c = mpNewAccts.get(c.AccountId).Active_Sales_Rep__c;
                conUpd = true;
            }
            
            if(mpNewAccts.get(c.AccountId).TsaPrimary__c != c.TSA__c)
            {
                c.TSA__c = mpNewAccts.get(c.AccountId).TsaPrimary__c;
                conUpd = true;
            }
            
            if(conUpd)
            {
                updatedContracts.add(c);
            }

		}
	if(updatedContracts.size() > 0) 
	{
         update updatedContracts;
    }

}
//referenceable and non-referenceable
//Disconnected Account.
public static void updateVariousAccountTypes(Map<Id, Account> mpNewAccts, Map<Id, Account> mpOldAccts){
		
		 Set<Id> discAccts = new Set<Id>();
		 GYR__c[] gyrs = new GYR__c[]{};
		 Set<Id> nrAccts = new Set<Id>();
		 Set<Id> referAccts = new Set<Id>();
	     list<xmGroupChangeRequestHeader__c> xmHeaderData = new list<xmGroupChangeRequestHeader__c>();

		for (Account na : mpNewAccts.values()){	
			//check for new disconnected gyrs
            if(na.CG_Disconnect_Date__c != NULL && mpOldAccts.get(na.Id).CG_Disconnect_Date__c == NULL)
            {
                discAccts.add(na.Id);
            }
            
            //check for not referenceable
            if(mpOldAccts.get(na.Id).Referenceable__c && !na.Referenceable__c && na.NotReferencableReason__c != NULL)
            {
                nrAccts.add(na.Id);
            }
            
            //check for referenceable
            if(!mpOldAccts.get(na.Id).Referenceable__c && na.Referenceable__c && na.NotReferencableReason__c != NULL)
            {
                referAccts.add(na.id);
            }
		}

		if(!referAccts.isEmpty()){
			List<Account> refAcctList = new List<Account>();
			refAcctList = [SELECT ID, NotReferencableReason__c FROM Account WHERE ID IN :referAccts];
			for(Account a:refAcctList)
			{
				a.NotReferencableReason__c = NULL;
			}
        
			update refAcctList;
      }
	//loop through not referencable accounts
		 if(!nrAccts.isEmpty()){
			List<Account> nrAcctList = new List<Account>();
			nrAcctList = [SELECT ID, NotReferencableReason__c FROM Account WHERE ID IN :nrAccts];
			List<Note> notes = new List<Note>();
     
			for(Account a:nrAcctList)
			{
			   Note n = new Note();
			   n.ParentId = a.Id;
			   n.Body = a.NotReferencableReason__c;
			   n.Title = 'Reason account was marked NOT referenceable.';
			   notes.add(n);           
			}
		  
			insert notes;
	}
	//see if any new disconnected accounts
		System.debug('discAccts == >' + discAccts);
		if(!discAccts.isEmpty()){
			//see if any open black gyrs
			gyrs = [SELECT ID, GYRStatus__c FROM GYR__c WHERE GYREndDate__c = NULL AND Account__c IN :discAccts];
			//close out gyrs
			if(!gyrs.isEmpty())
			{
				for(GYR__c gyr:gyrs)
				{
					if(gyr.GYRStatus__c != 'Black')
						gyr.GYREndDate__c = system.today();
				}
			
				update gyrs;
			}
            // expire license -- Please uncomment this logic before LMA deployment.
            list<sfLma__License__c> lstlicense = new list<sfLma__License__c>();
                         
              for (sfLma__License__c lic : [select Id, sfLma__Expiration__c
			  								FROM sfLma__License__c
			  								where sfLma__Account__c in :  discAccts
											and (NOT sfLma__Instance__c like 'CS%') and sfLma__License_Status__c in('Active', 'Trial')])
              {            // add status to the SOQL
                sfLma__License__c updlic = new sfLma__License__c(id = lic.Id);
                
                if (lic.sfLma__Expiration__c == null)
                    	updlic.sfLma__Expiration__c = system.today(); 
                  
                lstlicense.add(updlic);  
              }                
               System.debug('lstlicense ====> ' + lstlicense); 
                update lstlicense;

	}

 }
 // send accounts to Sharepoint
public static void accSendToSharePoint(List<Account> acctsToSendToSharepoint){
	Set<string> cadbillAccounts = new Set<String>(); 
	for(Account acct: acctsToSendToSharepoint){
			cadbillAccounts.add(string.valueOf(acct.CadebillAccountNo__c));            
        }
		if (!Test.isRunningTest()){
              SharepointDocumentAccess.CreateCustomerLibraryAsync(cadbillAccounts);
            }
 }
 // Create Entitlement if doen't exist
public static void accEntitlementsCreation(List<Account> lstNewAct, List<Account> lstOldAct){
	  List<Account> accts = new List<Account>();
	  Set<Id> includeAccts = new Set<Id>();
	  List<Entitlement> entToInsert = new List<Entitlement>();
	  Set<Id> staccts = new Set<Id>();
		for (Account act : lstNewAct){
			 staccts.add(act.Id);
			 includeAccts.add(act.Id);
		}
		for (Entitlement ent : [Select e.Id, e.AccountId From 
								Entitlement e 
								WHERE e.AccountID IN :staccts  AND Status = 'Active']){
						if(includeAccts.contains(ent.AccountId))
								includeAccts.remove(ent.AccountId);
			}
		
    
		if (includeAccts.size() > 0){
			SlaProcess sla = [SELECT Id FROM SlaProcess WHERE Name = 'inContact Standard Process' AND IsActive = true LIMIT 1]; 
			SlaProcess vzSla = [SELECT Id FROM SlaProcess WHERE Name = 'Verizon Entitlement Process' AND IsActive = true LIMIT 1]; 
			SlaProcess ringCentralsla = [SELECT Id FROM SlaProcess WHERE Name = 'RingCentral Entitlement Process' AND IsActive = true LIMIT 1]; 
			
			accts = [SELECT Id, Name, CadebillAccountNo__c, Parent.CostGuard_Acct__c, Parent.CadebillAccountNo__c FROM Account WHERE ID IN :includeAccts];
		
			for(Account a:accts){
				if(a.CadebillAccountNo__c != NULL){
					Entitlement e = new Entitlement();
					e.AccountId = a.Id;
					e.StartDate = system.today();
					e.Name = a.Name + ' - ' + a.CadebillAccountNo__c;
				
					if(a.Parent.CadebillAccountNo__c == 4593141)
						e.SlaProcessId = vzSla.Id;				
					else if(a.Parent.CadebillAccountNo__c == 4594865)
						e.SlaProcessId = ringCentralsla.Id;
					else	
						e.SlaProcessId = sla.Id;
						
					entToInsert.add(e);
				}
			}		
			if(!entToInsert.IsEmpty())
				insert entToInsert;		
		}
  }
// Account ParnershipChange
public static void accountPartnershipChange(List<Account> lstNewAct, List<Account> lstOldAct){
	//Record Types
	Id subAgentRT = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND Name = 'Sub Agents'].id;
	Id custRT = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND Name = 'Customers'].id;

	//Account Maps
	Map<Id,Account> custAccts = new Map<Id,Account>();
	Map<Id,Account> subAgentAccts = new Map<Id,Account>();

		if (lstOldAct == null){
			for (Account a : lstNewAct){
				if(a.RecordTypeId == custRT && a.SalesPartner__c != null){
					//add account is new account with a sales partner listed
					custAccts.put(a.Id,a);			
					}
				if (a.SalesPartner__c == null){
					a.SalesPartnerMasterAgent__c = null;
				}
			}
		}
		else{
			for(integer i=0; i < lstNewAct.size(); i++){
				Account an = lstNewAct[i];
				Account ao = lstOldAct[i];
			
				//customer accounts that have a different sales partner
				if(an.RecordTypeId == custRT && (an.SalesPartner__c != ao.SalesPartner__c)){
					//if sub agent is removed then remove master agent
					if(an.SalesPartner__c == null){
						an.SalesPartnerMasterAgent__c = null;
					}
					else{
						//add to list of accounts to get updated
						custAccts.put(an.Id,an);
					}
				}
							
				//sub agent accounts where the parent ID has changed.
				if(an.RecordTypeId == subAgentRT && (an.ParentId != ao.ParentId)){
					subAgentAccts.put(an.Id,an);
				}
			}
		}
		if(!custAccts.isEmpty()){
			//update customer accounts
			AccountPartnerClass.UpdateCustomerAccountMasterAgent(custAccts);
		}
	
		if(!subAgentAccts.isEmpty()){
			//update customer account attached to the sub agent accounts
			AccountPartnerClass.UpdateSubAgentChildAccounts(subAgentAccts);
		}
}

public static map<id,Id> updateOwner(list<Account> newActList, map<id,Account> oldActMap){
	//Record Types
	Id prosp = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospects').getRecordTypeId();
	Id cust =  Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customers').getRecordTypeId();
	
    map<Id, ID> accountOwnerIdMap = new map<Id,ID>();
  	
    
    for(Account newAct : newActList)
    {
         Id newCS = newAct.CS_AM__c;
         double newCBID = newAct.CadebillAccountNo__c;  
        if(oldActMap != null)
        {
            if(newCS != oldActMap.get(newAct.Id).CS_AM__c && newAct.RecordTypeId == cust && newCS != null)
             	accountOwnerIdMap.put(newAct.Id, newAct.CS_AM__c);
        }
        else if(newCBID != null && newCS != null)
        {          
              accountOwnerIdMap.put(newAct.Id, newCS);
        }
    }
	return accountOwnerIdMap;   
    }
	
}