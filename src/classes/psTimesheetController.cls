public class psTimesheetController {

    public psTimesheetController() {}

    @RemoteAction       // Get Phase Allocations Method
    public static String getPhaseAllocationsMethod() {
        String uId = UserInfo.getUserId();
        List<Project_Asset_Allocation__c> queryRecords = [Select Id, Name, Project__r.Id, Project__r.Name, Project__r.Summary__c,
                                                                Project__r.Account__r.Id, Project__r.Account__r.Name, Asset__r.Name
                                                          From Project_Asset_Allocation__c
                                                          Where (Project__r.ClosedDate__c = null OR Project__r.ClosedDate__c = THIS_QUARTER)
                                                                AND Assigned_User__c = :uId
                                                          Order By Project__r.Account__r.Name, Project__r.Name, Name ASC Limit 1000];
        return JSON.serialize(queryRecords);
    }

    @RemoteAction       // Get ATO Project Method
    public static String getATOProjectMethod() {
        List<Project__c> queryATO = [Select Id From Project__c Where Summary__c = 'PS ATO/Holiday Hours' Limit 1];
        String atoId = '';
        if (queryATO.size() > 0) {
            Project__c atoProj = queryATO.get(0);
            atoId = atoProj.Id;
        }
        return atoId;
    }

    @RemoteAction       // Get PreSale Projects Method
    public static String getPreSalesMethod() {
        String uId = UserInfo.getUserId();
        String title = '';
        List<User> userList = [Select Title From User Where Id = :uId Limit 1];
        if (userList.size() > 0) {
            User users = userList.get(0);
            title = users.Title;
        }
        Integer titleFound = title.indexOf('Project Manager');

        if (titleFound > -1) {
            List<Project__c> queryPreSales = [Select Id, Name, Summary__c, Account__r.Id, Account__r.Name
                                              From Project__c
                                              Where (ClosedDate__c = null OR ClosedDate__c = THIS_QUARTER)
                                                    AND ProjectManager__c = :uId
                                                    AND Status__c IN('0 - PreSale','1 - Open')
                                              Order By Account__r.Name, Name, Name ASC Limit 50];
            return JSON.serialize(queryPreSales);
        } else {
            List<Project__c> queryPreSales = [Select Id, Name, Summary__c, Account__r.Id, Account__r.Name
                                              From Project__c
                                              Where (ClosedDate__c = null OR ClosedDate__c = THIS_QUARTER)
                                                    AND ImplementationConsultant__c = :uId
                                                    AND Status__c = '0 - PreSale'
                                              Order By Account__r.Name, Name, Name ASC Limit 50];
            return JSON.serialize(queryPreSales);
        }
    }


    @RemoteAction       // Get Cases Method
    public static String getCasesMethod() {
        String uId = UserInfo.getUserId();
        List<Case> queryCases1 = [Select Id, CaseNumber, Subject, Account.Id, Account.Name
                                 From Case
                                 Where IsClosed = false
                                    AND Assigned_To__c = :uId 
                                 	AND RecordType__c != 'Contract Billing Audit'
                                 Order By Account.Name, CaseNumber ASC Limit 100];
        
        List<Case> queryCases2 = [Select Id, CaseNumber, Subject, Account.Id, Account.Name
                                 From Case
                                 Where IsClosed = false
                                 	AND Id IN (Select WorkIt2__Case__c From WorkIt2__Timing__c Where OwnerId = :uId)  
                                 Order By Account.Name, CaseNumber ASC Limit 100];
        
        List<Case> queryCases3 = new List<Case>();
        						 queryCases3.addAll(queryCases1);
        						 queryCases3.addAll(queryCases2);
                                        
        return JSON.serialize(queryCases3);
    }


    @RemoteAction       // Get Risks Method
    public static String getRisksMethod() {
        String uId = UserInfo.getUserId();
        List<Issues__c> queryRisks = [Select Id, Name, Escalation_Subject__c, Account__r.Id, Account__r.Name
                                          From Issues__c
                                          Where (Status__c != 'Closed' OR (Status__c = 'Closed' AND Escalation_Close_Date__c = THIS_QUARTER))
                                                AND Owner__c = :uId
                                          Order By Account__r.Name, Name ASC Limit 50];
        return JSON.serialize(queryRisks);
    }

    @RemoteAction       // Get Accounts for TAMs Method
    public static String getTamAccountsMethod() {
        String uId = UserInfo.getUserId();
        List<Account> queryAccounts = [Select Id, Name, CadebillAccountNo__c
                                       From Account
                                       Where (TechnicalSuccessManagerprimary__c = :uId
                                                OR TsaSecondary__c = :uId)
                                       		AND CG_Disconnect_Date__c = null 
                                       Order By Name ASC Limit 50];
        return JSON.serialize(queryAccounts);
    }


    @RemoteAction
    public static String getNewRecordsMethod(String searchTerm, String objectType) {
        If (objectType == 'Project') {
            String newSearchText = searchTerm + '%';
            List<Project__c> queryNewProjects = [ Select Id, Name, Summary__c, Account__r.Name, Account__r.Id
                                                 From Project__c
                                                 Where Name LIKE :newSearchText
                                                 Order By Name DESC Limit 50];
            return JSON.serialize(queryNewProjects);
        } else if (objectType == 'Case') {
            String newSearchText = '%' + searchTerm + '%';
            List<Case> queryNewCases = [ Select Id, Account.Name, Account.Id, CaseNumber, Subject
                                                 From Case
                                                 Where CaseNumber LIKE :newSearchText
                                                 Order By CaseNumber DESC Limit 50];
            return JSON.serialize(queryNewCases);
        } else if (objectType == 'Risk') {
            String newSearchText = searchTerm + '%';
            List<Issues__c> queryNewRisks = [Select Id, Name, Escalation_Subject__c, Account__r.Id, Account__r.Name
                                             From Issues__c
                                             Where (Status__c != 'Closed' OR (Status__c = 'Closed' AND Escalation_Close_Date__c = THIS_QUARTER))
                                                AND Account__r.Name LIKE :newSearchText
                                             Order By Account__r.Name, Name ASC Limit 50];
                        return JSON.serialize(queryNewRisks);
        } else if (objectType == 'Account') {
            String junc = searchTerm.substring(0,1);
            If (junc == '#') {
                integer strLen = searchTerm.length();
                String newSearchText = searchTerm.substring(1,strLen);
                newSearchText = newSearchText + '%';
                List<Account> queryAccounts = [Select Id, Name, CadebillAccountNo__c
                                               From Account
                                               Where CadebillAccountNoText__c LIKE :newSearchText
                                               Order By Name ASC Limit 50];
                return JSON.serialize(queryAccounts);
            } else {
                String newSearchText = searchTerm + '%';
                List<Account> queryAccounts = [Select Id, Name, CadebillAccountNo__c
                                               From Account
                                               Where Name LIKE :newSearchText
                                               Order By Name ASC Limit 50];
                return JSON.serialize(queryAccounts);
            }
        }
        return null;
    }

    @RemoteAction
    public static String getAssetAllocations(String projId) {
        List<Project_Asset_Allocation__c> queryAllocations = [ Select Id, Name, Project__r.Id, Project__r.Name, Project__r.Summary__c,
                                                                                Project__r.Account__r.Id, Project__r.Account__r.Name, Asset__r.Name
                                                               From Project_Asset_Allocation__c
                                                               Where Project__r.Id = :projId
                                                               Order By Name ASC Limit 50];
        return JSON.serialize(queryAllocations);
    }

    @RemoteAction
    public static String queryTimesheets(integer yr, integer mo, integer dy) {
        String userId = UserInfo.getUserId();
        DateTime beginTime = DateTime.newInstance(yr, mo, dy, 00, 00, 00);
        DateTime endTime = beginTime.addMinutes(10080);

        List<WorkIt2__Time_Entry__c> timeSheets = [Select Id, Name, Proactive__c, WorkIt2__Heartbeat__c, WorkIt2__Time_In_Hours__c, WorkIt2__Comment__c,
                                                   WorkIt2__Session_Type__r.Name, WorkIt2__Timing__r.Id,
                                                   WorkIt2__Timing__r.Project__r.Id,
                                                   WorkIt2__Timing__r.Project__r.Name,
                                                   WorkIt2__Timing__r.Project__r.Summary__c,
                                                   WorkIt2__Timing__r.Project__r.Account__r.Id,
                                                   WorkIt2__Timing__r.Project__r.Account__r.Name,
                                                   WorkIt2__Timing__r.Project_Asset_Allocation__r.Id,
                                                   WorkIt2__Timing__r.Project_Asset_Allocation__r.Name,
                                                   WorkIt2__Timing__r.Project_Asset_Allocation__r.Project__r.Id,
                                                   WorkIt2__Timing__r.Project_Asset_Allocation__r.Project__r.Name,
                                                   WorkIt2__Timing__r.Project_Asset_Allocation__r.Project__r.Summary__c,
                                                   WorkIt2__Timing__r.Project_Asset_Allocation__r.Asset__r.Name,
                                                   WorkIt2__Timing__r.Project_Asset_Allocation__r.Asset__r.Account.Id,
                                                   WorkIt2__Timing__r.Project_Asset_Allocation__r.Asset__r.Account.Name,
                                                   WorkIt2__Timing__r.WorkIt2__Case__r.Id,
                                                   WorkIt2__Timing__r.WorkIt2__Case__r.CaseNumber,
                                                   WorkIt2__Timing__r.WorkIt2__Case__r.Account.Id,
                                                   WorkIt2__Timing__r.WorkIt2__Case__r.Account.Name,
                                                   WorkIt2__Timing__r.Risk_Escalation__r.Id,
                                                   WorkIt2__Timing__r.Risk_Escalation__r.Name,
                                                   WorkIt2__Timing__r.Risk_Escalation__r.Escalation_Subject__c,
                                                   WorkIt2__Timing__r.Risk_Escalation__r.Account__r.Id,
                                                   WorkIt2__Timing__r.Risk_Escalation__r.Account__r.Name,
                                                   WorkIt2__Timing__r.Account__r.Id,
                                                   WorkIt2__Timing__r.Account__r.Name
                                                   From WorkIt2__Time_Entry__c
                                                   Where WorkIt2__Timing__r.OwnerId = :userId
                                                                AND WorkIt2__Start__c < :endTime
                                                                AND WorkIt2__Start__c >= :beginTime
                                                   Limit 1000];
        return JSON.serialize(timeSheets);
    }

    @RemoteAction
    public static String submitTime(String objectType, String objectId, String accountId, String dispo, integer loggedMinutes, integer yr, integer mo, integer dy, integer hr, integer mn, integer sc, integer proactive, string comments) {
        String userId = UserInfo.getUserId();
        String timeSheetId = '';
        String defaultSession = '';
        String objectName = '';

        if (objectType == 'project') {

            defaultSession = 'a4d39000000LODRAA4'; // Implementation
            List<WorkIt2__Timing__c> timeSheetList = [Select Id From WorkIt2__Timing__c Where Project_Asset_Allocation__r.Id = :objectId AND Owner.Id = :userId Limit 1];
            if (timeSheetList.size() > 0) {
                WorkIt2__Timing__c timeSheets = timeSheetList.get(0);
                timeSheetId = timeSheets.Id;
            } else {
                WorkIt2__Timing__c timeSheet = new WorkIt2__Timing__c();
                timeSheet.Project_Asset_Allocation__c = objectId;
                insert timeSheet;
                timeSheetId = timeSheet.Id;
            }
            String AllocationName = '';
            List<Project_Asset_Allocation__c> Allocations  = [Select Name, Project__r.Name From Project_Asset_Allocation__c Where Id = :objectId Limit 1];
            if (Allocations.size() > 0) {
                Project_Asset_Allocation__c Allocation = Allocations.get(0);
                AllocationName = Allocation.Name;
                objectName = Allocation.Project__r.Name;
                }
            objectName  = objectName + ' - ' + AllocationName;

        } else if (objectType == 'case') {

            defaultSession = 'a4d39000000HcVNAA0'; // Research
            List<WorkIt2__Timing__c> timeSheetList = [Select Id From WorkIt2__Timing__c Where WorkIt2__Case__r.Id = :objectId AND Owner.Id = :userId Limit 1];
            if (timeSheetList.size() > 0) {
                WorkIt2__Timing__c timeSheets = timeSheetList.get(0);
                timeSheetId = timeSheets.Id;
            } else {
                WorkIt2__Timing__c timeSheet = new WorkIt2__Timing__c();
                timeSheet.WorkIt2__Case__c = objectId;
                insert timeSheet;
                timeSheetId = timeSheet.Id;
            }
            List<Case> Cases = [Select CaseNumber From Case Where Id = :objectId Limit 1];
            if (Cases.size() > 0) {
                Case firstCase = Cases.get(0);
                objectName = firstCase.CaseNumber;
            }

        } else if (objectType == 'presale') {

            defaultSession = 'a4d39000000LOurAAG'; // Pre-Sale
            List<WorkIt2__Timing__c> timeSheetList = [Select Id From WorkIt2__Timing__c Where Project__r.Id = :objectId AND Owner.Id = :userId Limit 1];
            if (timeSheetList.size() > 0) {
                WorkIt2__Timing__c timeSheets = timeSheetList.get(0);
                timeSheetId = timeSheets.Id;
            } else {
                WorkIt2__Timing__c timeSheet = new WorkIt2__Timing__c();
                timeSheet.Project__c = objectId;
                insert timeSheet;
                timeSheetId = timeSheet.Id;
            }
            List<Project__c> Projects = [Select Name From Project__c Where Id = :objectId Limit 1];
            if (Projects.size() > 0) {
                Project__c proj = Projects.get(0);
                objectName = proj.Name;
            }

        } else if (objectType == 'risk') {

            defaultSession = 'a4d39000000LOGuAAO'; // Managing Rsk/Esc
            List<WorkIt2__Timing__c> timeSheetList = [Select Id From WorkIt2__Timing__c Where Risk_Escalation__r.Id = :objectId AND Owner.Id = :userId Limit 1];
            if (timeSheetList.size() > 0) {
                WorkIt2__Timing__c timeSheets = timeSheetList.get(0);
                timeSheetId = timeSheets.Id;
            } else {
                WorkIt2__Timing__c timeSheet = new WorkIt2__Timing__c();
                timeSheet.Risk_Escalation__c = objectId;
                insert timeSheet;
                timeSheetId = timeSheet.Id;
            }

        } else if (objectType == 'account') {

            defaultSession = 'a4d39000000LOCnAAO'; // General Correspondence
            List<WorkIt2__Timing__c> timeSheetList = [Select Id From WorkIt2__Timing__c Where Account__r.Id = :objectId AND Owner.Id = :userId Limit 1];
            if (timeSheetList.size() > 0) {
                WorkIt2__Timing__c timeSheets = timeSheetList.get(0);
                timeSheetId = timeSheets.Id;
            } else {
                WorkIt2__Timing__c timeSheet = new WorkIt2__Timing__c();
                timeSheet.Account__c = objectId;
                insert timeSheet;
                timeSheetId = timeSheet.Id;
            }
        }


        String sessionId = '';
        List<WorkIt2__Session_Type__c> sessionList = [Select Id From WorkIt2__Session_Type__c Where Name = :dispo Limit 1];
        if (sessionList.size() > 0) {
            WorkIt2__Session_Type__c sessionIds = sessionList.get(0);
            sessionId = sessionIds.Id;
        }

        Date queryDate          = Date.newInstance(yr, mo, dy);
        Date weekStartDate      = queryDate.toStartOfWeek();
        Integer year            = weekStartDate.year();
        Integer month           = weekStartDate.month();
        Integer day             = weekStartDate.day();
        DateTime WeekStartTime  = DateTime.newInstance(year, month, day, 00, 00, 01);
        DateTime weekEndTime    = weekStartTime.addDays(7);
        DateTime beginTime      = DateTime.now();

        List<WorkIt2__Time_Entry__c> Entries = [Select Id, WorkIt2__Heartbeat__c From WorkIt2__Time_Entry__c
                                                Where WorkIt2__Timing__c = :timeSheetId
                                                        AND WorkIt2__Start__c >= :weekStartTime
                                                        AND WorkIt2__Heartbeat__c < :weekEndTime
                                                Order BY WorkIt2__Heartbeat__c DESC Limit 1];
        if (Entries.size() > 0) {
            WorkIt2__Time_Entry__c latestEntry = Entries.get(0);
            beginTime = latestEntry.WorkIt2__Heartbeat__c;
            beginTime = beginTime.addMinutes(3);
        } else {
            beginTime = WeekStartTime;
        }

        DateTime endTime   = beginTime.addMinutes(loggedMinutes);

        WorkIt2__Time_Entry__c timeEntry = new WorkIt2__Time_Entry__c();
        timeEntry.WorkIt2__Start__c                = beginTime;
        timeEntry.WorkIt2__Timing__c               = timeSheetId;
        timeEntry.WorkIt2__Comment__c              = comments;
        if (sessionId.length() > 0) {
            timeEntry.WorkIt2__Session_Type__c     = sessionId;
        } else {
            timeEntry.WorkIt2__Session_Type__c     = defaultSession;
        }
        if (proactive == 1) {
            timeEntry.Proactive__c                 = true;
        }
        timeEntry.WorkIt2__Heartbeat__c            = endTime;
        insert timeEntry;

        String recordId    = timeEntry.id;
        String sessionName = [Select WorkIt2__Session_Type__r.Name From WorkIt2__Time_Entry__c Where Id = :recordId Limit 1].WorkIt2__Session_Type__r.Name;
        String accountName = '';
        List<Account> accountList = [Select Name From Account Where Id = :accountId Limit 1];
        if (accountList.size() > 0) {
            Account accounts = accountList.get(0);
            accountName = accounts.Name;
        } else {
            accountName = 'No Account Found';
        }

        return sessionName + '|' + accountName + '|' + objectName;
    }

    @RemoteAction       // Upload Notes Method
    public static String uploadNoteMethod(String noteTitle, String noteBody, String recordId) {

        // Check if Record is a project.  If it is, check if there's a parent project.  If there is, set the recordId to the parent project Id
        List<Project__c> projectList = [Select ParentProject__c From Project__c where Id = :recordId limit 1];
        if (projectList.size() > 0) {
            Project__c projects = projectList.get(0);
            String parentId = projects.ParentProject__c;
            List<Project__c> parentList = [Select Id From Project__c where Id = :parentId limit 1];
            if (parentList.size() > 0) {
                recordId = projects.ParentProject__c;
            }
        }

        note n      = new note();
        n.parentId  = recordId;
        n.body      = noteBody;
        n.title     = noteTitle;
        n.isPrivate = false;
        insert n;

        return n.id;
    }

    @RemoteAction       // Upload File Method
    public static String uploadFileMethod(String fileName, String fileContent, String fileBody, String recordId) {

        // Check if Record is a project.  If it is, check if there's a parent project.  If there is, set the recordId to the parent project Id
        List<Project__c> projectList = [Select ParentProject__c From Project__c where Id = :recordId limit 1];
        if (projectList.size() > 0) {
                Project__c projects = projectList.get(0);
            String parentId = projects.ParentProject__c;
            List<Project__c> parentList = [Select Id From Project__c where Id = :parentId limit 1];
            if (parentList.size() > 0) {
                recordId = projects.ParentProject__c;
            }
        }

        Attachment attachment           = new Attachment();
        attachment.Body                 = EncodingUtil.base64Decode(fileBody);
        attachment.Name                 = fileName;
        attachment.ContentType          = fileContent;
        attachment.ParentId             = recordId;
        insert attachment;
        fileBody = '';

        return attachment.id;
    }
    
    @RemoteAction               // Delete Time Entry
    public static String deleteEntryMethod(String entryId) {
        
        List<WorkIt2__Time_Entry__c> timeEntries = [Select id From WorkIt2__Time_Entry__c where Id = :entryId limit 1];
        if (timeEntries.size() > 0) {
                WorkIt2__Time_Entry__c timeEntry = timeEntries.get(0);
                delete timeEntry;
        }
        return entryId;
    }
}