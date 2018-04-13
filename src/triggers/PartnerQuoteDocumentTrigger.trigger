/**
*   This trigger is used to update all Partner Quote Document record as Rejected
*  
* ====================================================================================================
*     Version     Date          Comment
* ====================================================================================================
*     1.0         9-Feb-2017    - Check for criteria - Accepted=true. If matches, fetch all existing
*                                 Partner Quote Document records of current record's Opportunity and
*                                 set them as Rejected=true.
*      
**/
Trigger PartnerQuoteDocumentTrigger on Partner_Quote_Document__c (After Update,After Insert) {
  // After Update of the Partner_Quote_Document__c record
  if(Trigger.isUpdate && Trigger.isAfter) {
    PartnerQuoteDocumentTriggerHandler.updatePartnerQuoteDocumentAfterUpdate(Trigger.new,Trigger.oldMap);
  }
  // After Insert of Partner_Quote_Document__c record
  if(Trigger.isInsert && Trigger.isAfter) {
    PartnerQuoteDocumentTriggerHandler.updatePartnerQuoteDocumentAfterInsert(Trigger.new);
  }
}