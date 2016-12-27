/**
 * Created by mohandaas.rangaswamy on 12/22/2016.
 */
public class SandboxPostCopy_AbortScheduledApex extends SandboxPostCopyTask{

    public override String getClassName(){
        return 'SandboxPostCopy_AbortScheduledApex';
    }

    public override void task(SandboxContext context){

        Id batchId = database.executeBatch(new DeleteScheduledApex());
        system.debug('task(): batchId - '+batchId);

    }
}