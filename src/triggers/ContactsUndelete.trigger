trigger ContactsUndelete on Contact (before delete, after undelete) 
{
	List<Contact> contacts = new List<Contact>();
	
	//get list of all the contacts undeleted
	if(trigger.isDelete)
	{
		contacts = [SELECT Id, IsDeleted, Last_Delete_Date__c, CG_ContactID__c FROM Contact WHERE Id IN :trigger.oldMap.keySet()];
	}
	else
	{
		contacts = [SELECT Id, IsDeleted, Last_Delete_Date__c, CG_ContactID__c FROM Contact WHERE Id IN :trigger.newMap.keySet()];
	}
  	
  	//loop through contacts and erase contact ID
  	for(Contact c: contacts)
  	{
  		if(trigger.isDelete)
  		{
  			c.Last_Delete_Date__c = system.now();
  		}
  		else
  		{		
	  		if(c.Last_Delete_Date__c != NULL)
	  		{
		  		if(c.Last_Delete_Date__c.addMinutes(5) >= system.now())
		  		{
		  		  trigger.new[0].addError('Must wait at least five minutes to undelete after deleting a contact.');
		  			
		  		}
		  		else
		  		{
		  			c.CG_ContactID__c = NULL;
		  		}
	  		}
  		}
  	}
  	
  	update contacts;
}