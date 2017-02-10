/**     ****** History Of Chnages *****
    User Story 14922:48155 - Help Desk Surveys Triggered on Case Closure 
        ** Added Recordtype Help Desk 
        ** Call Email service (CaseSendSurvey)
        ** Change Date - 12/22/2015
**/
trigger CaseBeforeUpdate on Case (before update)
{
    Schema.DescribeSObjectResult d = Schema.SObjectType.Case;
    Map<String,Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();
    SiteConfiguration__c siteConfig = new SiteConfiguration__c();

    siteConfig = SiteConfiguration__c.getInstance(inContactBaseClass.OrgId15Digit);

    //Get Event record type id
    Id eventRecordType = rtMapByName.get('Event').getRecordTypeId();
    Id maintenanceRecordType = rtMapByName.get('Maintenance Notification').getRecordTypeId();
    Id knownIssueRecordType = rtMapByName.get('Known Issue').getRecordTypeId();
    Id incidentRecordType = rtMapByName.get('Incident').getRecordTypeId();
    Id problemRecordType = rtMapByName.get('Problem').getRecordTypeId();
    Id incidentUptivityRecordType = rtMapByName.get('Incident - Premise').getRecordTypeId();
    Id serviceRequestRecordType = rtMapByName.get('Service Request').getRecordTypeId();
    Id workOrderRecordType = rtMapByName.get('Work Orders').getRecordTypeId();
    Id workOrderUptivityRecordType = rtMapByName.get('Work Orders - Premise').getRecordTypeId();
    Id helpDeskRCTypeId = rtMapByName.get('Help Desk').getRecordTypeId(); // Added the HelpDesk RecordType - Arnab
    Map<Id,String> eventCasePriorities = new Map<Id,String>();
    Map<ID,SET<ID>> queueUsers = new Map<ID,SET<ID>>();
    //Get Maps for the Queue Managers and Queues
    List<Queue_Manager__c> queueManagersList = new List<Queue_Manager__c>([Select Name, Manager__c FROM Queue_Manager__c]);
    Map<String,ID> queueManagers = new Map<String,ID>();
    list<String> listPlatforms = new list<string>();
    //Loop through all the queue managers to create a map object
    for(Queue_Manager__c qm : queueManagersList)
    {
        queueManagers.put(qm.Name, qm.Manager__c);
    }

    //Loop through all the cases to get all the case owners and assignTo users in the update to 
    // send to the Assignment Validation
    Set<String> closedStatuses = new Set<String>();
    Set<Id> closedTechSupportCaseIds = new Set<ID>();
    List<Id> closedCasesForEntitlements = new List<ID>();
    Set<Id> affectedQueueIDs = new Set<ID>();
    Set<Id> affectedUserIDs = new Set<ID>();
    Set<Id> accountIds = new Set<ID>();
    Set<Id> parentCaseIds = new Set<Id>();
    Set<Id> attachedToKnownIssue = new Set<Id>();
    Set<Id> closedCaseHD = new Set<Id>();

    Id[] itCaseIds = new Id[]{};

    //get all closed statuses
    for(CaseStatus cs:[SELECT MasterLabel FROM CaseStatus WHERE IsClosed = true])
    {
        closedStatuses.add(cs.MasterLabel);
    }

    for(Case c : trigger.new)
    {
        affectedQueueIDs.add(c.OwnerID);
        //get all the affect User IDs
        if(c.Assigned_To__c != null)
            affectedUserIDs.add(c.Assigned_To__c);
        if(!accountIds.contains(c.AccountId))
        {
            accountIds.add(c.AccountId);
        }

        //get parent cases
        if(c.ParentId != null) parentCaseIds.add(c.ParentId);
    }

    if(!parentCaseIds.isEmpty())
    {
        for(Case event:[SELECT Id, Priority FROM Case WHERE Id IN :parentCaseIds AND RecordTypeId = :eventRecordType])
        {
            eventCasePriorities.put(event.Id,event.Priority);
        }
    }
    //Get all groups/queues, with all the group members (which can be either a userid or a groupid),
    // from the database that are a case-queue
    Map<ID,Group> allQueues = new Map<ID,Group>([Select g.ID, g.Name, (Select UserOrGroupId From GroupMembers) from Group g Where g.ID IN : affectedQueueIDs ]);

    //get all resell accounts where cases were modified to exclude them from surveys EXCEPT VERIZON
    Map<ID,Account> excludedResellerAccounts = new Map<Id,Account>([SELECT ID FROM Account WHERE (RecordType.Name = 'Resell Customers' OR RecordType.Name = 'Resell Partner') AND Billing_Group__c <> 'Verizon' and Id IN:accountIds]);

    if(!CaseAssignmentClass.isTest)
    {
        system.debug('Allqueue*************'+allQueues);
        //create a map of affected queues with all their users
        queueUsers = CaseAssignmentClass.GetValidQueueUsers(allQueues, affectedUserIDs);
        system.debug('queueUsers*************'+queueUsers);
    }

    //Loop through all the cases
    for(integer i=0; i < trigger.new.size(); i++)
    {
        Case co = trigger.old[i];
        Case cn = trigger.new[i];
        boolean newlyClosed = (!closedStatuses.contains(co.Status) && closedStatuses.contains(cn.Status));
        boolean closed = closedStatuses.contains(cn.Status);
        boolean resolved = cn.Status == 'Resolved';

        if(co.StatusDetails__c != cn.StatusDetails__c)
        {
            cn.StatusDetailsLastModifiedDateTime__c = system.now();
        }

        if(!co.FirstResponseViolated__c && cn.FirstResponseViolated__c)
        {
            cn.FirstResponseViolationQueue__c = allqueues.get(co.OwnerId).Name;
        }

        if(!co.SLAViolated__c && cn.SLAViolated__c)
        {
            cn.SLAViolationQueue__c =   allqueues.get(co.OwnerId).Name;
        }

        if(co.NOC__c != cn.NOC__c && cn.Status != 'Closed')
        {
            cn.Status = 'Acknowledged';
        }

        //find cases assigned to IT for following
        if(co.OwnerId != cn.OwnerId && cn.OwnerId == '00G70000001ciRp' /*IT Development Queue*/)
        {
            itCaseIds.Add(cn.Id);
        }

        //Set Case Priority
        if(cn.RecordTypeId == incidentRecordType || cn.RecordTypeId == problemRecordType)
        {
            if(!eventCasePriorities.isEmpty() && eventCasePriorities.containsKey(cn.ParentId))
            {
                cn.Priority = eventCasePriorities.get(cn.ParentId);
            }
            else
            {
                CaseAssignmentClass.setCasePriority(cn,true);
            }
        }


        if(!System.isFuture() && cn.SystemClosed__c != true && !excludedResellerAccounts.containsKey(cn.AccountId) && !system.isBatch())//batch soql does not accept @future callouts
        {
            if(newlyClosed && cn.RecordTypeId == helpDeskRCTypeId){ // Get Closed cases for HelpDesk - Arnab (The man)
                closedTechSupportCaseIds.add(cn.Id);
            }

            if(newlyClosed && Userinfo.getLastName() == '_castiron')
            {
                if(cn.Disposition__c == null)
                {
                    cn.Disposition__c = 'Customer Closed';
                }
                if(cn.Reason == null)
                {
                    cn.Reason = 'Customer Closed';
                }
                if(cn.Issue_Product__c == null)
                {
                    cn.Issue_Product__c = 'Customer Closed';
                }
            }
        }

        if(cn.RecordTypeId != eventRecordType)
        {
            //Check if Owner has changed
            if(co.OwnerId != cn.OwnerId  && co.OwnerId != UserInfo.getUserId() && cn.IsClosed == False)
            {
                //Set Escalation based on Priority
                if(cn.Priority == 'P1' || cn.Priority == 'P2')
                    cn.Escalation_Date_Time__c = System.now().addMinutes(10);
                else
                        cn.Escalation_Date_Time__c = System.now().addMinutes(60);

                //Remove any assignment when the queue changes
                if(co.Assigned_To__c == cn.Assigned_To__c)
                {
                    cn.Assigned_To__c = null;
                }

                //change the case status to Transferred if the owner changes.
                if(co.Status == 'New')
                {
                    if(cn.RecordTypeId != '01270000000MHOw')//Corp IT
                    {
                        if(cn.RecordTypeId == incidentRecordType && cn.KnownIssue__c != NULL)
                        {
                            cn.Status = 'Assigned To Known Issue';
                            cn.Disposition__c = 'Assigned To Known Issue';
                            attachedToKnownIssue.add(cn.KnownIssue__c);
                        }
                        else
                        {
                            cn.Status = 'Auto-Assigned';
                        }
                    }
                }
                else
                {
                    cn.Acknowledge_By__c = System.now().addHours(2);
                    cn.Transferred_By__c = UserInfo.getUserId();

                    if(cn.RecordTypeId != '01270000000MHOw' && cn.KnownIssue__c == NULL)//Corp IT
                    {
                        cn.Status = 'Transferred';
                    }
                    else if(cn.KnownIssue__c != NULL && cn.RecordTypeId == incidentRecordType)
                    {
                        cn.Status = 'Assigned To Known Issue';
                        cn.Disposition__c = 'Assigned To Known Issue';
                        attachedToKnownIssue.add(cn.KnownIssue__c);
                    }
                }

            }
            else
            {
                if(queueUsers.containsKey(cn.OwnerID))
                {
                    if(cn.Assigned_To__c != null && co.Assigned_To__c != cn.Assigned_To__c && cn.IsClosed == False)
                    {
                        if(queueUsers.get(cn.OwnerID).contains(cn.Assigned_To__c))
                        {
                            if(cn.RecordTypeId != '01270000000MHOw' && cn.RecordTypeId != eventRecordType && cn.KnownIssue__c == NULL)//Corp IT
                            {
                                //if the current user is the assigned user then acknowledged
                                if(cn.Assigned_To__c == UserInfo.getUserId())
                                    cn.Status = 'Acknowledged';
                                else
                                        cn.Status = 'Assigned';
                            }

                        }
                        else
                        {
                            cn.AddError('Assigned To user is not assigned to the case owner queue.');
                        }
                    }
                }
                else
                {
                    if(!CaseAssignmentClass.isTest)
                    {
                        cn.AddError('Only a Queue can be the owner of a case.');
                    }
                }

                if(cn.KnownIssue__c != NULL && cn.RecordTypeId == incidentRecordType && cn.Status != 'Closed')
                {
                    cn.Status = 'Assigned To Known Issue';
                    cn.Disposition__c = 'Assigned To Known Issue';
                    attachedToKnownIssue.add(cn.KnownIssue__c);
                }
                else if(co.KnownIssue__c != NULL && cn.KnownIssue__c == NULL)
                {
                    /*/set default assignment rule
                    database.DMLOptions dmo = new database.DMLOptions();
                    dmo.assignmentRuleHeader.useDefaultRule = true;

                    cn.setOptions(dmo);*/
                    cn.Status = 'Transferred';
                }

                //Check if Priority has increased to a P1 or P2 set escalation times based on priority
                if((co.Priority == 'P3' || co.Priority == 'P4') && (cn.Priority == 'P1' || cn.Priority == 'P2'))
                    cn.Escalation_Date_Time__c = System.now().addMinutes(10);
                else if((co.Priority == 'P1' || co.Priority == 'P2') && (cn.Priority == 'P3' || cn.Priority == 'P4'))
                    cn.Escalation_Date_Time__c = System.now().addMinutes(60);
            }
        }
        else  if(cn.RecordTypeId == eventRecordType)
        {
            if(siteConfig.AutoEventEmails__c && !cn.IsClosed)
            {
                //RUN FOR EVENTS. Initial communication
                if((cn.Priority == 'P1' || cn.Priority == 'P2') && cn.Status != 'Resolved')
                {
                    if(cn.EventConfirmedDateTime__c != null && !cn.EventEmailSent__c && !cn.InternalEvent__c)
                    {
                        NotificationHelperClass.NewEventEmailAsync(cn.Id, null);
                        cn.EventEmailSent__c = true;
                    }
                    else if (cn.EventEmailSent__c && cn.PlatformsImpacted__c != co.PlatformsImpacted__c && cn.EventConfirmedDateTime__c != null && !cn.InternalEvent__c)
                    {
                        for(string s : cn.PlatformsImpacted__c.split(';'))
                        {
                            if(!co.PlatformsImpacted__c.contains(s))
                            {
                                listPlatforms.add(s);
                            }
                        }
                        if(listPlatforms.size() > 0)
                        {
                            system.debug('test lstPlatforms CaseBeforeUpdate => ' + listPlatforms);
                            NotificationHelperClass.NewEventEmailAsync(cn.Id, listPlatforms);
                        }
                    }
                }

            }

            Set<string> eventResolvedPriorities = new Set<string>();
            if(!string.isBlank(siteConfig.EventResolvedPriorities__c))
            {
            	eventResolvedPriorities = new Set<string>(siteConfig.EventResolvedPriorities__c.split('\\;'));
            }

            if(siteConfig.EventResolvedEmails__c && cn.Status == 'Resolved' && !cn.EventResolvedEmailRequested__c && (eventResolvedPriorities.contains(cn.Priority) || cn.SendNotificationEmail__c) && !cn.InternalEvent__c)
            {
                NotificationHelperClass.ResolvedEventEmail(cn.Id);
                cn.EventResolvedEmailRequested__c = true;
                cn.SendNotificationEmail__c = false;
            }
        }

        //maintenance time zone conversion
        if(cn.RecordTypeId == maintenanceRecordType && cn.TimeZone__c == 'UTC/GMT')
        {
            if(co.EventStartDateTime__c != cn.EventStartDateTime__c)
            {
                datetime sd = cn.EventStartDateTime__c;
                cn.EventStartDateTime__c = datetime.newInstanceGmt(sd.year(),sd.month(),sd.day(),sd.hour(),sd.minute(),sd.second());
            }
            if(co.EventEndDateTime__c != cn.EventEndDateTime__c)
            {
                datetime ed = cn.EventEndDateTime__c;
                cn.EventEndDateTime__c = datetime.newInstanceGmt(ed.year(),ed.month(),ed.day(),ed.hour(),ed.minute(),ed.second());
            }
        }

        //get all newly closed cases for sla Entitlements
        if((!closedStatuses.contains(co.Status) && co.Status != 'Resolved') && (closed || resolved) && (cn.RecordTypeId == incidentRecordType || cn.RecordTypeId == incidentUptivityRecordType))
        {
            closedCasesForEntitlements.add(cn.Id);
            cn.EntitlementStatus__c = 'Closed';
        }


        //set resolved date
        if((co.Status != 'Resolved' && resolved) || (!closedStatuses.contains(co.Status) && closed && cn.ResolvedDate__c == null))
        {
            cn.ResolvedDate__c = system.now();
            cn.ResolvedBy__c = Userinfo.getUserId();
        }

        //remove resolved date
        if((!resolved && !closed && cn.ResolvedDate__c != NULL))
        {
            cn.ResolvedDate__c = NULL;
            cn.ResolvedBy__c = NULL;
            cn.EntitlementStatus__c = 'Reopened';
        }

    }

    //update CaseOwnership
    /* SFDC test begin */
    CaseOwnershipClass.updateCaseOwnerShip(Trigger.new,allqueues);
    /*SFDC test ends */


    if(!System.isFuture() && !system.isBatch())
    {
        System.debug('closedTechSupportCaseIds ==>' + closedTechSupportCaseIds);

        //if there are closed tech support cases send survey
        if(!closedTechSupportCaseIds.isEmpty())
        {
            CaseSendSurvey.TechSupportSurveyMain(closedTechSupportCaseIds);
        }
    }


    if(!closedCasesForEntitlements.isEmpty())
    {
        //close out any remaining first response milestones first.
        CaseAssignmentClass.CompleteMilestone(closedCasesForEntitlements, 'First Response', system.now());
        CaseAssignmentClass.CompleteMilestone(closedCasesForEntitlements, 'Status Update', system.now());
        CaseAssignmentClass.CompleteMilestone(closedCasesForEntitlements, 'SLA', system.now());
    }

    if(!itCaseIds.isEmpty())
    {
        ChatterUpdates.ChatterFollowITDevelopment(itCaseIds);
    }

    if(!System.isFuture() && !attachedToKnownIssue.isEmpty() && !system.isBatch()){
        CaseAssignmentClass.KnownIssueClusterCheck(attachedToKnownIssue);
    }
}