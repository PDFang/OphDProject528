public with sharing class XMattersServiceGroup {
    public String addMembersToGroup(String notificationGroupId) {
        XMattersServiceWrapper service = new XMattersServiceWrapper();

        //the service returns the notificationGroup Id that we passed to it
        //if the group is found
        //the rest of the processing happens after the call has returned
        String url = 'v1/NotificationGroup/' + notificationGroupId + '/members';
        String result = service.performCallOut(url, 'POST', null);

        return result;
    }
}