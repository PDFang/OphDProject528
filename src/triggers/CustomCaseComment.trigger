/**
 * Created by william.nelson on 9/25/2017.
 */

trigger CustomCaseComment on Case_Comment_Custom__c (after insert) {
    new CustomCaseCommentHandler().run();
}