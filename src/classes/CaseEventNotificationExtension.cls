public class CaseEventNotificationExtension
{
    public Case c{get; private set;}
    private Set<Id> accountIds;
    private Id templateId;
    private Map<Id, EmailTemplate> templates;
    //private CaseEventClass.AccountIncident[] acctIncidents;
    public CaseEventClass cec{public get;private set;}
    private String[] csmEmails;
    public string subject;
    public string htmlString{public get;private set;}
    public string emailBody{get;set;}
    public string textBody{get;set;}
    //public List<Contact> contacts{public get;private set;}
    private List<Contact> allContacts;
    public integer contactCount{public get;private set;}
    public integer emailsSent{public get;private set;}
    public boolean renderPage{public get;private set;}
    public boolean renderConfirm{public get;private set;}
    public boolean canEdit{public get;private set;}
    public boolean allowNotifications{public get;private set;}
    public string xmSelectedForm{get;set;}

    // For product eligible for select Customers enable legacy notification otherwise enable xMatters notification
    public boolean enableXmatters{public get;private set;}
    // Fields mapped in Case_to_xMatters_Field_Mapping__mdt
    public List<String> xMattersFieldMapping{get; private set;}
    // list of forms setup in xMatters_Forms__mdt
    public List<SelectOption> xMattersForms{get; private set;}

    private final List<RecordType> recordTypes;
    private ID selRecordTypeId;
    private String standText;
    public boolean noText{get;set;}
    public Id selectedStandardTextId{get;set;}
    private List<Standard_Text__c> standardTexts;
    public string contactRole{public get;private set;}
    private string recordTypeName;
    public static list<string> clusters;


    private static boolean isxMattersMaintenanceNotificationsTurnedOff = false;

    Static Set<String> caseFields = new Set<String>{
            'Id', 'RecordTypeId', 'StartDateTImeUTC__c', 'EndDateTimeUTC__c', 'EventType__c', 'Subject', 'Description', 'ProductImpacted__c', 'CustomersMayExperienceTheFollowing__c',
            'CustomerAction__c', 'Status', 'CaseNumber', 'PlatformsImpacted__c', 'Owner.Name', 'Account.Id', 'NumberOfAccountsImpacted__c'
    };

    public CaseEventNotificationExtension(ApexPages.StandardController controller)
    {
        this.c = (Case)controller.getRecord();
        string caseType;

        initXmattersForms();

        if(clusters == null)
        {
            clusters = new list<string>();
        }

        if(c.Id != null)
        {
            Map<ID,Schema.RecordTypeInfo> recordTypeMapById = Schema.SObjectType.Case.getRecordTypeInfosByID();
            recordTypeName = recordTypeMapById.get(c.RecordTypeId).getName();

            canEdit = inContactBaseClass.HasEditAccess(c.Id,UserInfo.getUserId());

            if((recordTypeName == 'Event' && c.Owner.Name != 'NOC Queue') || c.Status == 'Suspected')
            {
                allowNotifications = false;
            }
            else
            {
                allowNotifications = true;
            }


            AppConfiguration__c appConfig = AppConfiguration__c.getInstance();
            if(appConfig != null && appConfig.XM_Turn_Off_Maintenance_Notifications__c){
                isxMattersMaintenanceNotificationsTurnedOff = true;
            }
            System.debug('CaseEventNotificationExtension(): isxMattersMaintenanceNotificationsTurnedOff - ' + isxMattersMaintenanceNotificationsTurnedOff);

            Map<String, ProductEventMap__c> productEventMap = ProductEventMap__c.getAll();

            ProductEventMap__c productEventInfo = productEventMap.get(c.ProductImpacted__c);
            System.debug('CaseEventNotificationExtension(): productEventInfo - ' + productEventInfo);

            // Record Type - Maintenance Notification
            // Product Impacted - Not for Select Customers
            // xMatters Maintenance Notification turned on
            if(recordTypeName == 'Maintenance Notification' && productEventInfo != null && !productEventInfo.SelectCustomers__c
                    && !isxMattersMaintenanceNotificationsTurnedOff)
            {
                enableXmatters = true;
                xMattersFieldMapping = getxMattersFieldMapping();
                caseFields.addAll(xMattersFieldMapping);
            }else{
                enableXmatters = false;
            }

            List<String> soqlColumns = new List<String>(caseFields);
            System.debug('soqlColumns - ' + soqlColumns);

            String soql = 'Select ' + String.join(soqlColumns, ',') + ' FROM Case where Id = \'' + c.Id + '\'';
            c = Database.query(soql);
            System.debug('Case Record is' + c);

            if(enableXmatters){
                return;
            }

            accountIds = new Set<Id>();
            csmEmails = new String[]{};
            cec = new CaseEventClass(c);
            cec.listSize = 50000;
            if(clusters.size() > 0)
                cec.lstClusters = clusters;
            AccountIncidentsUpdate();

            if(recordTypeName == 'Event')
            {
                caseType = 'Event Standard Text';
                contactRole = 'Event Notification';
            }
            else if(recordTypeName == 'Maintenance Notification')
            {
                caseType = 'Notification Standard Text';
                contactRole = 'Maintenance Notification';
            }


            EventContactsUpdate();

            //get all Standard Text record types for dropdown
            recordTypes = new List<RecordType>([SELECT Name FROM RecordType WHERE sObjectType = 'Standard_Text__c' AND Name = :caseType ORDER BY Name]);

            SelectedRecordTypeId = recordTypes[0].Id;

            noText = true;
            renderConfirm = false;


        }
    }

    private void AccountIncidentsUpdate()
    {
        CaseEventClass.AccountIncident[] acctIncidents = cec.AccountIncidentList();

        if(!acctIncidents.isEmpty())
        {
            for(CaseEventClass.AccountIncident a:acctIncidents )
            {
                accountIds.add(a.acct.Id);

                if(a.acct.CSM__r.Email != NULL)
                {
                    csmEmails.add(a.acct.CSM__r.Email);
                }
            }
        }
    }


    private void EventContactsUpdate()
    {
        //contacts = new List<Contact>();
        //List<Contact> allContacts = new List<Contact>();

        string countquery = 'SELECT COUNT(Id) cnt FROM Contact WHERE Email != NULL AND AccountId IN :accountIds AND Deactivated__c = FALSE AND Contact_Role__c INCLUDES (\'' + contactRole + '\') ' ;
        AggregateResult[] getContacts = Database.Query(countquery);
        contactCount = integer.valueOf(getContacts[0].get('cnt')) ;
        
        /*
        if(contactCount > 1000)
        {
            for(integer i=0;i<1000;i++)
            {
                contacts.add(allContacts[i]);
            }
        }
        else if(contactCount > 0)
        {
            contacts.addAll(allContacts);
        }
        */

        //if(contactCount > 0)
        //{
        //    contacts = [SELECT Id, Name, Email, AccountId FROM Contact WHERE Email != NULL AND Contact_Role__c INCLUDES(:contactRole) AND AccountId IN :accountIds];
        //}
    }

    public PageReference EventAccounts()
    {
        PageReference pageRef = Page.CaseEventAccounts;
        pageRef.getParameters().put('id', c.Id);

        return pageRef;
    }

    public PageReference SendNotification()
    {
        String[] addresses = new String[]{};
        Set<String> setAddresses = new Set<String>();
        String[] resellAndInternalAddresses = new String[]{};
        textBody = emailBody.replace('<br/>', '');
        htmlString = emailBody.replace('\\n','<br/>');
        htmlString = htmlString.replace('\n','<br/>');
        List<Task> tasks = new List<Task>();
        Id internalEmailGroup;
        Set<Id> internalEmailGroupMembers = new Set<Id>();
        string emailBodyCustomer, emailBodyPartner;


        string platformImpacted = MergeFieldListFormat('{Platform Impacted}',c.PlatformsImpacted__c.replace(' - inContact',''), ';');
        string platforms = '<b>Platform(s) Impacted:</b>\t ' + platformImpacted;
        htmlString = htmlString.replace('{Platform Impacted}','<br/><br/>' + platforms);
        textBody   = textBody.replace('{Platform Impacted}','\n\n' + platforms);
        emailBody = textBody;

        system.debug('==== emailBodyPartner ====' + emailBodyPartner);
        system.debug('==== emailBodyCustomer ====' + emailBodyCustomer);

        if(emailBody.contains('{') || emailBody.contains('}')  || subject.contains('{') || subject.contains('}'))
        {
            if(system.isFuture())
            {
                inContactBaseClass.SendErrorEmail('Event Email cannot contain { or } characters.  Please update the place holder.', c.CaseNumber);
            }else
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Email cannot contain { or } characters.  Please update the place holder.'));
            }
            return null;
        }

        if(string.isBlank(emailBody) || string.isBlank(subject))
        {
            if(system.isFuture())
            {
                inContactBaseClass.SendErrorEmail('The subject and body cannot be blank in an Event Email', c.CaseNumber);
            }else
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'The subject and body cannot be blank.'));
            }
            return null;
        }




        if(recordTypeName == 'Event')
        {
            setAddresses.add(InContactConfiguration.EventEmailGroup);
        }
        else if(recordTypeName == 'Maintenance Notification')
        {
            setAddresses.add(InContactConfiguration.MaintenanceEmailGroup);
        }

        system.debug(setAddresses);


        List<Contact> allContacts = new List<Contact>();

        string countquery = 'SELECT Id, Name, Email, Account.RecordTypeId FROM Contact WHERE Email != NULL AND AccountId IN :accountIds AND Deactivated__c = FALSE AND Contact_Role__c INCLUDES (\'' + contactRole + '\') ORDER BY Account.Name, Name' ;
        allContacts = Database.Query(countquery);
        //System.debug('allContacts arnab ==>' + allContacts);
        //System.debug('accountIds arnab ==>' + accountIds);
        if(!allContacts.isEmpty())
        {
            for(Contact con:allContacts)
            {
                setAddresses.add(con.Email);

                Task t = new Task();
                t.Subject = subject;
                t.Type = recordTypeName + ' Email';
                t.WhoId = con.Id;
                t.WhatId = c.Id;
                t.Status = 'Completed';
                t.Description = emailBody;

                tasks.add(t);
            }

            system.debug('==== Set Addresses ====');
            system.debug(setAddresses);
            emailsSent = setAddresses.size() + resellAndInternalAddresses.size();

            //add csms
            setAddresses.addAll(csmEmails);
            addresses.addAll(setAddresses);

            try
            {

                list<NotificationHelperClass.EmailTemplate> listTemplates = new list<NotificationHelperClass.EmailTemplate>();

                if(addresses.size() > 0)
                {
                    NotificationHelperClass.EmailTemplate template = new NotificationHelperClass.EmailTemplate();
                    template.recipients = addresses;
                    template.subject = subject;
                    template.htmlBody = htmlString;
                    template.textBody = textBody;
                    template.templateId = 6;
                    listTemplates.add(template);
                }
                System.enqueueJob(new NotificationQueableClass(listTemplates,''));

                insert tasks;

                EmailMessage em = new EmailMessage();
                em.htmlBody = htmlString;
                em.textBody = textBody;
                em.Subject = subject;
                em.ParentId = c.Id;
                em.MessageDate = system.now();

                insert em;

                if(recordTypeName == 'Maintenance Notification')
                {
                    c.Status = 'Notification Sent';
                    c.NumberOfAccountsImpacted__c = cec.totalSize;
                    update c;
                }

                renderConfirm = true;
            }
            catch(DmlException ex)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getDmlMessage(0)));
                return null;
            }
        }

        return null;

    }

    private void MergeField(string field, string data)
    {
        string defaultReplaceMessage = ' ';
        if (data != null || String.isEmpty(data) == false)
        {
            emailBody = emailBody.replace(field, data);
        }
        else
        {
            emailBody = emailBody.replace(field, defaultReplaceMessage);
        }
    }

    private string MergeFieldListFormat(string field, string data, string delimiter)
    {
        //persumes list is delimited by 
        string []lines;
        string buffer ='';
        lines = data.split(delimiter);
        System.debug(lines);
        buffer = String.join(lines, '<br/>');
        buffer = '\n' + buffer;
        System.debug(buffer);
        return buffer;
        // return emailBody = emailBody.replace(field, buffer);

    }
    public void MergeFieldUpdate()
    {


        String formattedEventStartDate = c.StartDateTImeUTC__c;
        formattedEventStartDate = formattedEventStartDate.substringBeforeLast(':');
        formattedEventStartDate = formattedEventStartDate + ' (UTC)';

        String formattedEventEndDate = c.EndDateTimeUTC__c;
        if(formattedEventEndDate != null)
        {
            formattedEventEndDate = formattedEventEndDate.substringBeforeLast(':');
            formattedEventEndDate = formattedEventEndDate + ' (UTC)';
        }

        MergeField('{Event Type}',c.EventType__c);
        MergeField('{Subject}',c.Subject);
        MergeField('{Description}', c.Description);
        MergeField('{Start Time}', formattedEventStartDate);
        MergeField('{End Time}', formattedEventEndDate);
        MergeField('{Product Impacted}', c.ProductImpacted__c);
        MergeField('{Service Impact}', c.CustomersMayExperienceTheFollowing__c);
        MergeField('{Case Status}', c.Status);
        MergeField('{Customer Action}', c.CustomerAction__c);   //c.CustomerAction__c
        MergeField('{Case Number}', c.CaseNumber);


    }

    public void MergeFieldUpdateSubject()
    {
        subject = subject.replace('{Product Impacted}', c.ProductImpacted__c);
        subject = subject.replace('{Platform Impacted}', c.PlatformsImpacted__c.replace(' - inContact',''));
        subject = subject.replace('{Case Number}', c.CaseNumber);
        subject = subject.replace('{Subject}', c.Subject);
    }

    public void UpdateStandardText()
    {
        //loop though standard text to display the selected results
        for(Standard_Text__c st : standardTexts)
        {
            if(st.Id == selectedStandardTextId)
            {
                //in the display replace '\n' with '<br>' to add line breaks
                emailBody = st.StandardText__c;
                MergeFieldUpdate();
                subject = st.Name;
                MergeFieldUpdateSubject();
            }
        }
    }



    public List<selectOption> RecordTypeOptions
    {
        get
        {
            //new list for holding all of the picklist options
            List<SelectOption> options = new List<SelectOption>();
            //Add the first option of '- Select Record Type -' in case no values are returned from query below
            options.add(new selectOption('', '- Select Record Type -'));
            //Create an Option for each of the Record Types
            for(RecordType rt : recordTypes)
            {
                options.add(new selectOption(rt.Id, rt.Name));
            }
            return options;
        }
    }

    public string SelectedStandardText
    {
        get
        {
            return emailBody;
        }
        set
        {
            emailBody = value;
        }
    }

    public Id SelectedRecordTypeId
    {
        get
        {
            return selRecordTypeId;
        }
        set
        {
            standText = '';

            selRecordTypeId = value;
        }
    }

    public string SubjectText
    {
        get
        {
            return subject;
        }
        set
        {
            subject = value;
        }
    }

    public List<selectOption> StandardTextOptions
    {
        get
        {
            standardTexts = new List<Standard_Text__c>([Select Name, StandardText__c From Standard_Text__c WHERE RecordTypeId = :selRecordTypeId ORDER BY Name]);
            List<SelectOption> options = new List<SelectOption>();
            //Add the first option of '- Select Standard Text -' in case no values are returned from query below
            options.add(new selectOption('','- Select Standard Text -'));
            //Get Standard Text records for Record Type
            for(Standard_Text__c s : standardTexts)
            {
                options.add(new selectOption(s.Id,s.Name));
            }
            return options;
        }


    }

    public PageReference RefreshPage()
    {
        PageReference currPage = Page.CaseEventNotification;
        currPage.getParameters().put('id',c.id);
        currPage.setRedirect(true);
        return currPage;
    }

    private List<String> getxMattersFieldMapping(){

        List<String> xMattersFieldMapping = new List<String>();

        Set<String> sfFields = new Set<String>();
        for(Case_to_xMatters_Field_Mapping__mdt mdt : [
                Select Sort_Order__c, Salesforce_Case_Field__c From Case_to_xMatters_Field_Mapping__mdt where Maintenance__c = true order by Sort_Order__c NULLS LAST
        ]){
            sfFields.add(mdt.Salesforce_Case_Field__c);
        }

        xMattersFieldMapping.addAll(sfFields);
        system.debug('getxMattersFieldMapping(): xMattersFieldMapping - ' + xMattersFieldMapping);

        return xMattersFieldMapping;

    }

    private void initXmattersForms(){

        xMattersForms = new List<SelectOption>();
        xMattersForms.add(new SelectOption('', '- Choose a template -'));

        List<Schema.PicklistEntry> entries = xMatters_Forms__mdt.Form__c.getDescribe().getPicklistValues();

        for(xMatters_Forms__mdt mdt : [Select Form__c from xMatters_Forms__mdt order by Form__c]){
            xMattersForms.add(new SelectOption(mdt.Form__c, mdt.Form__c));
        }

    }

    public pagereference sendNotificationViaXmatters(){

        try{
            if(isxMattersMaintenanceNotificationsTurnedOff){ // safety check
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'xMatters Maintenance Notification is disabled. Please contact your administrator.'));
                return null;
            }
            if(String.isBlank(xmSelectedForm)){ // safety check
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must choose a maintenance template before sending the notification.'));
                return null;
            }
            xmNotification__c xmNotification = new xmNotification__c(
                    Case__c = c.Id,
                    Request_Date__c = system.now(),
                    Request_Type__c = 'Maintenance Notification',
                    xMatters_Form__c = xmSelectedForm
            );

            insert xmNotification;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Maintenance Notification request submitted successfully.'));

        }catch(Exception ex){
            system.debug('sendNotificationViaXmatters(): Exception - ' + ex);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Failed to Send Maintenance Notification. ' + ex.getDmlMessage(0)));
        }

        return null;

    }

}