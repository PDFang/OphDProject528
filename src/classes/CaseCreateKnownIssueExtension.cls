public with sharing class CaseCreateKnownIssueExtension 
{
    private Case c;
    public string recordTypeName {get;set;}
    
    public Case relatedCase{get;set;}
    public Boolean createJiraBug {get;set;}
    public Boolean canCreateKnownIssue {public get; private set;}
    public Boolean success {get; set;}

    public CaseCreateKnownIssueExtension(ApexPages.StandardController controller) 
    {
        recordTypeName = ApexPages.CurrentPage().getParameters().get('recordType');
        List<string> fields = new List<string>();
        fields.Add(recordTypeName.replace(' ', '') + '__c');
        fields.Add('Priority');
        if(!Test.isRunningTest())
         {
             controller.addFields(fields);
         }

        createJiraBug = false;
        this.c = (Case)controller.getRecord();
        
        if(c.get(recordTypeName.replace(' ', '') + '__c') != null)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'This incident already has an associated ' + recordTypeName + '.'));
            return;
        }
        
        relatedCase = new Case();
        Schema.DescribeSObjectResult d = Schema.SObjectType.Case; 
        Map<String,Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();
        
        if(rtMapByName.get(recordTypeName).isAvailable())
        {
            Id knownIssueRecordType = rtMapByName.get(recordTypeName).getRecordTypeId();
            relatedCase.RecordTypeId = knownIssueRecordType;
            relatedCase.Summary__c = c.Description;
            if(string.IsBlank(relatedCase.Summary__c))
            {
                relatedCase.Summary__c = c.Summary__c;
            }
            relatedCase.Subject = c.Subject;
            relatedCase.Steps_to_Recreate__c = c.Steps_to_Recreate__c;
            relatedCase.ProductImpacted__c = c.ProductImpacted__c;
            relatedCase.PlatformsImpacted__c = c.PlatformsImpacted__c ;
            relatedCase.FoundBy__c = c.FoundBy__c ;
            relatedCase.ExistsIn__c = c.ExistsIn__c ;
            
            if(ApexPages.CurrentPage().getParameters().get('origin') != null)
            {
                relatedCase.Origin = ApexPages.CurrentPage().getParameters().get('origin');
            }
            
            canCreateKnownIssue = true;
        }
        else
        {
            canCreateKnownIssue = false;            
        }
        
        success = false;
    }
    
    
    public PageReference Save()
    {
        try
        {
            SaveCase();
        }
        catch(Exception ex)
        {
            return null;
        }
                
        //return to case page
        PageReference casePage = new PageReference('/' + c.Id);
        casePage.setRedirect(true);
    
        return casePage;
    }
    
    public void SaveCase()
    {
        system.debug(c.get(recordTypeName.replace(' ', '') + '__c'));
        if(c.get(recordTypeName.replace(' ', '') + '__c') != null)
        {
            try
            {
                update c;

                list<Case> listKnownIssues = [select Id,Broken_by_Recent_Release__c from Case where id = :c.KnownIssue__c];
                KnownIssuesImpactCalcImplementation KIImpactCalc = new KnownIssuesImpactCalcImplementation();
                KnownIssueImpactCalculationClass KICalc = new KnownIssueImpactCalculationClass(KIImpactCalc);
                KICalc.CalculateKnownIssueScore(listKnownIssues);



            }
            catch(Exception ex)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
                return;// null;
            }
            
            //return to case page
            PageReference casePage = new PageReference('/' + c.Id);
            casePage.setRedirect(true);
            success = true;
        
            return;// null;
        }
        //set default assignment rule       
        database.DMLOptions dmo = new database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        dmo.emailHeader.triggerUserEmail = true;
        
        relatedCase.setOptions(dmo);
        
        try
        {
            relatedCase.IsVisibleInSelfService = true;
            system.debug(relatedCase.TFSWorkItem__c);
            // Known Issue must be created before making a callout to JIRA as it requires Salesfore ID
            // asynchronous callout refer CaseTriggerHandler.createJiraBugForKI()
            if(createJiraBug){
                system.debug('User requested to create a JIRA bug for KI - ' + relatedCase.Id);
                CaseTriggerHandler.createJiraBug = true;
                //need to populate the Description field with concatenated
                //summary + steps to reproduce + internal notes
                relatedCase.JIRA_Description__c = getJIRADescription(relatedCase);
                relatedCase.JIRA_Summary__c = relatedCase.Subject;
            }

            insert relatedCase;

            c.put(recordTypeName.replace(' ', '') + '__c',relatedCase.Id);
            update c;

            // // Call the KNown Issue Impact Calculation Class
            list<Case> listKnownIssues = new List<case>();
            listKnownIssues.add(relatedCase);
            KnownIssuesImpactCalcImplementation KIImpactCalc = new KnownIssuesImpactCalcImplementation();
            KnownIssueImpactCalculationClass KICalc = new KnownIssueImpactCalculationClass(KIImpactCalc);
            KICalc.CalculateKnownIssueScore(listKnownIssues);
            success = true;
        }
        catch(Exception ex)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage() + ' - stack trace - ' + ex.getStackTraceString()));
        }
        
        return;// null;
    }
    
    
    public void ClearKnownIssue()
    {
        c.put(recordTypeName.replace(' ', '') + '__c',null);
    }
    
    public static string getJIRADescription(Case relatedCase){

        String description = 'Summary\n' + relatedCase.Summary__c
                + '\n\nSteps to Recreate\n' + relatedCase.Steps_to_Recreate__c
                + '\n\nInternal Notes\n' + relatedCase.InternalNotes__c;

        return description;

    }

}