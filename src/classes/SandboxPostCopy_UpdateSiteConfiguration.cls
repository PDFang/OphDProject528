/**
 * Created by mohandaas.rangaswamy on 12/22/2016.
 */
// Update SiteConfiguration__c custom setting
public class SandboxPostCopy_UpdateSiteConfiguration extends SandboxPostCopyTask{

    public override String getClassName(){
        return 'SandboxPostCopy_UpdateSiteConfiguration';
    }

    public override string task(SandboxContext context){
        string sandboxOrgId;
        if(context != null){
            sandboxOrgId = ((String)context.organizationId()).left(15);
        }else{
            sandboxOrgId = UserInfo.getOrganizationId().left(15);
        }
        String sandboxName = context != null ? context.sandboxName() : UserInfo.getUserName().substringAfterLast('.');
        SiteConfiguration__c siteConfig = SiteConfiguration__c.getInstance(sandboxOrgId);
        if(siteConfig != null){
            //siteConfig.Name = ((String)context.sandboxId()).left(15);
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