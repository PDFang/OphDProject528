/**     ****** History Of Chnages *****
    User Story 14922:48155 - Help Desk Surveys Triggered on Case Closure 
        ** Added Recordtype Help Desk 
        ** Call Email service (CaseSendSurvey)
        ** Change Date - 12/22/2015
**/
trigger CaseBeforeUpdate on Case (before update)
{
    if(TriggerHandler.isBypassed('CaseTriggerHandler')){
        system.debug('By passed CaseBeforeUpdate trigger');
        return;
    }


    new CaseTriggerHandler().run();


}