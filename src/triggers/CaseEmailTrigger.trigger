trigger CaseEmailTrigger on EmailMessage (after insert) 
{
	
	List<EmailMessage> ems = new List<EmailMessage>();
	List<CaseComment> ccs = new List<CaseComment>();
	List<Case> casesToUpdate = new List<Case>();
	Set<ID> caseIds = new Set<ID>();
	ems = trigger.new;
	
	Schema.DescribeSObjectResult d = Schema.SObjectType.Case; 
	Map<String,Schema.RecordTypeInfo> recordTypeMapByName = d.getRecordTypeInfosByName();
	Map<Id,Schema.RecordTypeInfo> rtMapById = d.getRecordTypeInfosById();
	
	//Get Help Desk record type id
	Id helpDeskRecordTypeID = recordTypeMapByName.get('Help Desk').getRecordTypeId();
	Id eventRecordTypeID = recordTypeMapByName.get('Event').getRecordTypeId();
	Id notificationRecordTypeID = recordTypeMapByName.get('Maintenance Notification').getRecordTypeId();
	Id incidentRecordTypeId = recordTypeMapByName.get('Incident').getRecordTypeId();
    Id workOrderRecordTypeId = recordTypeMapByName.get('Work Orders').getRecordTypeId();
    Id serviceRequestRecordTypeId = recordTypeMapByName.get('Service Request').getRecordTypeId();
   
	
	//get all Case IDs
	for(EmailMessage e:ems)
	{
		caseIds.add(e.ParentId);
	}
	
	Map<ID,Case> cases = new Map<Id,Case>([SELECT CaseNumber, Id, IsClosed, Status, RecordTypeID, OwnerId, Assigned_To__c FROM Case WHERE ID IN:caseIds]);
	
	for(EmailMessage e:ems)
	{
		Id recType = cases.get(e.ParentId).RecordTypeID;
		
		if(recType != eventRecordTypeID && recType != notificationRecordTypeID)
		{
				
			String msgBody = '';
			Integer sLimit = 199;
			
			if(string.isNotBlank(e.TextBody) && e.TextBody.length() < 200)
			{
				sLimit = e.TextBody.length() - 1;
			}
			
			if(e.Subject != NULL 
				&& !e.Subject.containsIgnoreCase('OUT OF OFFICE')
				&& !e.Subject.containsIgnoreCase('Automatic reply:'))
			{
			
				CaseComment cc = new CaseComment();
				cc.IsPublished = false;
				cc.ParentId = e.ParentId;
				
				if(e.Incoming)
				{		
					msgBody = msgBody + 'EMAIL RECEIVED FROM: ' + e.FromName + '<' + e.FromAddress + '>\n\r';
					//mark help desk tickets
					if(recType == helpDeskRecordTypeID)
					{
						if(!cases.get(e.ParentId).IsClosed)
						{
							cases.get(e.ParentId).Status = 'Email Received';
						}
						
						casesToUpdate.add(cases.get(e.ParentId));
					}

                    
					//udpate incident status
					if((recType == incidentRecordTypeId || rtMapById.get(recType).getName().Contains('Premise') 
                         || recType == workOrderRecordTypeId || recType == serviceRequestRecordTypeId) 
                       && !cases.get(e.ParentId).IsClosed && !e.FromAddress.containsIgnoreCase('incontact.com'))
                        
					{
						cases.get(e.ParentId).Status = 'Customer Updated';
						casesToUpdate.add(cases.get(e.ParentId));
						
					}
				}
				else
				{
					msgBody = msgBody + 'EMAIL SENT TO: ' + e.ToAddress + '\n\r';
					//mark help desk tickets
					if(recType == helpDeskRecordTypeID)
					{
						if(!cases.get(e.ParentId).IsClosed)
						{
							cases.get(e.ParentId).Status = 'Waiting for Reply';
						}
						
						casesToUpdate.add(cases.get(e.ParentId));
					}
				}
				msgBody = msgBody + 'SUBJECT: ' + e.Subject + '\n\r';
				msgBody = msgBody + 'For more information see the email attached to the Case \n\r';
				
				if(string.isNotBlank(e.TextBody))
				{
					msgBody = msgBody + '\n\r' + e.TextBody.substring(0,sLimit);
				}
				
				cc.CommentBody = msgBody;
				ccs.Add(cc);
			}
		}
	}
	
	if(!casesToUpdate.isEmpty())
	{
		update casesToUpdate;
	}
	
	if(!ccs.isEmpty())
	{
		insert ccs;
	}
	
}