global class CaseUpdateBatch implements Database.Batchable<sObject> {
	global final String gstrQuery;
	Set<String> stRecordTypes = new Set<String>();
        
    global CaseUpdateBatch(String query)
    {
        stRecordTypes.add('01270000000LuEpAAK');
		stRecordTypes.add('01270000000MzcWAAS');
		stRecordTypes.add('01270000000LuErAAK');
		stRecordTypes.add('01270000000LuEqAAK');
        gstrQuery = query;
        system.debug('gstrQuery ==>' + gstrQuery);
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
    	return Database.getQueryLocator(gstrQuery);
    }
 
    global void execute(Database.BatchableContext BC, List<Case> scope)
    {
        Set<Id> closedCasesWithKbUsed = new Set<Id>();
		List<Case> listCasesToUpdate = new List<Case>();
		List<Case> newCases = new List<Case>();
		List<Case> CitationCases = new List<Case>();
		Map<String,Case> knownCases = new Map<String,Case>();
        Map<String,Case> noArticlesCase = new Map<String,Case>();
		Map<String,Case> ArticleCaseBridge = new Map<String,Case>();
		Map<String,String> ArticleCreatedBridge = new Map<String,String>();
		Map<Id, Case> mpCases = new Map<Id, Case>();
		// create a Map of Cases
		for (Case c : scope)
		{
			mpCases.put(c.Id, c);
			noArticlesCase.put(c.Id, c);
		}

        // Grab  a list of articles referenced in cases. Specifically those in scope
		// Get the Articles with KB ID
	    for(CaseArticle ca:[Select CaseId, KnowledgeArticleId, CreatedById from CaseArticle WHERE CaseId IN : mpCases.keySet()])
        {
            closedCasesWithKbUsed.add(ca.CaseId);
			ArticleCreatedBridge.put(ca.KnowledgeArticleId, ca.CreatedById);
			ArticleCaseBridge.put(ca.KnowledgeArticleId,mpCases.get(ca.CaseId));
			knownCases.put(ca.CaseId, mpCases.get(ca.CaseId));
			noArticlesCase.remove(ca.CaseId);
        }
		system.debug('newCases before ==> ' + newCases);
        system.debug('closedCasesWithKbUsed ==> ' + closedCasesWithKbUsed);
        // For Published Articles
		for(KnowledgeArticleVersion kav: [SELECT SourceId, CreatedById, KnowledgeArticleId FROM KnowledgeArticleVersion
										 WHERE PublishStatus='Online' AND Language = 'en_US'
                                          AND SourceId != null
                                          AND KnowledgeArticleId IN : ArticleCreatedBridge.keySet()])
		{
			// if the case article created by someone else that case is a citation case
			if(kav.CreatedById != ArticleCreatedBridge.get(kav.KnowledgeArticleId))
			{               
				CitationCases.add(ArticleCaseBridge.get(kav.KnowledgeArticleId));
			}
			// new article  => if the Knowedge base article was created from the current case (sourceid = currentCase)
			// Known article => if the Knowedge base article was created from otherCase (sourceid = null / othercase)
			if(closedCasesWithKbUsed.contains(kav.SourceId) && knownCases.containsKey(kav.SourceId))
			{
				newCases.add(knownCases.get(kav.SourceId));
				knownCases.remove(kav.SourceId);
			}
		}
		system.debug('newCases after online ==> ' + newCases);
        // For Draft Articles
	/**	for(KnowledgeArticleVersion kav: [SELECT SourceId, CreatedById, KnowledgeArticleId FROM KnowledgeArticleVersion
										 WHERE PublishStatus='Draft' AND Language = 'en_US' AND KnowledgeArticleId IN : ArticleCreatedBridge.keySet()])
		{
			if(closedCasesWithKbUsed.contains(kav.SourceId) && knownCases.get(kav.SourceId))
			{
				newCases.add(knownCases.get(kav.SourceId));
				knownCases.remove(kav.SourceId);
			}
		}**/
		system.debug('newCases after draft ==> ' + newCases);
        
        Map<String, Case> mpUpdateCases = new Map<String, Case>();
        
        if(!CitationCases.isEmpty())
        {
            for(Case c: CitationCases)
            {
                if (!mpUpdateCases.containsKey(c.Id))
                {
                    case  updateCase= new Case(Id = c.Id);
                    updateCase.Citation__c = true;
                    mpUpdateCases.put(c.Id, updateCase);
                }
            }
        }
        
        if(!newCases.isEmpty())
        {
            for(Case c: newCases)
            {
                if (!mpUpdateCases.containsKey(c.Id))
                {
                    case  updateCase= new Case(Id = c.Id);
                    updateCase.New_vs_Known__c = 'New';
                    mpUpdateCases.put(c.Id, updateCase);
                }
                else
                {
                    mpUpdateCases.get(c.Id).New_vs_Known__c = 'New';
    
                }
            }
        }
    	
        if(!knownCases.isEmpty())
        {
            for(Case c: knownCases.values())
            {
                if (!mpUpdateCases.containsKey(c.Id))
                {
                    case  updateCase= new Case(Id = c.Id);
                    updateCase.New_vs_Known__c = 'Known';
                    mpUpdateCases.put(c.Id, updateCase);
                }
                else
                {
                    mpUpdateCases.get(c.Id).New_vs_Known__c = 'Known';
    
                }
            }
        }
        
        if(!noArticlesCase.isEmpty())
        {
            for(Case c: noArticlesCase.values())
            {
                if (!mpUpdateCases.containsKey(c.Id))
                {
                    case  updateCase= new Case(Id = c.Id);
                    updateCase.New_vs_Known__c = 'N/A';
                    mpUpdateCases.put(c.Id, updateCase);
                }
                else
                {
                    mpUpdateCases.get(c.Id).New_vs_Known__c = 'N/A';
                }
            }
        }

      	for(Case objSObject : scope)
       	{
           	Case caseRecord = objSObject;
            
            // If the case has an associated article that was used then flag it
			if(closedCasesWithKbUsed.contains(caseRecord.Id))
            {
                
                if (!mpUpdateCases.containsKey(caseRecord.Id))
				{
					
					caseRecord.KB_Attached__c = true;					
					mpUpdateCases.put(caseRecord.Id, caseRecord);
				}
				else
				{
					mpUpdateCases.get(caseRecord.Id).KB_Attached__c = true;
				}
			}
        }
        
        if (mpUpdateCases.size() > 0 ) 
        {
            update mpUpdateCases.values();
        }
    }
    
    global void finish(Database.BatchableContext BC)
    {
        Last_Batch_Run_Date__c batchRunDt = Last_Batch_Run_Date__c.getall().values();
        batchRunDt.LastRunTime__c = system.now();
        update batchRunDt;
		        
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
	   		 TotalJobItems, CreatedBy.Email, ExtendedStatus
	   				 FROM AsyncApexJob WHERE Id =
	   				 :BC.getJobId()];
        
	   	// Send an email to the Apex job's submitter notifying of job completion. 
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		String[] toAddresses = new String[] {a.CreatedBy.Email};
		mail.setToAddresses(toAddresses);
		mail.setSubject('Case KB Attached Batch ' + a.Status);
		mail.setPlainTextBody('The batch Apex job processed ' 
                              + a.TotalJobItems 
                              + ' batches with '
                              + a.NumberOfErrors 
                              + ' failures.');
		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        
        
    }
}