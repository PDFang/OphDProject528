/**
 * Created by mohandaas.rangaswamy on 3/6/2017.
 */

trigger CaseCommentTrigger on CaseComment (before insert, before update, after insert, after update) {

    new CaseCommentTriggerHandler().run();

}