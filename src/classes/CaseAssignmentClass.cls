public class CaseAssignmentClass 
{
	//used for test methods to reduce the number of query rows
	public static boolean isTest = false;
	
	
	public static Map<ID,SET<ID>> GetValidQueueUsers(Map<ID,Group> allQueues, Set<ID> affectedUserIDs)
	{
		//This is the Map that we return
		//Map Key = Group.ID
		//Map Value = SET of all User.IDs that are part of the of group either by role or by direct assignment
		Map<ID,SET<ID>> queueUsers = new Map<ID,SET<ID>>();
	
		//Get all the user or groupIDs
		Set<ID> userOrGroupIds = new Set<ID>();
		for(Group g : allQueues.values())
		{
			for(GroupMember gm : g.GroupMembers)
			{
				userOrGroupIds.Add(gm.UserOrGroupId);
			}
		}
		
		//Get all the groups that represent a role or role and subordinates
		Map<ID,Group> roleGroups = new Map<ID,Group>([SELECT g.ID, g.Type, g.RelatedID FROM Group g WHERE g.Id IN : userOrGroupIds ]);
												
		//Get all roles from the database including all the users that are part of the role
		Map<ID,UserRole> roles = new Map<ID,UserRole>([SELECT ur.Id, ur.ParentRoleID, (SELECT Id FROM Users WHERE Id IN : affectedUserIDs) FROM UserRole ur WHERE ur.PortalType = 'None']);
		
		// Loop through all queues
		for(ID id : allQueues.keySet())
		{
			//create a new element in our queueUsers Map
			queueUsers.put(id, new Set<ID>());
			
			//loop through each queue member
			for(GroupMember gm : allQueues.get(id).GroupMembers)
			{
				//check to see if the this is a UserID or a GroupID
				if(roleGroups.containsKey(gm.UserOrGroupId))
				{	
					Group assignedGroup = roleGroups.Get(gm.UserOrGroupId);
					UserRole assignedUserRole = roles.get(assignedGroup.RelatedID);
					
					if(assignedGroup.Type == 'Role')
					{
						CaseAssignmentClass.AssignUsersFromRole(assignedUserRole,id,queueUsers);
					}
					else if(assignedGroup.Type == 'RoleAndSubordinatesInternal')
					{
						CaseAssignmentClass.AssignUsersFromRoleAndSubordinates(assignedUserRole, id, queueUsers, roles);
					}
				}
				else //The ID is a User
				{
					//Add the user to our queueUsers as a direct assignment
					queueUsers.get(id).add(gm.UserOrGroupId);
				}
			}
		}
		return queueUsers;
	}
	
	public static void AssignUsersFromRole(UserRole userRole, ID queueId, Map<ID,SET<ID>> queueUsers)
	{
		//Loop through the users list and add all the users to the queueUsers Map
		for(User user : userRole.Users)
		{
			queueUsers.get(queueId).add(user.id);
		}
	}
	
	public static void AssignUsersFromRoleAndSubordinates(UserRole userRole, ID queueId, Map<ID,SET<ID>> queueUsers, Map<ID,UserRole> allRoles)
	{
		//First add the users from this role
		CaseAssignmentClass.AssignUsersFromRole(userRole,queueId,queueUsers);
		//Now find out if this role has children and the users from those roles
		for(UserRole ur : allRoles.values())
		{
			//check if this role is one of our children
			if(ur.ParentRoleId == userRole.Id)
			{
				CaseAssignmentClass.AssignUsersFromRoleAndSubordinates(ur, queueId, queueUsers, allRoles);
			}
		}
	}

	public static void setCasePriority(Case c, Boolean isUpdate)
	{
		string severity = c.Severity__c;
		//string frequency = c.Freqeuncy__c;
		
		if(c.Status != 'New' || !isUpdate)
		{
			
			if(c.Origin == 'Web')
			{
				//set priority if came from support site
				if(severity != NULL)
				{
					c.Priority = severity.replace('S','P');
					
					if(severity == 'S2')
					{
						c.Urgency__c = 'Medium';
						c.Impact__c = 'Medium';
					}
					else if(severity == 'S3')
					{
						c.Urgency__c = 'Low';
						c.Impact__c = 'Medium';
					}
					else
					{
						c.Urgency__c = 'Low';
						c.Impact__c = 'Low';
					}
				}
			}
			else
			{
				if(c.Impact__c == 'High' && c.Urgency__c == 'High')
				{
					c.Priority = 'P1';
					c.Severity__c = 'S1';
				}
				else if((c.Impact__c == 'High' &  c.Urgency__c == 'Medium') || (c.Impact__c == 'Medium' && c.Urgency__c == 'High'))
				{
					c.Priority = 'P2';
					c.Severity__c = 'S2';
				}
				else if((c.Impact__c == 'High' &  c.Urgency__c == 'Low') || (c.Impact__c == 'Medium' && c.Urgency__c == 'Medium') || (c.Impact__c == 'Low' && c.Urgency__c == 'High'))
				{
					c.Priority = 'P3';
					c.Severity__c = 'S3';
				}
				else if((c.Impact__c == 'Medium' &  c.Urgency__c == 'Low') || (c.Impact__c == 'Low' && c.Urgency__c == 'Medium'))
				{
					c.Priority = 'P4';
					c.Severity__c = 'S4';
				}
				else
				{
					c.Priority = 'P4';
					c.Severity__c = 'S4';
				}
			}
		}
	}
	
	public static void AssignToCsAm (Case c, string recordTypeName, Account a)
	{
		//make sure CS-AM is not a group or NULL
		if(a.CS_AM__r.LastName == null || a.CS_AM__r.LastName == '_Call Center' || a.CS_AM__r.LastName == '_Account Manager Team' || a.CS_AM__r.LastName == '_inContact Client Support')
		{
			return;
		} 
		else if((recordTypeName == 'Incident' && (c.Request_Type__c == 'Billing Issues' || c.Request_Type__c == 'Not Sure...')) || (recordTypeName == 'Service Request' && c.Request_Type__c == 'Service Request'))
		{ 
			//assign to CS-AM
    		c.Assigned_To__c = a.CS_AM__c;
    		c.Escalation_Manager__c = a.CS_AM__r.ManagerId;
		} 
	}
	

	public static void CompleteMilestone(List<Id> caseIds, String milestoneName, DateTime complDate) 
	{
		List<CaseMilestone> cmsToUpdate = [select Id, completionDate, case.SlaExitDate from CaseMilestone
                       where caseId in :caseIds and MilestoneType.Name=:milestoneName and completionDate = null];
                       
	    if (cmsToUpdate.isEmpty() == false)
	    {
	      for (CaseMilestone cm : cmsToUpdate)
	      {
	      	if(cm.case.SlaExitDate == null)
	      	{
	        	cm.completionDate = complDate;
	      	}
	      }
	      update cmsToUpdate;
	    } // end if
 	 }
 	 
 	 public static void ResetStatusUpdateMilestone(List<Id> caseIds)
 	 {
 	 	List<CaseMilestone> cmsToUpdate = [select Id, completionDate, case.SlaExitDate from CaseMilestone
                       where caseId in :caseIds and MilestoneType.Name='Status Update' and completionDate = null];
                       
        if (cmsToUpdate.isEmpty() == false)
	    {
	      for (CaseMilestone cm : cmsToUpdate)
	      {
	      	if(cm.case.SlaExitDate == null)
	      	{
	        	cm.StartDate = system.now();
	      	}
	      }
	      update cmsToUpdate;
	    } // end if
             	
 	 }
 	 
 	 @future
 	 public static void ReopenSlaMilestone(Set<Id> caseIds)
 	 {
 	 	List<CaseMilestone> cmsToUpdate = [select Id, completionDate from CaseMilestone
                       where caseId in :caseIds and MilestoneType.Name='SLA' and completionDate != NULL];
                       
        if (cmsToUpdate.isEmpty() == false)
	    {
	      for (CaseMilestone cm : cmsToUpdate)
	      {
	       	cm.CompletionDate = null;
	      }
	      update cmsToUpdate;
	    } // end if
             	
 	 }
 	 
 	public static String SetDefaultCaseStatus(Case c, Map<String,Schema.RecordTypeInfo> rtMapByName)
	{
		//Get Event record type id
		ID eventRecordType = rtMapByName.get('Event').getRecordTypeId();
		//Get Corp IT record type id
		Id corpITRecordType = rtMapByName.get('Corp IT').getRecordTypeId();
		Id knownIssueRecordType = rtMapByName.get('Known Issue').getRecordTypeId();
		String results;
		ID recordTypeId = c.RecordTypeId;
		
		ID nOCProfileId = '00e700000017HEk';
		String userProfile = UserInfo.getProfileId();
		
		
		if(userProfile == nOCProfileId && eventRecordType == recordTypeId)
        {
        	c.IgnoreEventStatusLock__c = true;
        	results = 'Confirmed'; 
        }
        else if(eventRecordType == recordTypeId)
    	{
    		c.IgnoreEventStatusLock__c = true;
    		results = 'Suspected';	
    		c.InternalEvent__c = true;
    	}
        else if(recordTypeId == corpITRecordType)//Corp IT
        {
        	results = 'New';
        }
        else if(recordTypeId == knownIssueRecordType)
        {
        	results = 'In Review';
        }
        else
        {
      		results = 'Auto-Assigned';
        }
        
        return results;
	}
	
	public static List<GroupMember> ListUsersGroups(string userId)
	{
		List<GroupMember> gm = new List<GroupMember>();
		
		GroupMember[] gmArray = [SELECT Id, GroupId FROM GroupMember WHERE UserOrGroupId = :userId];
		
		if(gmArray != null)
		{
			gm.addAll(gmArray);
		}
		
		return gm;
	}
	
	public static List<Group> UsersQueues(string userId, string sObjectName)
	{
		Group[] groups = new Group[]{};
		Set<Id> usersGroups = new Set<Id>();
		Set<Id> queueGroups = new Set<id>();
		Set<Id> parentRoles = new Set<Id>();
		Set<Id> roleGroups = new Set<Id>();
		List<QueueSobject> objectQueues = new List<QueueSobject>([SELECT Id, QueueId, Queue.Name FROM QueueSobject WHERE SobjectType = :sObjectName]);
		
		GroupMember[] gm = ListUsersGroups(userId);
		
		if(gm == null || objectQueues == null)
		{
			return null;
		}
		
		for(QueueSobject q:objectQueues)
		{
			queueGroups.add(q.QueueId);
		}
		
		for(GroupMember g:gm)
		{
			usersGroups.add(g.GroupId);
		}
		
		parentRoles = ParentRoles(userId);
		 
		roleGroups = new Map<Id,Group>([SELECT Id FROM Group WHERE Type IN('RoleAndSubordinates','RoleAndSubordinatesInternal') AND RelatedId IN :parentRoles]).keySet();
		
		groups = [SELECT Id, Name FROM Group WHERE Id IN :queueGroups AND Id IN (SELECT GroupId FROM GroupMember WHERE UserOrGroupId IN :usersGroups OR UserOrGroupId = :userId) ];
		groups.addAll([SELECT Id, Name FROM Group WHERE Id IN :queueGroups AND Id IN (SELECT GroupId FROM GroupMember WHERE UserOrGroupId IN :roleGroups)]);
		return groups;
	}
	
	public static Set<Id> ParentRoles(string userId)
	{
		
		Set<Id> parents = new Set<Id>();
		ID usersRole = [SELECT UserRoleId FROM User WHERE Id = :userId].UserRoleId;
		Id parentRole;
		Id childRole;
		Map<Id, UserRole> allUserRoles = new Map<Id, UserRole>([SELECT Id, ParentRoleId FROM UserRole]);
		UserRole ur = new UserRole();
		
		
		
		ur = allUserRoles.get(usersRole);
		parents.add(ur.Id);
		parentRole = ur.ParentRoleId;
		
		while(parentRole != null)
		{
			ur = allUserRoles.get(parentRole);
			parents.add(ur.Id);
			parentRole = ur.ParentRoleId;
		}
		
		return parents;
	}
    
    @future
    public static void KnowIssueClosed(Set<Id> knownIssueIds)
    {
        List<Case> cases = new List<Case>();
        
        for(Case c:[SELECT Id, Status FROM Case WHERE RecordType.Name = 'Incident' AND KnownIssue__c IN :knownIssueIds])
        {
            c.Status = 'Closed';
            cases.add(c);
        }
        
        if(!cases.isEmpty())
        {
            try
            {
            	update cases;
            }
            catch(Exception ex)
            {
                inContactBaseClass.SendErrorEmail(ex,'KnowIssueClosed');
            }
        }
    }
	
    @future
    public static void KnownIssueClusterCheck(Set<Id> knownIssueIds)
    {
        Map<String, ProductEventMap__c> eventMap = ProductEventMap__c.getAll();
        Map<Id, Case> casesToUpdate = new Map<Id,Case>();
        Set<String> closedStatuses = GetClosedStatuses();
        
        for(Case ki:[SELECT Id, PlatformsImpacted__c, ProductImpacted__c, (SELECT Id, AccountCluster__c FROM KnownIssues__r) FROM Case WHERE Status NOT IN :closedStatuses AND Id IN :knownIssueIds])
        {
            for(ProductEventMap__c em:eventMap.values())
            {
                if(ki.ProductImpacted__c == em.Product__c && em.HasClusters__c)
                {
            		  for(Case c: ki.KnownIssues__r)
                      {
                          if(c.AccountCluster__c != null &&  !ki.PlatformsImpacted__c.contains(em.Platform__c.replace('Cluster',c.AccountCluster__c)))
                          {
                              ki.PlatformsImpacted__c = ki.PlatformsImpacted__c + ';' + em.Platform__c.replace('Cluster',c.AccountCluster__c);
                              if(!casesToUpdate.containsKey(ki.Id)){
                                  casesToUpdate.put(ki.Id,ki);
                              }
                          }
                      }
                }
            }
        }
        
        if(!casesToUpdate.isEmpty())
        {
            try
            {
            	update casesToUpdate.values();
            }
            catch(Exception ex)
            {
                inContactBaseClass.SendErrorEmail(ex,'KnownIssueClusterCheck');
            }
        }
        
    }
    
    public static Set<String> GetClosedStatuses()
    {
        
    	Set<String> closedStatuses = new Set<String>();
        
        //get all closed statuses
        for(CaseStatus cs:[SELECT MasterLabel FROM CaseStatus WHERE IsClosed = true])
        {
            closedStatuses.add(cs.MasterLabel);
        }
        
        return closedStatuses;
    }
    
    public static void InsertCaseTeamMembers(Map<Id, Id> caseAccountIds, List<Case> cases)
    {
        List<CaseTeamMember> newCaseTeamMembers = new List<CaseTeamMember>();
        Map<string, Id> caseRoles = new Map<string, Id>();
        for(CaseTeamRole ctr:[SELECT Id, Name FROM CaseTeamRole])
        {
            caseRoles.put(ctr.Name, ctr.Id);
        }
        
        Map<Id,Account> accountMembers = new Map<Id,Account>([SELECT Id, a.TsaPrimary__c, a.TsaPrimary__r.IsActive, a.CS_AM__c, a.CS_AM__r.IsActive, a.CS_AM__r.LastName, a.CSM__c, a.CSM__r.IsActive, a.CSM__r.LastName, a.CSMsecondary__c, a.TSMLead__c, a.TSMsecondary__c, a.TechnicalSuccessManagerprimary__c, a.TechnicalSuccessManagerprimary__r.IsActive, a.RecordTypeId FROM Account a WHERE Id IN :caseAccountIds.values()]);
        
        for(Case c:cases)
        {
            if(c.AccountId != null && accountMembers.containsKey(c.AccountId))
            {
                Account a = accountMembers.get(c.AccountId);
                Set<Id> teamMembers = new Set<id>();
                
                //Apply to standard user types only
                if(UserInfo.getUserType() == 'Standard')
                {
                    //TSM
                    if(a.TechnicalSuccessManagerprimary__c != null && caseRoles.containsKey('TSM') && a.TechnicalSuccessManagerprimary__r.IsActive)
                    {
                        CaseTeamMember ctm = new CaseTeamMember();
                        ctm.MemberId = a.TechnicalSuccessManagerprimary__c;
                        ctm.ParentId = c.Id;
                        ctm.TeamRoleId = caseRoles.get('TSM');
                        
                        newCaseTeamMembers.add(ctm);
                        teamMembers.add(a.TechnicalSuccessManagerprimary__c);
                    }
                    
                    //TSA
                    if(a.TsaPrimary__c != null && !teamMembers.contains(a.TsaPrimary__c) && caseRoles.containsKey('TSA') && a.TsaPrimary__r.IsActive)
                    {
                        CaseTeamMember ctm = new CaseTeamMember();
                        ctm.MemberId = a.TsaPrimary__c;
                        ctm.ParentId = c.Id;
                        ctm.TeamRoleId = caseRoles.get('TSA');
                        
                        newCaseTeamMembers.add(ctm);
                        teamMembers.add(a.TsaPrimary__c);
                    }
                    
                    //CSM
                    if(a.CSM__c != null && a.CSM__r.LastName != '_Customer Service' && !teamMembers.contains(a.CSM__c) && caseRoles.containsKey('CSM') && a.CSM__r.IsActive)
                    {
                        CaseTeamMember ctm = new CaseTeamMember();
                        ctm.MemberId = a.CSM__c;
                        ctm.ParentId = c.Id;
                        ctm.TeamRoleId = caseRoles.get('CSM');
                        
                        newCaseTeamMembers.add(ctm);
                        teamMembers.add(a.CSM__c);
                    }
                    
                    //CSA
                    if(a.CS_AM__c != null && a.CS_AM__r.LastName != '_Customer Service'  && !teamMembers.contains(a.CS_AM__c) && caseRoles.containsKey('CSA') && a.CS_AM__r.IsActive)
                    {
                        CaseTeamMember ctm = new CaseTeamMember();
                        ctm.MemberId = a.CS_AM__c;
                        ctm.ParentId = c.Id;
                        ctm.TeamRoleId = caseRoles.get('CSA');
                        
                        newCaseTeamMembers.add(ctm);
                    }
                }
            }
        }
        
        
        if(!newCaseTeamMembers.isEmpty())
        {
            system.debug(newCaseTeamMembers);
            insert newCaseTeamMembers;
        }
    }
    
}