/**
 * Created by william.nelson on 9/26/2017.
 */

public class CustomCaseCommentHandler extends TriggerHandler {

    public CustomCaseCommentHandler(){}

    protected override void afterInsert() {

        if (AllCommentTriggerHelper.hasAlreadyCreatedComments() == false) {
            List<casecomment> childcomment = new List<casecomment>();
            Map<Id, SendMailData> SendEmailList = new Map<Id, SendMailData>();

            //system.debug('Trigger.new => ' + Trigger.new);
            for (Case_Comment_Custom__c t : (List<Case_Comment_Custom__c>) Trigger.new) {
                if (t.IsPublished__c == true){
                    casecomment newcomment = new casecomment();
                    newcomment.CommentBody = t.CommentBody__c;
                    newcomment.IsPublished = t.IsPublished__c;
                    //newCommmand.CreateDate = t.CommentCreatedDate__c;
                    newcomment.ParentId = t.ParentId__c;
                    childcomment.add(newcomment);
                    system.debug('newcomment.new => ' + newcomment);
                }
                else{
                    SendMailData mailData = new SendMailData();
                    //MailData.AccountId = t.Account()
                    MailData.CaseId = t.ParentId__c;
                    //MailData.AccountId = t.;
                    MailData.Message = getMessageText(t);
                    MailData.Header = Label.Custom_Case_Comment_Email_Subject;
                    MailData.AccountId = t.ParentID__c;
                    MailData.CreatorName = t.CreatorName__c;
                    SendEmailList.put(t.ParentId__c, MailData);
                }
            }
            system.debug('childCommand.new => ' + childcomment);
            if (!childcomment.isEmpty()) {
                insert childcomment;
            }
            if (!SendEmailList.isEmpty()){
                SendCaseCommentEmail(SendEmailList);
            }

        }
    }
    private string getMessageText(Case_Comment_Custom__c comment) {
        string Header;
        string Body;



        Body =  Label.Custom_Case_Comment_Email_Body;
               //'A new private case comment has been added to {case #} by {CreatorName}. Click {here} to access the case.  ' +
               // 'Do not reply to this email. Access the {case} record to make any updates.';

        return Body;
    }

    private void SendCaseCommentEmail( Map<Id, SendMailData> SendEmailList){
        //one query to get the data
        system.debug ('Entering Comment Email');

        Map<Id, Case> AccountCaseMap = new Map<Id, Case>();
        Map<Id, Contact> ContactAccountMap = new Map<Id, Contact>();
        Set<Id> UserSet = new Set<Id>();
        Set<id> FinalContactList = new Set<id>();

        List<case> CaseList  =  [Select  Id, AccountId, CaseNumber, CaseNumberLink__c, CadebillAccountNo__c from Case where id in: SendEmailList.keySet()];

        system.debug ('AccountCaseMap ==> ' + AccountCaseMap);
        for (Case c: CaseList){
            AccountCaseMap.put(c.AccountId, c);
            if(SendEmailList.containsKey(c.id)){
                SendEmailList.get(c.id).AccountId = c.accountId;
                SendEmailList.get(c.id).AccountNumber = c.CadebillAccountNo__c;
                SendEmailList.get(c.id).caseNumber = c.CaseNumber;
                SendEmailList.get(c.id).caseNumber = c.CaseNumber;
                SendEmailList.get(c.id).CaseLink = c.CaseNumberLink__c;

            }

        }
        List<Contact> ContactList  =  [Select Id, AccountID, Email from Contact where AccountId in: AccountCaseMap.keySet()];

        system.debug ('ContactList ==> ' + ContactList);
        for(Contact c : ContactList){
            ContactAccountMap.Put(c.id, c);
        }
        system.debug ('ContactAccountMap ==> ' + ContactAccountMap);

        //List<PermissionSetAssignment> ValidUserList  =  [SELECT PermissionSetId, AssigneeID FROM PermissionSetAssignment WHERE AssigneeId in (select id from user where contactid in: ContactAccountMap.KeySet()) AND PermissionSet.Name = 'Partner_Community_Implementation_SaaS'];
        List<PermissionSetAssignment> ValidUserList  =  [SELECT PermissionSetId, AssigneeID FROM PermissionSetAssignment WHERE AssigneeId in (select id from user where contactid in: ContactAccountMap.KeySet())]; // AND PermissionSet.Name = 'Partner_Community_Implementation_SaaS'];
        for(Contact c : ContactList){
            ContactAccountMap.Put(c.id, c);
        }

        system.debug ('ValidUserList ==> ' + ValidUserList);

        for(PermissionSetAssignment u: ValidUserList){
            UserSet.Add(u.AssigneeID);
        }

        system.debug ('ValidUserList ==> ' + ValidUserList);

        List<Contact> tempContactList = [Select id from Contact where id in (Select contactId from user where id in: UserSet)];
        for (contact c: tempContactList){
            FinalContactList.add(c.id);
        }

        for ( Id mID : SendEmailList.KeySet())
        {
            system.debug ('Sending Email ==> ***') ;
            SendMailData mailData = SendEmailList.get(mID);
            GetEmailListByCase(mailData,AccountCaseMap, ContactAccountMap,FinalContactList );
        }
    }

