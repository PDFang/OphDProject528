/**
 * Created by mohandaas.rangaswamy on 12/21/2016.
 */

public with sharing abstract class SandboxPostCopyTask {

    public class SandboxPostCopyTaskException extends Exception{}

    protected abstract String getClassName();

    // class extension must implement this method and include post copy logic
    protected abstract string task(SandboxContext context);

    // this method wraps the abstract  method
    public void execute(SandboxContext context){

        Sandbox_Post_Copy_Log__c log = new Sandbox_Post_Copy_Log__c();
        log.Class_Name__c = getClassName();
        try {
            log.Async_Job_ID__c = task(context);
            log.Status__c = 'Success';
        } catch (Exception ex){
            system.debug('execute(): this - '+ this);
            system.debug('execute() exception - '+ ex);
            log.Status__c = 'Failed';
            log.Status__c = ex.getMessage();
        }
        insert log;
    }

    protected boolean allowFutureCall(){
        if(Limits.getFutureCalls() == Limits.getLimitFutureCalls()){
            throw new SandboxPostCopyTaskException('Future method call limit has been reached.');
        }
        return true;
    }

    protected boolean allowCallout(){
        if(Limits.getCallouts() == Limits.getLimitCallouts()){
            throw new SandboxPostCopyTaskException('Callout limit has been reached.');
        }
        return true;
    }

}