/**
 * Created by mohandaas.rangaswamy on 12/21/2016.
 */

public with sharing abstract class SandboxPostCopyTask {

    protected abstract String getClassName();

    // class extension must implement this method and include post copy logic
    protected abstract void task(SandboxContext context);

    // this method wraps the abstract  method
    public void execute(SandboxContext context){

        Sandbox_Post_Copy_Log__c log = new Sandbox_Post_Copy_Log__c();
        log.Class_Name__c = getClassName();
        try {
            task(context);
            log.Status__c = 'Success';
        } catch (Exception ex){
            system.debug(this);
            system.debug(ex);
            log.Status__c = 'Failed';
            log.Status__c = ex.getMessage();
        }
        insert log;
    }

}