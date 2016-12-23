/**
 * Created by mohandaas.rangaswamy on 12/21/2016.
 */

public with sharing class SandboxPostCopyImplementation //implements SandboxPostCopy
{
    public void runApexClass(SandboxContext context){
        List<Sandbox_Post_Copy_Task__mdt> postCopyTasks = [
                SELECT Id, DeveloperName, IsActive__c, Task_Order__c
                FROM Sandbox_Post_Copy_Task__mdt
                WHERE IsActive__c = true
                ORDER BY Task_Order__c
        ];
        system.debug('runApexClass(): postCopyTasks - ' + postCopyTasks);
        for(Sandbox_Post_Copy_Task__mdt mdt : postCopyTasks){
            Type t = Type.forName(mdt.DeveloperName);
            SandboxPostCopyTask task = (SandboxPostCopyTask) t.newInstance();
            task.execute(context);
        }
    }
}