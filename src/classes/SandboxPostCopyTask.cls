/**
 * Created by mohandaas.rangaswamy on 12/21/2016.
 */

public with sharing abstract class SandboxPostCopyTask {

    // class extension must implement this method and include post copy logic
    protected abstract void task(SandboxContext context);

    // this method wraps the abstract  method
    public void execute(SandboxContext context){
        try {
            task(context);
        } catch (Exception ex){
            system.debug(this);
            system.debug(ex);
        }
    }

}