    private List<string> GetEmailListByCase(SendMailData Maildata,  Map<Id, Case> AccountCaseMap, Map<Id, Contact> ContactAccountMap,Set<id> FinalContactList )
    {

        system.debug( '** AccountCaseMap == > ' + AccountCaseMap);
        id CaseId = MailData.CaseId;
        id AccountId = MailData.AccountId;
        Case CaseAccountData  =  AccountCaseMap.get(CaseID);
        List<string> EmailAddresses;
        EmailAddresses = new List<string>();
        for ( id cID : ContactAccountMap.keySet()) {
            Contact con = ContactAccountMap.get(cID);
            if (con.AccountID == MailData.AccountId) {
                system.debug('Acount has a match **');
                system.debug('con.email == > ' + con.Email);
                system.debug('con.id == > ' + con.Id);
                system.debug('FinalContactList ==>' + FinalContactList);
                system.debug('FinalContactList.Contains(con.id) == >' + FinalContactList.Contains(con.id));
                if (FinalContactList.Contains(con.id)) {
                    system.debug('Adding con.email == > ' + con.Email);
                    EmailAddresses.add(con.Email);
                }
            }
        }

        system.debug('FinalContactList ==>' + FinalContactList);
        system.debug('EmailAddresses ==>' + EmailAddresses);
        EmailAddresses = new List<string>();
        EmailAddresses.add('William.Nelson@niceIncontact.com');
        //workflow rule to send and avoid governer limit ?
        if (!EmailAddresses.isEmpty())
        {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            system.debug('EmailAddresses ==>' + EmailAddresses);
            mail.setToAddresses(EmailAddresses);
            mail.setSubject(buildSubject(MailData));
            mail.setPlainTextBody(MailData.Message);
            mail.setHtmlBody(buildBody(MailData));
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
        return null;
    }

    private string buildSubject(SendMailData MailData){
        string subject =  MailData.Header;
        subject = subject.replace('{Account}', MailData.AccountNumber);
        subject = subject.replace('{Case}', MailData.CaseNumber);
        return subject;
    }

    private string buildBody(SendMailData MailData){
        string body = MailData.Message;
        body = body.replace ('{case #}', MailData.caseNumber);
        body = body.replace ('{here}',  '<a href =' +  URL.getSalesforceBaseUrl().toExternalForm() + '/'  + MailData.CaseId  + '> here </a>');
        body = body.replace ('{case}',  '<a href =' +  URL.getSalesforceBaseUrl().toExternalForm() + '/'  + MailData.CaseId  + '> case </a>');
        body = body.replace ('{CreatorName}', MailData.CreatorName);
        return body;
    }

}