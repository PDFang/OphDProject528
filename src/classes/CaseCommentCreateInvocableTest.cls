/**
 * Created by jeremy.sparrell on 4/4/2018.
 */

@IsTest
private class CaseCommentCreateInvocableTest {
    @isTest static void createCaseCommentTest() {

        //set default assignment rule
        database.DMLOptions dmo = new database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;

        Case c = new Case();
        c.Subject = 'test case';
        c.setOptions(dmo);

        insert c;

        List<CaseCommentCreateInvocable.CommentInfo> commentInfos = new List<CaseCommentCreateInvocable.CommentInfo>();
        CaseCommentCreateInvocable.CommentInfo commentInfo = new CaseCommentCreateInvocable.CommentInfo();
        commentInfo.isPublic = true;
        commentInfo.commentBody = 'test comment';
        commentInfo.caseId = c.Id;

        commentInfos.add(commentInfo);

        Test.startTest();
        CaseCommentCreateInvocable.createCaseComment(commentInfos);

        Test.stopTest();

        List<CaseComment> comments = [SELECT Id, ParentId, CommentBody, IsPublished FROM CaseComment WHERE ParentId = :c.id];

        system.assertEquals(comments.size(), 1);
        system.assertEquals(comments[0].CommentBody, commentInfo.commentBody);
        system.assert(comments[0].IsPublished);
    }
}