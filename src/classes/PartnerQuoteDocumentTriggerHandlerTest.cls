/**
*   This test class is used to cover code coverage for trigger - PartnerQuoteDocumentTrigger and
*   handler - PartnerQuoteDocumentTriggerHandler
*  
* ====================================================================================================
*     Version     Date          Comment
* ====================================================================================================
*     1.0         9-Feb-2017    - test class for class - PartnerQuoteDocumentTriggerHandler
*     1.1         14-Feb-2017   -
*      
**/

@isTest
public class PartnerQuoteDocumentTriggerHandlerTest {

  // Test data for Account
  public static Account createAccountTestData() {
    Account accRecord = new Account();
		accRecord.Name='Demo Account';
		return accRecord;
	}

	// Test data for Opportunity
  public static Opportunity createOpportunityTestData() {
		Account acc = createAccountTestData();
		insert acc;
  	Account accPartner = createAccountTestData();
		insert accPartner;

		Opportunity oppRecord = new Opportunity();
		oppRecord.Name = 'Demo Opportunity';
		oppRecord.AccountId = acc.Id;
    oppRecord.Partner_Account__c = accPartner.Id;
		oppRecord.Partner_Deal__c ='YES';
		oppRecord.CloseDate = date.parse('12/27/2017');
		oppRecord.StageName = '1 - Identification / Qualification';
		oppRecord.ForecastCategoryName = 'Commit';
		oppRecord.Contract_Type__c = 'New Customer';
		return oppRecord;
	}

	// Test data for Partner_Quote_Document__c
	public static List<Partner_Quote_Document__c> createPartnerQuoteDocumentTestData() {
	  List<Partner_Quote_Document__c> listPartnerQuoteDocument = new List<Partner_Quote_Document__c>();
		Opportunity opp = createOpportunityTestData();
		insert opp;
		for(Integer i=0;i<10;i++) {
			Partner_Quote_Document__c PartnerQuoteDocumentObj = new Partner_Quote_Document__c();
			PartnerQuoteDocumentObj.Opportunity__c=opp.Id;
			listPartnerQuoteDocument.add(PartnerQuoteDocumentObj);
		}
		return listPartnerQuoteDocument;
	}

	// to update the Partner_Quote_Document__c with Accepted
	@isTest
  static void updatePartnerQuoteDocumentAfterUpdate() {
    List<Partner_Quote_Document__c>  listPartnerQuoteDocumentRecords = createPartnerQuoteDocumentTestData();
    insert listPartnerQuoteDocumentRecords;
		Partner_Quote_Document__c changePQDToAccepted = [SELECT Id,Accepted__c FROM Partner_Quote_Document__c LIMIT 1];
		changePQDToAccepted.Accepted__c = true;

		System.Test.startTest(); // test starts here
		  update changePQDToAccepted; // update Record
		System.Test.stopTest(); // test stops here

    List<Partner_Quote_Document__c> listWithExpired = [SELECT Id,Accepted__c FROM Partner_Quote_Document__c
                                                        WHERE Expired__c = true];
		System.assertEquals(9,listWithExpired.size()); // assert
	}
}