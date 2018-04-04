global class CaseCommentCreateInvocable {

    @InvocableMethod(label='Create Case Comment')
    global static void createCaseComment(List<CommentInfo> commentInfos){
        List<CaseComment> caseComments = new List<CaseComment>();

        for(CommentInfo c:commentInfos){
            CaseComment cc = new CaseComment();
            cc.CommentBody = c.commentBody;
            cc.IsPublished = c.isPublic;
            cc.ParentId = c.caseId;

            caseComments.add(cc);
        }

        insert caseComments;
    }

    global class CommentInfo{

        @InvocableVariable(label='Case ID' required=true)
        public string caseId;

        @InvocableVariable(label='Comment Body' required=true)
        public string commentBody;

        @InvocableVariable(required=true)
        public boolean isPublic;
    }
}