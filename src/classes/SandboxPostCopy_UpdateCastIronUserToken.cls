/**
 * Created by mohandaas.rangaswamy on 12/27/2016.
 */
// Update Cast Iron user email and security token
public with sharing class SandboxPostCopy_UpdateCastIronUserToken extends SandboxPostCopyTask{

    static final String CAST_IRON_USER_EMAIL = '_castiron@incontact.com';

    public override String getClassName(){
        return 'SandboxPostCopy_UpdateCastIronUserToken';
    }

    public override string task(SandboxContext context) {

        List<User> userList = [SELECT Id, Email FROM User where Username like '_castiron@incontact.com%'];
        if(userList.size() > 0){
            update new User(Id = userList[0].Id, Email = CAST_IRON_USER_EMAIL);
            system.setPassword(userList[0].Id, 'C@stiron1');
        }

        return null;

    } // end of task()

}