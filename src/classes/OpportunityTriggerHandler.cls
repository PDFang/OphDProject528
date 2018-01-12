/* =================================================================================================
*   Version     Date                   Comment
* =================================================================================================
*   1.0         15-Feb-2017           OpportunityTriggerHandler
*   1.1         21-Feb-2017           Changed functionality from Offering object to Opportunity object
**/
public with sharing class OpportunityTriggerHandler {

	//method to check if opportunity is updated
	public void checkOppIsUpdated(List<Opportunity> lstNewOpportunity, Map<Id,Opportunity> oldMap) {
		List<Opportunity> listOfUpdatedOpportunity = new List<Opportunity>();

		for(Opportunity objNewOpp : lstNewOpportunity) {
			Opportunity objOldOpp = oldMap.get(objNewOpp.id);

			if(objNewOpp.PersonalConnectionSeats__c != objOldOpp.PersonalConnectionSeats__c
			|| objNewOpp.Service_Package_MAT__c != objOldOpp.Service_Package_MAT__c
			|| objNewOpp.inContact_Setup_Fee__c != objOldOpp.inContact_Setup_Fee__c
			|| objNewOpp.Salesforce_Agent__c != objOldOpp.Salesforce_Agent__c
			|| objNewOpp.inContact_Ports__c != objOldOpp.inContact_Ports__c
			|| objNewOpp.ECHO__c != objOldOpp.ECHO__c
			|| objNewOpp.WFM__c != objOldOpp.WFM__c
			|| objNewOpp.Quality_Management__c != objOldOpp.Quality_Management__c
			|| objNewOpp.Screen__c != objOldOpp.Screen__c
			|| objNewOpp.Analytics__c != objOldOpp.Analytics__c
			|| objNewOpp.inContact__c != objOldOpp.inContact__c
			|| objNewOpp.inViewSeats__c != objOldOpp.inViewSeats__c
			|| objNewOpp.StageName != objOldOpp.StageName)
            {
				listOfUpdatedOpportunity.add(objNewOpp);
			}
		}
		updateOrInsertOpportunity(listOfUpdatedOpportunity);
	}

	//method to insert or update opportunity
	public void updateOrInsertOpportunity(List<Opportunity> lstOpportunity) {
		if (lstOpportunity.size() > 0) {
			for(Opportunity objOpp : lstOpportunity) {
				objOpp = insertValuesInFields(objOpp);
			}
		}
	}

	//method for populating values in Portfolio and Buying Stage fields
	public Opportunity insertValuesInFields(Opportunity objOpp) {
		//populate buying stage values on opportunity
		if(objOpp.StageName == 'N/A') {
			objOpp.Buying_Stage__c = 'UNI Thought Leadership';
		}
		else if(String.valueOf(objOpp.StageName) == '1 - Identification / Qualification') {
			objOpp.Buying_Stage__c = 'MQL Awareness';
		}
		else if(String.valueOf(objOpp.StageName) == '2 - Determining Problem / Impact') {
			objOpp.Buying_Stage__c = 'STAGE 2 Exploration';
		}
		else if(String.valueOf(objOpp.StageName) == '3 - Aligning Benefits & Value') {
			objOpp.Buying_Stage__c = 'STAGE 3 Alignment';
		}
		else if(String.valueOf(objOpp.StageName) == '4 - Confirm Value & Agreement') {
			objOpp.Buying_Stage__c = 'STAGE 4 Evaluation';
		}
		else if(String.valueOf(objOpp.StageName) == '5 - Proposal / Negotiation') {
			objOpp.Buying_Stage__c = 'STAGE 5 Commitment';
		}
		else if(String.valueOf(objOpp.StageName) == 'Closed – Won') {
			objOpp.Buying_Stage__c = 'CUST Use;CUST Renew and Expand;CUST Advocate';
		}

		//populate portfolio scope values on opportunity
		String portfolio = null;
		if(objOpp.inContact__c == 'YES') {
			portfolio = 'OmniChannel Routing; Customer Interaction Cloud';
		}
        
        if(objOpp.PersonalConnectionSeats__c > 0) {
			if(portfolio != null) {
				portfolio = portfolio + ';' + 'OmniChannel Routing';
			}
			else {
				portfolio = 'OmniChannel Routing';
			}
		}
        
		if(objOpp.ECHO__c == 'YES' || objOpp.WFM__c == 'YES' || objOpp.Quality_Management__c == 'YES' || objOpp.Screen__c == 'YES') {
			if(portfolio != null) {
				portfolio = portfolio + ';' + 'Workforce Optimization';
			}
			else {
				portfolio = 'Workforce Optimization';
			}
		}

		if(objOpp.Analytics__c == true || objOpp.inViewSeats__c > 0) {
			if(portfolio != null) {
				portfolio = portfolio + ';' + 'Analytics';
			}
			else {
				portfolio = 'Analytics';
			}
		}

		if(objOpp.Salesforce_Agent__c == true) {
			if(portfolio != null) {
				portfolio = portfolio + ';' + 'Open Cloud Platform';
			}
			else {
				portfolio = 'Open Cloud Platform';
			}
		}

		if(objOpp.inContact_Ports__c > 0) {
			if(portfolio != null) {
				portfolio = portfolio + ';' + 'Voice as a Service';
			}
			else {
				portfolio = 'Voice as a Service';
			}
		}

		if(objOpp.Service_Package_MAT__c > 0 || objOpp.inContact_Setup_Fee__c > 0) {
			if(portfolio != null) {
				portfolio = portfolio + ';' + 'Services';
			}
			else {
				portfolio = 'Services';
			}
		}

		/*Update 4/6/2017 - Derar A. 
		 * 
		 * if(objOpp.OSC__c == true || objOpp.iCA__c == true) {
		 *	if(portfolio != null) {
		 *		portfolio = portfolio + ';' + 'TBD';
		 *	}

		 *	else {
		 *		portfolio = 'TBD';
		 *	}
		}*/


        
        if(portfolio == null){
            portfolio = 'Omnichannel Routing; Customer Interaction Cloud';
            
        }
		objOpp.Portfolio_Scope__c = portfolio;
		return objOpp;
	}
}