@isTest
public class ArticleDraftFromCaseControllerTest {
	static testMethod void testArticleCreation()
	{
        		string caseSubject = 'Test Articles';
        		string strDesc = 'test description';
        		string strEnv = 'WFO - Discover' + '<br/>' + 'Fusion Desktop Analytics' + '<br/>' + '';
        
        		 //set default assignment rule       
                database.DMLOptions dmo = new database.DMLOptions();
                dmo.assignmentRuleHeader.useDefaultRule = true;

                Case c = new Case();
                //create test case
                c.Subject = caseSubject;
                c.EventType__c = 'Service Disruption';
                c.Product_or_Service__c = 'WFO - Discover';
                c.Status = 'New';
                c.SubProductorService__c = 'Fusion Desktop Analytics';
                c.Priority = 'P1';
                c.Description = strDesc;
        		c.setOptions(dmo);
        
        		insert c;
     			String caseId = c.id;
                System.debug('Created Case: ' + caseId);
                ApexPages.currentPage().getParameters().put('sourceId', caseId);
                ApexPages.currentPage().getParameters().put('sfdc.override', '1');
        		// Test how to artcles
		        ApexPages.KnowledgeArticleVersionStandardController howtoCtl = new ApexPages.KnowledgeArticleVersionStandardController(new How_To__kav());
                ArticleDraftFromCaseController article = new ArticleDraftFromCaseController(howtoCtl);
                System.assertEquals(caseId, howtoCtl.getSourceId());
                System.assertEquals(caseSubject, howtoCtl.getRecord().get('title'));
                System.assertEquals(strDesc, howtoCtl.getRecord().get('Objective__c'));
        		System.assertEquals(strEnv, howtoCtl.getRecord().get('Environment__c'));
        
      			// test QA
        		ApexPages.KnowledgeArticleVersionStandardController QActl = new ApexPages.KnowledgeArticleVersionStandardController(new Q_A__kav());
                new ArticleDraftFromCaseController(QActl);
                System.assertEquals(caseId, QActl.getSourceId());
                System.assertEquals(caseSubject, QActl.getRecord().get('title'));
                System.assertEquals(strDesc, QActl.getRecord().get('Question__c'));
        		System.assertEquals(strEnv, QActl.getRecord().get('Environment__c'));
        		// test Solutions
        		ApexPages.KnowledgeArticleVersionStandardController Solctl = new ApexPages.KnowledgeArticleVersionStandardController(new Solution_Article__kav());
                new ArticleDraftFromCaseController(Solctl);
                System.assertEquals(caseId, Solctl.getSourceId());
                System.assertEquals(caseSubject, Solctl.getRecord().get('title'));
                System.assertEquals(strDesc, Solctl.getRecord().get('Symptom__c'));
        		System.assertEquals(strEnv, Solctl.getRecord().get('Environment__c'));
	   
    }  
}