public class InContactConfiguration 
{
        
    //*Sandbox
    
    public static String Instance = 'Sandbox';
    
    //CastIron orchestration urls
    public static String AccountUpdateURL = 'http://199.172.9.113:80/CGAccountInfoUPD';
    public static String PartnerUserResetPasswordURL = 'http://199.172.9.113:80/ResetAPIUserPassword';
    
    //Case ADFS Link
    public static String ADFSContactLink = 'http://labsbx02.blfdev.lab/ServiceSite/UserDetail.aspx?AccountNumber={AccountNumber}&Guid={Guid}';
    public static String ADFSCreateContactLink = 'http://labsbx02.blfdev.lab/UserAdmin/CreateUserFromSFContact.aspx?ContactId={ContactId}';
    public static String ADFSImpersonateAccountLink = 'http://jfike.ucn.net/ServiceSiteAdmin/Impersonate.aspx?AcctNum={AccountNumber}';
    public static String ADFSImpersonateContactLink = 'http://jfike.ucn.net/ServiceSiteAdmin/Impersonate.aspx?guid={Guid}';
    
    //Email URL For account management work orders and service requests.
    public static String CaseAMClosedWorkOrderServReqSurveyURL = 'http://echoreview.echosurvey.com/ucn/ucn/AM_Launcher.taf?ticketnumber={Case #}&subject={Subject}&accountnumber={CostGuard Acct#}&customername={Account Name}&contact_name={Contact Name}&customer_email={Contact Email}&queue={Case Owner}&assignedto={Assigned To}&createddate={Date/Time Opened}&closeddate={Date/Time Closed}&status={Status}&send_email=yes'; 
    
    //Email URL For account management work orders and service requests.
    public static String CaseSDSClosedWorkOrderServReqSurveyURL = 'https://echo.incontact.com/ucn/ucn/sds_Launcher.taf?ticketnumber={Case #}&subject_of_the_email={Subject}&accountnumber={CostGuard Acct#}&customername={Account Name}&contact_name={Contact Name}&customer_email={Contact Email}&queue={Case Owner}&assignedto={Assigned To}&createddate={Date/Time Opened}&closeddate={Date/Time Closed}&status={Status}&send_email=yes&service_package={ServicePackage}';
    
         
    //Trip_Report Echo survey configurations
    public static String TripReportEchoSurveyURL = 'http://edev.echosurvey.com/ucn/ucn/gsd_launcher.taf?customer_email={Email1}&case_id={CustomerAcctNumber}&customer_name={Company}&CSM={CSM}&Customer_Name_First={FirstName}&Customer_Name_Last={LastName}';
	public static String EducationTripReportEchoSurveyURL = 'http://edev.echosurvey.com/ucn/ucn/edu_launcher.taf?customer_email={Email1}&case_id={CustomerAcctNumber}&customer_name={customerName}&CSM={CSM}&send_email=true&Subject={subject}';
    
    //Event notification Engine
    public static String NotificationEndPoint = 'https://labproxy.ucn.net/Notifications/NotificationProxy.asmx ';
    public static String NotificationUserName = 'test';
    public static String NotificationPassword = 'pw';
    public static String SharepointEndPoint = 'http://199.172.9.115:40443/KBProxy.asmx';
    public static String SharepointUserName = 'test';
    public static String SharepointPassword = 'pw';
    public static String SharepointPath = 'http://labmojo';
    public static String EventEmailGroup = 'salesforceadmins@incontact.com';
    public static String MaintenanceEmailGroup = 'salesforceadmins@incontact.com';
    public static String BugEndPoint = 'https://labproxy.ucn.net/tfs/rndservice.asmx';
    public static String BugUserName = 'test';
    public static String BugPassword = 'pw';
    public static String CorpTfsEndPoint = 'https://labproxy.ucn.net/tfs/corpservice.asmx';
    public static String CorpTfsUserName = 'test';
    public static String CorpTfsPassword = 'pw';
    public static String DocumentEndPoint = 'https://labproxy.ucn.net/SharePointProxy/DocumentService.asmx';
    public static String DocumentUserName = 'test';
    public static String DocumentPassword = 'pw';
    
    //End Sandbox Code*/
    
