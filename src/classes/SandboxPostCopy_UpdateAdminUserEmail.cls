/**
 * Created by mohandaas.rangaswamy on 12/27/2016.
 */
// Update IS admin users email
public with sharing class SandboxPostCopy_UpdateAdminUserEmail extends SandboxPostCopyTask{

    public override String getClassName(){
        return 'SandboxPostCopy_UpdateAdminUserEmail';
    }

    public override string task(SandboxContext context) {

        List<User> userList = new List<User>();
        for(User admin : [
                SELECT Id, Email FROM User
                where Profile.Name IN ('System Administrator-CRM','System Administrator')
                and Department = 'Information Systems 00' and IsActive = true
        ]){
            String email = admin.Email;
            if(email.endsWith('@example.com') && email.indexOf('=') > 0){
                email = email.left(email.indexOf('@'));
                admin.Email = email.replace('=','@');
                userList.add(admin);
            }
        }

        if(userList.size() > 0){
            system.debug('task(): userList - ' + userList);
            update userList;
        }

        return null;

    } // end of task()

}