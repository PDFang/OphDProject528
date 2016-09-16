@isTest()
public class TimesheetTestClass 
{
    public static testMethod void TestTimesheetExtension()
    {
        //get record type ids
        Schema.DescribeSObjectResult d = Schema.SObjectType.Project__c; 
        Map<String,Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();
        Id psChangeRequestPhase = rtMapByName.get('PS Change Request Phase').getRecordTypeId();
        Id psParentProjectSaaS = rtMapByName.get('PS Parent Project - SaaS').getRecordTypeId();
        Id psParentProjectPremise = rtMapByName.get('PS Parent Project - Premise').getRecordTypeId();
        Id psPremisePhase = rtMapByName.get('PS Project Phase Premise WFO').getRecordTypeId();
        Id psSaaSPhase = rtMapByName.get('PS Project Phase SaaS').getRecordTypeId();
                
        date startDate = system.today().toStartOfWeek();
        date endDate = startDate + 6;
        List<TimesheetDay__c> tsDays = new List<TimesheetDay__c>();
        List<Project__c> testProjects = new List<Project__c>();
        List<Asset> lstAssets = new List<Asset>();
        
        //create timesheet
        Timesheet__c ts = new Timesheet__c();
        ts.OwnerId = UserInfo.getUserId();
        ts.StartDate__c = startDate;
        ts.EndDate__c = endDate;
        ts.Status__c = 'Open';
        
        insert ts;
        
        //create timesheet days
        for(integer i=0;i<7;i++)
        {
            TimesheetDay__c td = new TimesheetDay__c();
            td.Timesheet__c = ts.Id;
            td.Date__c = startDate + i;
            
            tsDays.add(td);
        }
        
        insert tsDays;
        
        Account acct = inContactBaseClass.CreateAccount('Test Account');
		acct.CadebillAccountNo__c = 9999999;
		acct.inContact_Cluster__c = 'C6';
		insert acct;
        
        
        //create Change Request project
        Project__c p1 = new Project__c();
        p1.RecordTypeId = psChangeRequestPhase;
        p1.Summary__c = 'TEST';
        p1.OwnerId = UserInfo.getUserId();
        
        //insert p1;
        testProjects.add(p1);
        
        //Create SaaS Parent Project
        Project__c p2 = new Project__c();
        p2.RecordTypeId = psParentProjectSaaS;
        p2.Summary__c = 'SaaS Parent Project TEST';
        p2.OwnerId = UserInfo.getUserId();
        p2.PlannedStartDate__c = system.today()-5;
        
        testProjects.add(p2);
        
        //Create Premise Parent Project
        Project__c p3 = new Project__c();
        p3.RecordTypeId = psParentProjectPremise;
        p3.Summary__c = 'Premise Parent Project TEST';
        p3.OwnerId = UserInfo.getUserId();
        
        testProjects.add(p3);
        
        //Create SaaS Phase future planned start date
        Project__c p4 = new Project__c();
        p4.RecordTypeId = psSaaSPhase;
        p4.Summary__c = 'SaaS Phase TEST';
        p4.OwnerId = UserInfo.getUserId();
        p4.PlannedStartDate__c = system.today()+7;
        
        testProjects.add(p4);
        
        //Create SaaS Phase previous planned start date
        Project__c p5 = new Project__c();
        p5.RecordTypeId = psSaaSPhase;
        p5.Summary__c = 'SaaS Project Phase TEST';
        p5.OwnerId = UserInfo.getUserId();
        p5.PlannedStartDate__c = system.today()-7;
        
        testProjects.add(p5);
        
        //Create premise phase w/Project owner ID instead of OwnerId
        Project__c p6 = new Project__c();
        p6.RecordTypeId = psPremisePhase;
        p6.Summary__c = 'Premise Project Phase TEST';
        p6.ProjectOwner__c = UserInfo.getUserId();
        p5.OwnerId = UserInfo.getUserId();
        p6.PlannedStartDate__c = system.today()-7;
        
        testProjects.add(p6);
        
        insert testProjects;
        
        for(integer i=0; i<6; i++)
        {
            if(testProjects[i].Summary__c != 'TEST')
            {
                Asset ast = new Asset();
                ast.Project_Phase__c = testProjects[i].id;
                ast.Name = 'Test Asset ' + i;
                ast.Status = 'New';
                ast.Sales_Price__c = 10;
                ast.AccountId = acct.Id;
                lstAssets.add(ast);
            }
        }
        
        insert lstAssets;
        
        //initiate extension
       	PageReference tsPage = Page.Timesheet;
        test.setCurrentPage(tsPage);
        ApexPages.StandardController tsCon = new ApexPages.StandardController(ts);
        TimesheetExtension tsExt = new TimesheetExtension(tsCon);
        
        ApexPages.currentPage().getParameters().put('wlDate',tsDays[0].Id);
        ApexPages.currentPage().getParameters().put('ref','0');
        ApexPages.currentPage().getParameters().put('summ','test');
        ApexPages.currentPage().getParameters().put('recId',p1.Id);
        
        tsExt.EditDate();
        
        tsExt.DayWorkLogList[0].WorkLog.Hours_Worked__c = 3;
        tsExt.DayWorkLogList[0].selectedProduct = 'Align';
        tsExt.UpdateHoursDate();
        
        
        tsExt.SaveLogEdit();
        WorkLog__c wrklg = [select Asset__c, LogType__c from WorkLog__c where Project__c = : testProjects[0].id limit 1];
        
        system.assertEquals(null,wrklg.Asset__c);
        system.assertEquals('Align',wrklg.LogType__c);
        
        tsExt.AddRecord();
        tsExt.AddNewProject();
        
        tsExt.projectNum = [select Name from Project__c where Id =: testProjects[2].Id].Name;
        system.debug('Name ==> ' +  tsExt.projectNum);
        tsExt.changePicklist();
        
        
        tsExt.CancelLogEdit();
        
        //initiate extension
        TimesheetExtension tsExt2 = new TimesheetExtension(tsCon);
        
        tsExt2.EditDate();
        tsExt2.DayWorkLogList[1].WorkLog.Hours_Worked__c = 3;
        tsExt2.DayWorkLogList[1].selectedProduct = lstAssets[0].Id;
        Id projId = tsExt2.DayWorkLogList[1].WorkLog.Project__c;
        
        tsExt2.SaveLogEdit();
        WorkLog__c wrklg2 = [select Asset__c, LogType__c from WorkLog__c where Project__c = : projId limit 1];
        system.assertEquals(lstAssets[0].Id,wrklg2.Asset__c);
        system.assertEquals(null,wrklg2.LogType__c);
        
    }
}