/**
 * Created by mohandaas.rangaswamy on 12/22/2016.
 */
// Update SiteConfiguration__c custom setting
public class SandboxPostCopy_UpdateSiteConfiguration extends SandboxPostCopyTask{

    public override String getClassName(){
        return 'SandboxPostCopy_UpdateSiteConfiguration';
    }

    public override string task(SandboxContext context){

        SiteConfiguration__c siteConfig = SiteConfiguration__c.getInstance(((String)context.organizationId()).left(15));
        if(siteConfig != null){
            siteConfig.Name = ((String)context.sandboxId()).left(15);
            siteConfig.AutoEventEmails__c = false;
            siteConfig.EventResolvedEmails__c = false;
            siteConfig.DeveloperErrorFromName__c = context.sandboxName() + ' Sandbox';
            siteConfig.OrgId__c = context.sandboxName();
            update siteConfig;
        }
        system.debug('task(): siteConfig - '+siteConfig);
        return null;

    }
}