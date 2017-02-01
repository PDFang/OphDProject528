/**
 * Created by mohandaas.rangaswamy on 1/11/2017.
 */

@IsTest
private class SandboxPostCopyImplementationTest {
    static testMethod void testBehavior() {
        createTestData();
        test.startTest();
        Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
        test.testSandboxPostCopyScript(new SandboxPostCopyImplementation(), userinfo.getOrganizationId(), userinfo.getOrganizationId(), 'LAB');
        test.stopTest();

        List<Sandbox_Post_Copy_Task__mdt> taskList = [Select DeveloperName, Task_Order__c from Sandbox_Post_Copy_Task__mdt where IsActive__c = true];
        List<Sandbox_Post_Copy_Log__c> logList = [Select Class_Name__c, Status__c from  Sandbox_Post_Copy_Log__c];
        system.assertEquals(logList.size(), taskList.size(), 'Not all active sandbox post copy tasks were executed.');
    }

    static testMethod void testDisableSsoPermission() {
        test.startTest();
        Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
        new SandboxPostCopy_DisableSsoPermission().task(null);
        test.stopTest();
    }

    static testMethod void testUpdateOutboundMessage() {
        test.startTest();
        Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
        new SandboxPostCopy_UpdateOutboundMessage().task(null);
        test.stopTest();

    }

    static testMethod void testUpdateRemoteSiteSetting() {
        test.startTest();
        Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
        new SandboxPostCopy_UpdateRemoteSiteSetting().task(null);
        test.stopTest();

    }

    static testMethod void testUpdateEmailRecipients() {
        test.startTest();
        Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
        new SandboxPostCopy_UpdateEmailRecipients().task(null);
        test.stopTest();

    }


    static void createTestData(){

        ServiceConnection__c accountSync = new ServiceConnection__c();
        accountSync.Name = 'AccountSync';
        accountSync.EndPoint__c = System.LABEL.Corp_Proxy;
        accountSync.Username__c = 'testuser';
        accountSync.Password__c = '@#$!%^';
        insert accountSync;

        SiteConfiguration__c siteConfig = new SiteConfiguration__c();
        siteConfig.Name = userInfo.getOrganizationId().left(15);
        siteConfig.AutoEventEmails__c = true;
        siteConfig.EventResolvedEmails__c = true;
        siteConfig.DeveloperErrorFromName__c = 'inContact';
        siteConfig.OrgId__c = userInfo.getOrganizationName();
        insert siteConfig;

        Profile sysAdmin = [SELECT Id from Profile where Name = 'System Administrator'];
        user adminUser = new User(
                FirstName = 'Test System',
                LastName = 'Admin',
                Email = 'adminuser=incontact.com@example.com',
                Username = 'adminuser@incontact.com',
                Department = 'Information Systems 00',
                Alias = 'test',
                profileId = sysAdmin.Id,
                EmailEncodingKey = 'UTF-8',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US'
        );
        insert adminUser;

    } // end of createTestData()

    private class WebServiceMockImpl implements WebServiceMock
    {
        public void doInvoke(
                Object stub, Object request, Map<String, Object> response,
                String endpoint, String soapAction, String requestName,
                String responseNS, String responseName, String responseType)
        {
            if(request instanceof MetadataService.retrieve_element)
                response.put('response_x', new MetadataService.retrieveResponse_element());
            else if(request instanceof MetadataService.readMetadata_element) {
                String metadataType = ((MetadataService.readMetadata_element)request).type_x;
                if(metadataType == 'WorkflowOutboundMessage') {
                    MetadataService.WorkflowOutboundMessage message = new MetadataService.WorkflowOutboundMessage();
                    message.fullName = 'TEST_MESSAGE';
                    message.endpointUrl = 'https://test.incontact.com';
                    MetadataService.ReadWorkflowOutboundMessageResult result = new MetadataService.ReadWorkflowOutboundMessageResult();
                    result.records = new MetadataService.WorkflowOutboundMessage[]{
                            message
                    };
                    MetadataService.readWorkflowOutboundMessageResponse_element responseElement = new MetadataService.readWorkflowOutboundMessageResponse_element();
                    responseElement.result = result;
                    response.put('response_x', responseElement);
                }
                else if(metadataType == 'RemoteSiteSetting') {
                    MetadataService.RemoteSiteSetting remoteSite = new MetadataService.RemoteSiteSetting();
                    remoteSite.fullName = 'TEST_SITE';
                    remoteSite.isActive = true;
                    MetadataService.ReadRemoteSiteSettingResult result = new MetadataService.ReadRemoteSiteSettingResult();
                    result.records = new MetadataService.RemoteSiteSetting[]{
                            remoteSite
                    };
                    MetadataService.readRemoteSiteSettingResponse_element responseElement = new MetadataService.readRemoteSiteSettingResponse_element();
                    responseElement.result = result;
                    response.put('response_x', responseElement);
                }
                else if(metadataType == 'WorkflowAlert'){
                    MetadataService.WorkflowAlert emailAlert = new MetadataService.WorkflowAlert();
                    emailAlert.fullName = 'TEST_ALERT';
                    emailAlert.ccEmails = new String[]{'user1@incontact.com'};
                    MetadataService.ReadWorkflowAlertResult result = new MetadataService.ReadWorkflowAlertResult();
                    result.records = new MetadataService.WorkflowAlert[]{
                            emailAlert
                    };
                    MetadataService.readWorkflowAlertResponse_element responseElement = new MetadataService.readWorkflowAlertResponse_element();
                    responseElement.result = result;
                    response.put('response_x', responseElement);
                }
            }
            else if(request instanceof MetadataService.listMetadata_element) {
                MetadataService.FileProperties result = new MetadataService.FileProperties();
                result.fullName = 'TEST';
                MetadataService.listMetadataResponse_element responseElement = new MetadataService.listMetadataResponse_element();
                responseElement.result = new MetadataService.FileProperties[]{
                        result
                };
                response.put('response_x', responseElement);
            }
            else if(request instanceof MetadataService.describeMetadata_element)
                response.put('response_x', new MetadataService.describeMetadataResponse_element());
            else if(request instanceof MetadataService.updateMetadata_element) {
                MetadataService.SaveResult result = new MetadataService.SaveResult();
                result.success = true;
                MetadataService.updateMetadataResponse_element responseElement = new MetadataService.updateMetadataResponse_element();
                responseElement.result = new MetadataService.SaveResult[]{
                        result
                };
                response.put('response_x', responseElement);
            }
            else if(request instanceof  MetadataService.deleteMetadata_element) {
                MetadataService.DeleteResult result = new MetadataService.DeleteResult();
                result.success = true;
                MetadataService.deleteMetadataResponse_element responseElement = new MetadataService.deleteMetadataResponse_element();
                responseElement.result = new MetadataService.DeleteResult[]{result};
                response.put('response_x', responseElement);
            }
            else if(request instanceof  MetadataService.upsertMetadata_element)
                response.put('response_x', new MetadataService.upsertMetadataResponse_element());
            else if(request instanceof  MetadataService.createMetadata_element)
                response.put('response_x', new MetadataService.createMetadataResponse_element());
            return;
        }
    }

}