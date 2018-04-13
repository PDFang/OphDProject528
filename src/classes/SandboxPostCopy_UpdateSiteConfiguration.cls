/**
 * Created by mohandaas.rangaswamy on 12/22/2016.
 */
// Update SiteConfiguration__c custom setting
public class SandboxPostCopy_UpdateSiteConfiguration extends SandboxPostCopyTask{

    public override String getClassName(){
        return 'SandboxPostCopy_UpdateSiteConfiguration';
    }

    public override string task(SandboxContext context){

        String orgId = ((String) (context != null ? context.organizationId() : UserInfo.getOrganizationId())).left(15);

        SiteConfiguration__c siteConfig = SiteConfiguration__c.getInstance(orgId);

        if(siteConfig != null){
            String sandboxName = context != null ? context.sandboxName() : UserInfo.getUserName().substringAfterLast('.').toUpperCase();

            siteConfig.Name = orgId;
            siteConfig.AutoEventEmails__c = false;
            siteConfig.EventResolvedEmails__c = false;
            siteConfig.DeveloperErrorFromName__c = sandboxName + ' Sandbox';
            siteConfig.OrgId__c = sandboxName;
            update siteConfig;
        }
        system.debug('task(): siteConfig - '+siteConfig);
        return null;

    }
}