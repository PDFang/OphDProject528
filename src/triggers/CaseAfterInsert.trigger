trigger CaseAfterInsert on Case (after insert, after update) 
{
    if(TriggerHandler.isBypassed('CaseTriggerHandler')){
        system.debug('By passed CaseAfterInsert trigger');
        return;
    }
    new CaseTriggerHandler().run();

    if(CaseTriggerHandler.callActionHub){
        actionHub.InternalAdapter ia=new actionhub.InternalAdapter();
        ia.acceptEventData(trigger.new,trigger.old,'Salesforce');
    }


    List<CaseComment> comments = new List<CaseComment>();
    Map<Id,String> eventCaseIds = new Map<Id,String>();
    Map<Id, Id> caseAccountIds = new Map<Id,Id>();
    Case[] autoEventCases = new Case[]{};
    Id techSupportQueueId;
    // get tech support queue
    list<Group> grpList = new list<Group>([select Id from Group where developerName = 'TechSupportQueue' and Type = 'Queue' Limit 1]);
    if(grpList.size() > 0){
        techSupportQueueId = grpList[0].Id;
    }
    Schema.DescribeSObjectResult d = Schema.SObjectType.Case;
    Map<String,Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();

    Id eventRecType = rtMapByName.get('Event').getRecordTypeId();
    Id incidentRecType = rtMapByName.get('Incident').getRecordTypeId();

    for(integer i=0;i<trigger.new.size();i++)
    {
        Case c = trigger.new[i];
        Case oldCase;
        system.debug('owner########'+ c.OwnerId);

        if(trigger.isInsert)
        {

            if(c.AccountId != null)
            {
                caseAccountIds.put(c.Id, c.AccountId);
            }
            oldCase = trigger.new[i];

            /*/check for recurring cases to for auto event creation
            if(string.isNotBlank(c.X3rd_Party_Vendor_or_Partner__c) && (string.isNotBlank(c.Carrier__c) || string.isNotBlank(c.PartnerVendor__c) || string.isNotBlank(c.CarrierandSwitchType__c)))
            {
                autoEventCases = [SELECT X3rd_Party_Vendor_or_Partner__c, Carrier__c, PartnerVendor__c, CarrierandSwitchType__c FROM Case WHERE CreatedDate >= :system.now().addHours(-4) AND (CarrierandSwitchType__c = :c.CarrierandSwitchType__c OR PartnerVendor__c = :c.PartnerVendor__c OR Carrier__c = :c.Carrier__c) AND RecordType.Name = 'Incident' LIMIT 4];

            }*/
        }
        else
        {
            oldCase = trigger.old[i];
        }

        if(c.PlatformsImpacted__c != NULL && c.RecordTypeId == eventRecType && c.EventConfirmedDateTime__c == null && c.Status == 'Confirmed' && ((trigger.isInsert) || (oldCase.Status != 'Confirmed' && trigger.isUpdate) || (oldCase.PlatformsImpacted__c == NULL)))
        {
            system.debug('inside If loop');
            String[] platforms = c.PlatformsImpacted__c.split(';');
            String internalDeclare = '';


            if(c.InternalEvent__c)
            {
                internalDeclare = 'Internal';
            }
            else
            {
                internalDeclare = 'External';
            }


            String bodyString = 'The inContact Network Operations Center identified a service degrading issue affecting: ';
            bodyString = bodyString + '\r\n \r\n';

            for(String s:platforms)
            {
                bodyString = bodyString + s + '\r\n';
            }

            bodyString = bodyString + '\r\nThe issue involves the following product: ';
            bodyString = bodyString + '\r\n\r\n' + c.ProductImpacted__c + '\r\n \r\nTechnicians and engineers are working to correct the issue at this time.';
            bodyString = bodyString + '\r\n\r\n' + 'Customers may experience the following: ' + c.CustomersMayExperienceTheFollowing__c;

            CaseComment cc = new CaseComment();

            if(c.Priority == 'P3' || c.Priority == 'P4')
            {
                cc.IsPublished = true;
            }
            else
            {
                cc.IsPublished = false;
            }

            cc.ParentId = c.Id;
            cc.CommentBody = bodyString;

            comments.add(cc);

            String urlString = URL.getSalesforceBaseUrl().toExternalForm();
            urlString = urlString + '/';

            bodyString = c.Priority + ' ' + internalDeclare + ' Event ' + c.CaseNumber + ' has been created. ' + urlString + c.Id + '\r\n\r\n' + bodyString;
            bodyString = bodyString.left(1000);

            //add events for auto chatter following
            eventCaseIds.put(c.Id,bodyString);
            system.debug('comments########'+comments);

        }else if(c.RecordTypeId == incidentRecType && (c.SLA_Halfway__c && (trigger.isInsert || (trigger.isUpdate && oldCase.SLA_Halfway__c != c.SLA_Halfway__c))
                 || (c.OwnerId == techSupportQueueId && (trigger.isInsert || (trigger.isUpdate && oldCase.OwnerId != c.OwnerId))))){
            CaseComment cc = new CaseComment();
            cc.ParentId = c.Id;
            cc.CommentBody = Label.AdvancedTechSupportCaseComment;
            cc.IsPublished = true;
            comments.add(cc);
        }
    }

    if(!comments.IsEmpty())
    {
        CaseAssignmentClass.isTest = true;
        insert comments;
        system.debug('inside iscommentscomments########'+comments);
    }

    if(!eventCaseIds.IsEmpty())
    {
        // ChatterUpdates.ChatterFollowEvents(eventCaseIds);
    }

    //build case team
    if(!caseAccountIds.isEmpty())
    {
        CaseAssignmentClass.InsertCaseTeamMembers(caseAccountIds, trigger.new);
    }

    
}