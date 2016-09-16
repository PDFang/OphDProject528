trigger CaseCommentFirstResponse on CaseComment (before insert) 
{
	//do not include comments from
	if(Userinfo.getLastName() != '_castiron' && Userinfo.getUserId() != '00570000001GJyZ')
	{
		List<Id> caseIds = new List<Id>();
		//bulk loads do not equate first response
		if(trigger.new.size()==1)
		{
			for(CaseComment cc: trigger.new)
			{
				//ignore _castiron created and private comments
				if(cc.IsPublished == true)
				{
					caseIds.add(cc.ParentId);
				}
			}
		}
		
		
	
		if(!caseIds.isEmpty())
		{
			CaseAssignmentClass.CompleteMilestone(caseIds, 'First Response', system.now());
			CaseAssignmentClass.CompleteMilestone(caseIds, 'Status Update', system.now());
			CaseAssignmentClass.CompleteMilestone(caseIds, '1st Response - Non-Emergency', system.now());
			//CaseAssignmentClass.ResetStatusUpdateMilestone(caseIds);
		}
	}
}