/**
 * Created by mohandaas.rangaswamy on 12/22/2016.
 */
public class SandboxPostCopy_UpdateServiceConnection extends SandboxPostCopyTask{

    public override String getClassName(){
        return 'SandboxPostCopy_UpdateServiceConnection';
    }

    public override void task(SandboxContext context){

        ServiceConnection__c accountSync = ServiceConnection__c.getInstance('AccountSync');
        if(accountSync != null && accountSync.EndPoint__c != null){
            if(context.sandboxName() == 'QA'){
                accountSync.EndPoint__c = accountSync.EndPoint__c.replace(System.LABEL.Corp_Proxy, System.LABEL.QA_Proxy);
            }else{
                accountSync.EndPoint__c = accountSync.EndPoint__c.replace(System.LABEL.Corp_Proxy, System.LABEL.LAB_Proxy);
            }
            accountSync.Username__c = null;
            accountSync.Password__c = null;
            update accountSync;
        }
        system.debug('task(): accountSync - '+accountSync);

    }
}