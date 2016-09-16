trigger OpportunityBeforeInsert on Opportunity (before insert) 
{
    
    String eduOppRT = inContactBaseClass.SelectRecordTypeIDByName('Education Request', 'Opportunity');
    
        //make the sales dev = created by when Saas request
    for(Opportunity o:trigger.new)
    {
        if(o.RecordTypeId == '01270000000LrnD')
        {
            o.Sales_Developer__c = Userinfo.getUserId();
        }
        
        if(o.RecordTypeId == eduOppRT)
        {
            o.RequestDate__c = system.now();
        }
        
        if(o.StageName == '2 - Determining Problem / Impact')
        {
            o.Stage_2_Timestamp__c = system.today();
        }
        else if(o.StageName == '3 - Aligning Benefits & Value')
        {
            o.Stage_2_Timestamp__c = system.today();
            o.Stage_3_Timestamp__c = system.today();
        }
        else if(o.StageName == '4 - Confirm Value & Agreement')
        {
            o.Stage_2_Timestamp__c = system.today();
            o.Stage_3_Timestamp__c = system.today();
            o.Stage_4_Timestamp__c = system.today();
        }
        else if(o.StageName == '5 - Proposal / Negotiation')
        {
            o.Stage_2_Timestamp__c = system.today();
            o.Stage_3_Timestamp__c = system.today();
            o.Stage_4_Timestamp__c = system.today();
            o.Stage_5_Timestamp__c = system.today();
        }
        else if(o.StageName == '6 - Pending')
        {
            o.Stage_2_Timestamp__c = system.today();
            o.Stage_3_Timestamp__c = system.today();
            o.Stage_4_Timestamp__c = system.today();
            o.Stage_5_Timestamp__c = system.today();
            o.Stage_6_Timestamp__c = system.today();
        }
    }

}