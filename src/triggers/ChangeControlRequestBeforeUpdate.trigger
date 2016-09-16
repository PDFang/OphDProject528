trigger ChangeControlRequestBeforeUpdate on ChangeControlRequest__c (before update) 
{
	
	for(integer i=0;i<trigger.new.size();i++)
	{
		boolean sendEmail = false;
		
		ChangeControlRequest__c oldCcr = trigger.old[i];
		ChangeControlRequest__c newCcr = trigger.new[i];
		
		
    	CCRControlsClass ccrCont = new CCRControlsClass(newCcr.CCRType__c);
    	CCRControls__c ccrValues  = ccrCont.ccrControlRecords;
		
		if(!oldCcr.PeerApproved__c && newCcr.PeerApproved__c)
		{
			
            if(ccrValues.BypassMasterReview__c)
            {
                newCcr.Status__c = 'Board Review';
                newCcr.RecordTypeId = ccrValues.CCBBoardRecordTypeID__c;   
                sendEmail = true;
            }  
            else
            {
                newCcr.Status__c = 'CCB Master Review';
                newCcr.RecordTypeId = ccrValues.CCBMasterRecordTypeID__c;
            }
    
            newCcr.OwnerId = ccrValues.CCBMastersQueue__c;
		}
		else if(!oldCcr.PeerRejectedRecalled__c && newCcr.PeerRejectedRecalled__c)
		{
			
                newCcr.Status__c = 'Peer Review Rejected';
                newCcr.RecordTypeId = ccrValues.NewRecordTypeID__c;
                newCcr.Approver1__c = null;
                newCcr.Approver2__c = null;
                newCcr.Approver3__c = null;
		}
		
		//send mail if going to the board
        if(sendEmail)
        {
            ccrCont.SendTaskEmail(newCcr.id, 'You have one or more tasks waiting for Board Approval on');
        }
	}
}