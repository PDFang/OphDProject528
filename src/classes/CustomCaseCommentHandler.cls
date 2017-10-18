/**
 * Created by william.nelson on 9/26/2017.
 */

public class CustomCaseCommentHandler extends TriggerHandler {

    public CustomCaseCommentHandler(){}

    protected override void afterInsert() {

        if (AllCommentTriggerHelper.hasAlreadyCreatedComments() == false) {
            List<casecomment> childCommand = new List<casecomment>();
            //system.debug('Trigger.new => ' + Trigger.new);
            for (Case_Comment_Custom__c t : (List<Case_Comment_Custom__c>) Trigger.new) {
                if (t.IsPublished__c == true){
                    casecomment newCommmand = new casecomment();
                    newCommmand.CommentBody = t.CommentBody__c;
                    newCommmand.IsPublished = t.IsPublished__c;
                    //newCommmand.CreateDate = t.CommentCreatedDate__c;
                    newCommmand.ParentId = t.ParentId__c;
                    childCommand.add(newCommmand);
                }
            }
            system.debug('childCommand.new => ' + childCommand);
            if (!childCommand.isEmpty()) {
                insert childCommand;
            }
        }
    }
}