    /*Production
    
    public static String Instance = 'Production';
    
    //CastIron orchestration urls
    public static String AccountUpdateURL = 'http://199.172.8.113:80/CGAccountInfoUPD';
    public static String PartnerUserResetPasswordURL = 'http://199.172.8.113:80/ResetAPIUserPassword';
    
    //Case ADFS Link
    public static String ADFSContactLink = 'http://ssoadmin.ucn.net/ServiceSite/UserDetail.aspx?AccountNumber={AccountNumber}&Guid={Guid}';
    public static String ADFSCreateContactLink = 'http://ssoadmin.ucn.net/CreateUserFromSFContact.aspx?ContactId={ContactId}';
    public static String ADFSImpersonateAccountLink = 'http://ssoadmin.ucn.net/Impersonate.aspx?AcctNum={AccountNumber}';
    public static String ADFSImpersonateContactLink = 'http://ssoadmin.ucn.net/Impersonate.aspx?guid={Guid}';
    
    //Email URL For account management work orders and service requests.
    public static String CaseAMClosedWorkOrderServReqSurveyURL = 'https://echo.incontact.com/ucn/ucn/AM_Launcher.taf?ticketnumber={Case #}&subject={Subject}&accountnumber={CostGuard Acct#}&customername={Account Name}&contact_name={Contact Name}&customer_email={Contact Email}&queue={Case Owner}&assignedto={Assigned To}&createddate={Date/Time Opened}&closeddate={Date/Time Closed}&status={Status}&send_email=yes'; 
    
    //Email URL For account management work orders and service requests.
    public static String CaseSDSClosedWorkOrderServReqSurveyURL = 'https://echo.incontact.com/ucn/ucn/sds_Launcher.taf?ticketnumber={Case #}&subject_of_the_email={Subject}&accountnumber={CostGuard Acct#}&customername={Account Name}&contact_name={Contact Name}&customer_email={Contact Email}&queue={Case Owner}&assignedto={Assigned To}&createddate={Date/Time Opened}&closeddate={Date/Time Closed}&status={Status}&send_email=yes&service_package={ServicePackage}';
    
         
    //Trip_Report Echo survey configurations
    public static String TripReportEchoSurveyURL = 'https://echo.incontact.com/ucn/ucn/GSD_Launcher.taf?customer_email={Email1}&case_id={CustomerAcctNumber}&customer_name={Company}&CSM={CSM}&Customer_Name_First={FirstName}&Customer_Name_Last={LastName}';
    public static String EducationTripReportEchoSurveyURL = 'https://echo.incontact.com/ucn/ucn/edu_launcher.taf?customer_email={Email1}&case_id={CustomerAcctNumber}&customer_name={customerName}&CSM={CSM}&send_email=true&Subject={subject}';
    
    //Event notification Engine
    public static String NotificationEndPoint = 'https://corpnotifications.incontact.com/NotificationProxy.asmx';
    public static String NotificationUserName = 'sfUser';
    public static String NotificationPassword = 'T3XRi1wHG2';
    public static String SharepointEndPoint = 'https://corpkbproxy.incontact.com/KBProxy.asmx';
    public static String SharepointUserName = '_kbproxy';
    public static String SharepointPassword = '~SyncW!thM3';
    public static String SharepointPath = 'http://mojo';
    public static String EventEmailGroup = 'eventnotifications-internal@incontact.com';
    public static String MaintenanceEmailGroup = 'maintenancenotifications-internal@incontact.com';
    
    public static String BugEndPoint = 'https://corpproxy.incontact.com/tfs/rndservice.asmx';
    public static String BugUserName = '_tfsproxy';
    public static String BugPassword = 'Pr0x4TfS!';
    public static String CorpTfsEndPoint = 'https://corpproxy.incontact.com/tfs/corpservice.asmx';
    public static String CorpTfsUserName = '_tfsproxy';
    public static String CorpTfsPassword = 'Pr0x4TfS!';
    public static String DocumentEndPoint = 'https://corpproxy.incontact.com/SharePointProxy/DocumentService.asmx';
    public static String DocumentUserName = '_spproxy';
    public static String DocumentPassword = 'Pr0x4sP!';

    //End Production Code*/
    
    //service level logos 
    public static String PlatinumLogoURL =  'https://images.incontact.com/salesforce/Plat20px.jpg';
    public static String GoldLogoURL =      'https://images.incontact.com/salesforce/gold20px.jpg';
    public static String SilverLogoURL =    'https://images.incontact.com/salesforce/Silver20px.jpg';
    public static String BasicLogoURL = 'https://images.incontact.com/salesforce/Basic20px.jpg';
    
