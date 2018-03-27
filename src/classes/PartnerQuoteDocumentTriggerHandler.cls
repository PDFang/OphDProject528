/**
*   This handler is used for trigger - PartnerQuoteDocumentTrigger to update all Partner Quote
*   Document record as Rejected
*  
* ====================================================================================================
*     Version     Date          Comment
* ====================================================================================================
*     1.0         9-Feb-2017    - Check for criteria - Accepted=true. If matches, fetch all existing
*                                 Partner Quote Document records of current record's Opportunity and
*                                 set them as Rejected=true.
*     1.1         14-Feb-2017   - If existing Partner Quote Document records of current record's
*                                 Opportunity are Accepted=true, set them as Accepted=false first
*                                 and then set them as Rejected=true.
*     1.2         23-Aug-2017   - Set Partner Quote Document records as 'Expired' = True instead of 'Rejected' = True.
*                                 
*      
**/
public class PartnerQuoteDocumentTriggerHandler {
  // To get records to update after  Partner_Quote_Document__c is inserted
  public static void updatePartnerQuoteDocumentAfterInsert(List<Partner_Quote_Document__c> listPartnerQuoteDocument) {
    Set<Id> setOpportunityIds = new Set<Id>();
    Set<Id> setPartnerQuoteDocumentIds = new Set<Id>();
    for(Partner_Quote_Document__c objPartnerQuoteDocument : listPartnerQuoteDocument) {
      if(objPartnerQuoteDocument.Accepted__c == True) {
        setOpportunityIds.add(objPartnerQuoteDocument.Opportunity__c);
        setPartnerQuoteDocumentIds.add(objPartnerQuoteDocument.Id);
      }
    }

    // method to update Partner_Quote_Document__c records
    updatePartnerQuoteDocument(setOpportunityIds,setPartnerQuoteDocumentIds);
  }

  // To get records to update after  Partner_Quote_Document__c is updated
  public static void updatePartnerQuoteDocumentAfterUpdate(List<Partner_Quote_Document__c> listPartnerQuoteDocument,Map<Id,Partner_Quote_Document__c> mapOldPartnerQuoteDocument) {
    Set<Id> setOpportunityIds = new Set<Id>();
    Set<Id> setPartnerQuoteDocumentIds = new Set<Id>();
      for(Partner_Quote_Document__c objPartnerQuoteDocument : listPartnerQuoteDocument) {
        if(objPartnerQuoteDocument.Accepted__c == True
        && mapOldPartnerQuoteDocument.get(objPartnerQuoteDocument.Id).Accepted__c == False) {
          setOpportunityIds.add(objPartnerQuoteDocument.Opportunity__c);
          setPartnerQuoteDocumentIds.add(objPartnerQuoteDocument.Id);
        }
      }

      // method to update Partner_Quote_Document__c records
      updatePartnerQuoteDocument(setOpportunityIds,setPartnerQuoteDocumentIds);
  }

  // To Update Partner_Quote_Document__c record
  public static void updatePartnerQuoteDocument(Set<Id> setOpportunityIds, Set<Id> setPartnerQuoteDocumentIds) {
    List<Partner_Quote_Document__c> listToUpdatePQD = new List<Partner_Quote_Document__c>();

    for(Partner_Quote_Document__c objPartnerQuoteDocument : [SELECT Id,Rejected__c,Expired__c,Opportunity__c,Accepted__c
                                                             FROM Partner_Quote_Document__c
                                                             WHERE Opportunity__c IN : setOpportunityIds
                                                             AND Id NOT IN : setPartnerQuoteDocumentIds
                                                             AND Expired__c = false
    ]) {

      objPartnerQuoteDocument.Expired__c = true;
      if(objPartnerQuoteDocument.Accepted__c) {
        objPartnerQuoteDocument.Accepted__c = false;
      }
      listToUpdatePQD.add(objPartnerQuoteDocument);
    }

    // updating Partner_Quote_Document__c records
    if(listToUpdatePQD != null && listToUpdatePQD.size() > 0) {
      List<Database.SaveResult> saveResultList = Database.update(listToUpdatePQD,False);
    }
  }
}