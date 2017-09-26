/**
 * Created by william.nelson on 9/25/2017.
 */

trigger CustomCaseComment on Case_Comment_Custom__c (after insert) {

    List<casecomment> childCommand = new List<casecomment>();
    //system.debug('Trigger.new => ' + Trigger.new);
    for (Case_Comment_Custom__c t: Trigger.new){
        casecomment newCommmand = new casecomment();
        newCommmand.CommentBody = t.CommentBody__c;
        newCommmand.IsPublished = t.IsPublished__c;
        //newCommmand.CreateDate = t.CommentCreatedDate__c;
        newCommmand.ParentId = t.ParentId__c;
        childCommand.add(newCommmand);
    }
    system.debug('childCommand.new => ' + childCommand);
    if(!childCommand.isEmpty()){
        insert childCommand;
    }

}