    //service level names
    public static String PlatinumName =     'Platinum Service Customer';
    public static String GoldName =         'Gold Service Customer';
    public static String SilverName =       'Silver Service Customer';
    public static String SignatureName =    'Signature Service Customer';
    public static String BasicName =    'Basic Service Customer';
    
    //customer segment bg colors
    public static String KeyBG = '#F79646';
    public static String SmallBG = '#C5D9F1';
    public static String MidMarketBG = '#B2A1C7';
    public static String MajorBG = '#538ED5';
    public static String StrategicBG = '#00B050';

    
    //Closed case Echo survey configurations
    public static String CaseTechSupportClosedEchoSurveyURL = 'https://echo.incontact.com/ucn/ucn/salesforce_receiver.taf?TicketNumber={Case #}&Subject={Subject}&AccountNumber={CostGuard Acct#}&CustomerName={Account Name}&Contact={Contact Name}&Email={Contact Email}&Queue={Case Owner}&AssignedTo={Assigned To}&CreatedDate={Date/Time Opened}&ClosedDate={Date/Time Closed}&Status={Status}';
    public static String CasePremiseTechSupportClosedEchoSurveyURL = 'http://echo.incontact.com/ucn/survey_request.taf?customer_email={Contact Email}&customer_name={Account Name}&ticket_number={Case #}&subject={Subject}&csr={Assigned To}&Saf~CaseID={Case #}&queue={Case Owner}&BR=ThirtyDayRule&send_email=true'; //TM: Added thirty day rule
    public static String CasePremiseInstallationClosedEchoSurveyURL = 'http://echo.incontact.com/ucn/survey_request.taf?customer_email={Contact Email}&Saf~customer_name={Account Name}&Saf~CaseID={Case #}&queue={Case Owner}&send_email=true'; //TM Updated Project 45301
    public static String CaseCustomerSuccessClosedEchoSurveyURL = 'http://echo.incontact.com/ucn/survey_request.taf?customer_email={Contact Email}&customer_name={Account Name}&ticketnumber={Case #}&Subject_of_the_Email={Subject}&queue={Case Owner}&send_email=true';
    
    //Event Calendar
    public static string[] platforms = new String[]{'Dialer','Echo','inContact','Intelligent Network','TF - inContact','TF - International','Transport Services','Voice Services','VoIP Services','WFO'};
    public static Map<String,String> platformColors = new Map<String,String>{'Dialer' => '#0099CC','Echo' => '#00CC99','inContact' => '#003366','Intelligent Network' => '#FF9900','TF - inContact' => '#FFFF00','TF - International' => '#996600','Transport Services' => '#69AA69','Voice Services' => '#000000','VoIP Services' => '#673499','WFO' => '#808080'};
    public static string[] clusters = new String[]{'C1','C2','C3','C4','C5','C6','C7','C8','C9','B2','E1'};
    
    //sales stuff
    public static Set<String> salesRoles = new Set<String>{'Corporate Sales' ,'DSM, Eastern Sales' ,'DSM, Western Sales','DSM, Pacific Sales','Sales Rep, APAC Sales','DSM, EMEA Sales','VP, EMEA Sales','VP, Central Field Sales','DSM, Central Sales'};

    
    //New P1/P2 Event email verbiage
    public static string NewEventEmailBody = 'inContact Technicians have received an alert of potential customer impact. This alert is related specifically to {Product Impacted}. Engineers are actively engaged and updates will be posted to our Trust site shortly.\n\n' + 
	'If you feel you have been impacted by this event, please click <a href=\"http://support.incontact.com/Support/Trust">here</a> to visit the Trust section on the support site to get additional details regarding impact, create a case associated with Event {Case Number}, or to receive updates.\n\n' + 
	'<b>Event Type:</b>\t{Event Type}\n\n<b>Incident Description:</b>\t\n\n{Subject}\n\n{Description}\n\n<b>Start Time:</b>\t{Start Time}\n\n<b>Product Impacted:</b>\t{Product Impacted}\n\n<b>Service Impact:</b>\t{Service Impact}\n\n<b>Status:</b>\t{Case Status}\n\n<b>Customer Action:</b>\t{Customer Action}\n\n\n\nThank you,\ninContact Support';
    
    public static string NewEventEmailSubject = '***Service Impacting Event for {Product Impacted}***';

}