/**
 * Created by mohandaas.rangaswamy on 3/30/2018.
 */

public with sharing class SandboxPostCopy_UpdateAppConfiguration extends SandboxPostCopyTask{

    public override String getClassName(){
        return 'SandboxPostCopy_UpdateAppConfiguration';
    }

    public override string task(SandboxContext context) {

        AppConfiguration__c appConfig = AppConfiguration__c.getInstance();

        if(appConfig != null){
            appConfig.Turn_Off_JIRA_Integration__c = true;
            appConfig.Turn_Off_Partner_Case_Proxy_Service__c = true;
            appConfig.XM_Turn_Off_Comment_Notifications__c = true;
            appConfig.XM_Turn_Off_Event_Notifications__c = true;
            appConfig.XM_Turn_Off_Maintenance_Notifications__c = true;

            update appConfig;
        }
        system.debug('task(): appConfig - '+appConfig);

        return null;

    } // end of task()

}