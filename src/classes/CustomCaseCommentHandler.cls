/**
 * Created by william.nelson on 9/26/2017.
 */

public class CustomCaseCommentHandler extends TriggerHandler {

    public CustomCaseCommentHandler(){}

    protected override void afterInsert() {

        if (AllCommentTriggerHelper.hasAlreadyCreatedComments() == false) {
            List<casecomment> childcomment = new List<casecomment>();
            //system.debug('Trigger.new => ' + Trigger.new);
            for (Case_Comment_Custom__c t : (List<Case_Comment_Custom__c>) Trigger.new) {
                if (t.IsPublished__c == true){
                casecomment newcomment = new casecomment();
                newcomment.CommentBody = t.CommentBody__c;
                newcomment.IsPublished = t.IsPublished__c;
                //newCommmand.CreateDate = t.CommentCreatedDate__c;
                newcomment.ParentId = t.ParentId__c;
                childcomment.add(newcomment);
                system.debug('newcomment.new => ' + newcomment);
                }
            }
            system.debug('childCommand.new => ' + childcomment);
            if (!childcomment.isEmpty()) {
                insert childcomment;
            }
        }
    }
}