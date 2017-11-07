/**
 * Created by william.nelson on 11/7/2017.
 */
@isTest
public with sharing class CustomCaseCommentAddControllerTest {

        private static case newCase = new case();
        private static Id MyID;
        private static void initTest(){


            Account a = new Account();
            a.Name = 'testName';
            a.Site = 'Test';
            a.CS_AM__c = UserInfo.getUserId();


            Case newCase = new Case();

            string caseSubject = 'Test Articles';
            string strDesc = 'test description';
            string strEnv = 'WFO - Discover' + '<br/>' + 'Fusion Desktop Analytics' + '<br/>' + '';

            //set default assignment rule
            database.DMLOptions dmo = new database.DMLOptions();
            dmo.assignmentRuleHeader.useDefaultRule = true;


            //create test case
            newCase.AccountId = a.Id;
            newCase.Subject = caseSubject;
            newCase.EventType__c = 'Service Disruption';
            newCase.Product_or_Service__c = 'WFO - Discover';
            newCase.Status = 'New';
            newCase.SubProductorService__c = 'Fusion Desktop Analytics';
            newCase.Priority = 'P1';
            newCase.Description = strDesc;
            newCase.setOptions(dmo);

            insert newCase;

            //set default assignment rule
            //dmo.assignmentRuleHeader.useDefaultRule = true;
            //newCase.setOptions(dmo);
            CaseComment comment = new CaseComment();
            comment.CommentBody = 'test';
            comment.ParentId = newCase.Id;
            MyID = newCase.Id;
            system.debug (' ** case Id  ==>' + newCase.Id);
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
        public static void testInint(){
            CustomCaseCommentAddController controller = new CustomCaseCommentAddController();

        }

        @isTest
        public static void CancelCreate(){
            initTest();
            test.startTest();
            ApexPages.StandardController stdCtrl = new ApexPages.StandardController(newCase);


            CustomCaseCommentAddController controller = new CustomCaseCommentAddController();
            controller.redirectUrl = 'http://www.salesforce.com';
            controller.CancelCreate();
            test.stopTest();
        }
        @isTest
        public static void CreatePrivateComment(){

            initTest();
            test.startTest();
            ApexPages.StandardController stdCtrl = new ApexPages.StandardController(newCase);
            CustomCaseCommentAddController controller = new CustomCaseCommentAddController(stdCtrl);
            controller.redirectUrl = 'http://www.salesforce.com';
            controller.commentBody = 'Test';
            controller.caseId = MyID;
            controller.isPublic = false;
            controller.createComment();
            test.stopTest();
        }

        @isTest
        public static void  CreateComment(){

            test.startTest();
            initTest();
            ApexPages.StandardController stdCtrl = new ApexPages.StandardController(newCase);
            CustomCaseCommentAddController controller = new CustomCaseCommentAddController(stdCtrl);
            controller.redirectUrl = 'http://www.salesforce.com';
            controller.commentBody = 'Test';
            controller.isPublic = true;
            controller.caseId = MyID;
            system.debug('***Test***');
            system.debug('controller ==> ' + MyID);
            controller.createComment();
            test.stopTest();
        }

}