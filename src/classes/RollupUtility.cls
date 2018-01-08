/**
 * Created by mohandaas.rangaswamy on 12/15/2017.
 */

public class RollupUtility {

    public static boolean isRollupEnabled;

    static {

        system.debug('**** Initialization');

        AppConfiguration__c config = AppConfiguration__c.getInstance();
        if(config == null || config.Deactivate_Roll_up_Calculation__c == null){
            isRollupEnabled = true;
        } else{
            isRollupEnabled = !config.Deactivate_Roll_up_Calculation__c;
        }
    }

}