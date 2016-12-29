/**
 * Created by mohandaas.rangaswamy on 12/22/2016.
 */
public class SandboxPostCopy_AbortScheduledApex extends SandboxPostCopyTask{

    public override String getClassName(){
        return 'SandboxPostCopy_AbortScheduledApex';
    }

    public override string task(SandboxContext context){

        Id batchId = database.executeBatch(new AbortScheduledApexBatch(), 150);
        system.debug('task(): batchId - '+batchId);
        return batchId;
    }
}