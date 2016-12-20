global class PartnerOpportunityManagement {
	webService static string acceptOpportunity(id OppId)
    {
        string status;
        Shared_Opportunity__c Opportunity;
        Opportunity = [select Id, Status__c, Partner_User__c from Shared_Opportunity__c where id = :OppId];
        if (Opportunity.Status__c == 'New')
        {
            Opportunity.Status__c = 'Accept';
            //Opportunity.Partner_User__c = userinfo.getProfileId();
            status = 'Opportunity status updated.';
            update Opportunity;
        }
        else if (Opportunity.Status__c == 'Accept')
        {
            status = 'Opportunity has already been accepted.';
        }
        return status; 
    }
    
    
    
    webService static string rejectOpportunity(id OppId)
    {
        string status;
        Shared_Opportunity__c Opportunity;
        Opportunity = [select Id, Status__c, Partner_User__c from Shared_Opportunity__c where id = :OppId];
        if (Opportunity.Status__c == 'New')
        {
            Opportunity.Status__c = 'Reject';
            //Opportunity.Partner_User__c = userinfo.getProfileId();
            status = 'Opportunity status updated.';
            update Opportunity;
        }
        else if (Opportunity.Status__c == 'Reject')
        {
            status = 'Opportunity has already been accepted.';
        }
        return status; 
    }
}