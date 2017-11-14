@isTest
public with sharing class CustomCaseCommentControllerTest {

    private static case newCase = new case();
    private static id MyCase;
    private static void initTest(){

        Case newCase = new Case();
        newCase.Subject = 'subject';
        newCase.Steps_to_Recreate__c = 'steps to recreate';
        newCase.EventType__c = 'Service Disruption';
        newCase.TfsItemState__c = 'state';
        newCase.ProductImpacted__c = 'product';
        newCase.PlatformsImpacted__c = 'platforms';

        //set default assignment rule
        database.DMLOptions dmo = new database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        newCase.setOptions(dmo);

        insert newCase;
        MyCase = newCase.Id;

        CaseComment comment = new CaseComment();
        comment.CommentBody = 'test';
        comment.ParentId = newCase.id;
        insert comment;
        CustomCaseCommentData commentData = new CustomCaseCommentData();
        commentData.ParentId = newCase.Id;
        commentData.isPublic = false;
        commentData.CaseComment = 'test';
        Case_Comment_Custom__c customComment =  new Case_Comment_Custom__c();
        customComment.ParentId__C = newCase.id;
        insert customComment;

    }

    @isTest
    public static void getCommentList ( ){

        initTest();
        test.startTest();
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(newCase);
        CustomCaseCommentController controller  = new CustomCaseCommentController(stdCtrl);
        controller.getCommentList(newCase);
        test.stopTest();
    }

    @isTest
    public static void saveAction(){
        initTest();
        test.startTest();
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(newCase);
        CustomCaseCommentController controller  = new CustomCaseCommentController(stdCtrl);

        CustomCaseCommentData commentData = new CustomCaseCommentData();
        commentData.isPublic = true;
        commentData.ParentId = MyCase;
        commentdata.isDeleted = false;
        commentData.CreateDate = DateTime.now();
        commentdata.CreatedBy = 'Test';
        commentData.CaseComment = 'test';
        controller.SaveAction(commentData);
        test.stopTest();
    }
    @isTest
    public static void NewPublicComment()
    {
        initTest();
        test.startTest();
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(newCase);
        CustomCaseCommentController controller = new CustomCaseCommentController(stdCtrl);
        controller.NewPublicComment();
        test.stopTest();
    }
    @isTest
    public static void NewPrivateComment()
    {
        initTest();
        test.startTest();
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(newCase);
        CustomCaseCommentController controller = new CustomCaseCommentController(stdCtrl);
        controller.NewPrivateComment();
        test.stopTest();
    }

    @isTest
    public static void CancelAction(){
        initTest();
        test.startTest();
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(newCase);
        CustomCaseCommentController controller = new CustomCaseCommentController(stdCtrl);
        controller.CancelAction();
        test.stopTest();
    }
}