/**
 * Created by mohandaas.rangaswamy on 12/22/2016.
 */
public class SandboxPostCopy_DeleteScheduledApex extends SandboxPostCopyTask{

    public override String getClassName(){
        return 'SandboxPostCopy_DeleteScheduledApex';
    }

    public override void task(SandboxContext context){

        Id batchId = database.executeBatch(new DeleteScheduledApex());
        system.debug('task(): batchId - '+batchId);

    }
}