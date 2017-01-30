/**
 * Created by mohandaas.rangaswamy on 12/21/2016.
 */
// Post copy apex class
public with sharing class SandboxPostCopyImplementation implements SandboxPostCopy
{
    public void runApexClass(SandboxContext context){
        // Do not run this class in Production unless it's running in test context
        if(!test.isRunningTest() && userinfo.getOrganizationId() == '00D700000008HFcEAM'){
            return;
        }
        List<Sandbox_Post_Copy_Task__mdt> postCopyTasks = [
                SELECT Id, DeveloperName, IsActive__c, Task_Order__c
                FROM Sandbox_Post_Copy_Task__mdt
                WHERE IsActive__c = true
                ORDER BY Task_Order__c
        ];
        system.debug('runApexClass(): No. of active tasks - ' + postCopyTasks.size());
        system.debug('runApexClass(): postCopyTasks - ' + postCopyTasks);
        for(Sandbox_Post_Copy_Task__mdt mdt : postCopyTasks){
            Type t = Type.forName(mdt.DeveloperName);
            SandboxPostCopyTask task = (SandboxPostCopyTask) t.newInstance();
            task.execute(context);
        }
    }
}