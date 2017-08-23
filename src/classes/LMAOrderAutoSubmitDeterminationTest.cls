/**
 * Created by arnab.karsarkar on 8/23/2017.
 */
@istest
public class LMAOrderAutoSubmitDeterminationTest {

	public static void setup(){

		list<Account> accounts = new list<Account> ();
		for(integer i = 0; i < 3; i++ ){
			accounts.add(new Account(Name = 'test' + i,
					BillingCity = 'SLC',
					BillingState = 'UT',
					BillingCountry = 'US',
					BillingStreet = 'test street' + i,
					BillingPostalCode = '12345' + i
			));
		}

		insert accounts;

		//Create package
		sfLma__Package__c pack = new sfLma__Package__c(
				Name = 'test',
				sfLma__Developer_Name__c = 'test',
				sfLma__Developer_Org_ID__c = 'abc',
				sfLma__Latest_Version__c = '3',
				sfLma__Lead_Manager__c = UserInfo.getUserId(),
				sfLma__Package_ID__c = '3',
				sfLma__Release_Date__c = system.today().addDays(-30)
		);
		insert pack;

		//Create a package version
		sfLma__Package_Version__c packVersion = new sfLma__Package_Version__c(
				Name = 'test',
				sfLma__Package__c = pack.id,
				sfLma__Is_Beta__c = false,
				sfLma__Release_Date__c = system.today(),
				sfLma__Sequence__c = 1,
				sfLma__Version__c = '3.1.2',
				sfLma__Version_ID__c = '3.1.2'
		);
		insert packVersion;

		//Ceate a license record

		Id recordTypeIdTrial = [select Id from RecordType where Name = 'Trial' and SobjectType = 'sfLma__License__c'].Id;
		list<sfLma__License__c> licenses = new list<sfLma__License__c> ();
		for(integer i = 0; i < 3; i++ ){
			licenses.add(new sfLma__License__c(
					RecordTypeId = recordTypeIdTrial,
					sfLma__Status__c = 'Trial',
					sfLma__Seats__c = 10,
					//sfLma__Used_Licenses__c = 10,
					sfLma__License_Type__c = 'Editable',
					sfLma__Account__c = accounts[i].Id,
					sfLma__Expiration__c = Date.newInstance(1970, 1, 1),// system.today().addDays(365),
					sfLma__Install_Date__c = system.today(),
					sfLma__Package_Version__c = packVersion.Id,
					sfLma__Org_Instance__c = 'NA1',
					sfLma__Version_Number__c = '1',
					sfLma__Proxy_User__c = '033i0000000ty0uaas@00ds0000003eehamaw'
			));
		}

		licenses[0].sfLma__Subscriber_Org_ID__c = '00D5B0000008bOp';
		licenses[1].sfLma__Subscriber_Org_ID__c = '00D4B0000009HnJ';
		licenses[2].sfLma__Subscriber_Org_ID__c = '00Di0000000b4hc';

		insert licenses;

		// insert Contract
		CHANNEL_ORDERS__Partner_Contract_Terms__c cont = new CHANNEL_ORDERS__Partner_Contract_Terms__c(
				Name = 'inContact_ISVForce_USD',
				CHANNEL_ORDERS__Partner_API_Key__c = 'a7bdgbdjbgf84',
				CHANNEL_ORDERS__Default_Contract_Currency__c = 'USD'
		);

		insert cont;

		CHANNEL_ORDERS__Partner_Product_Catalog__c prod = new CHANNEL_ORDERS__Partner_Product_Catalog__c(
				Name = 'ISVForce inContact Agent Console (Per User)',
				CHANNEL_ORDERS__Product_ID__c = 'test',
				CHANNEL_ORDERS__Partner_Contract_Terms__c = cont.Id
		);

		insert prod;




	}

	public static testmethod void orderAutoSubmissionTest(){
		setup();


		Id recordTypeId = [select Id from RecordType where Name = 'Active' and SobjectType = 'sfLma__License__c'].Id;
		list<sfLma__License__c> licenses = new list<sfLma__License__c>([select Id, sfLma__Status__c, sfLma__Subscriber_Org_ID__c, RecordTypeId from sfLma__License__c]);

		licenses[0].sfLma__Status__c = 'Active';
		licenses[0].RecordTypeId = recordTypeId;
		// update first License - Initial order
		update licenses[0];


		// Add on
		for(sfLma__License__c license1 : [select Id,sfLma__Seats__c from sfLma__License__c where id = : licenses[0].id]){
			license1.sfLma__Seats__c = 15;
			update license1;
		}


		// Reduction
		for(sfLma__License__c license1 : [select Id, sfLma__Seats__c from sfLma__License__c where id = : licenses[0].id]){
			license1.sfLma__Seats__c = 10;
			update license1;
		}


		for(CHANNEL_ORDERS__Service_Order_Detail__c sod1 :[select Id, CHANNEL_ORDERS__Quantity__c from CHANNEL_ORDERS__Service_Order_Detail__c
															where CHANNEL_ORDERS__Partner_Order__r.CHANNEL_ORDERS__Customer_Org_ID__c = :licenses[0].sfLma__Subscriber_Org_ID__c])
		{
			//system.debug('channel orders for license 1 ====>' + sod1);
			Test.setCreatedDate(sod1.Id, System.now().addDays(-4));
		}

		Test.startTest();
		// Another add on after cutoff date
		for(sfLma__License__c license1 : [select Id, sfLma__Seats__c from sfLma__License__c where id = : licenses[0].id]){
			license1.sfLma__Seats__c = 15;
			update license1;
		}

		// Another reduction after cutoff date
		for(sfLma__License__c license1 : [select Id, sfLma__Seats__c from sfLma__License__c where id = : licenses[0].id]){
			license1.sfLma__Seats__c = 10;
			update license1;
		}

		list<sfLma__License__c> sfLicenses = new list<sfLma__License__c>();
		for(integer i = 1; i < licenses.size(); i++){
			licenses[i].sfLma__Status__c = 'Active';
			licenses[i].RecordTypeId = recordTypeId;
			sfLicenses.add(licenses[i]);
		}

		LMAHelperClass.isLMAHelperClassCalled = false;
		update sfLicenses;



		// Other current licenses.
		sfLicenses[0].sfLma__Seats__c = 15;
		sfLicenses[1].sfLma__Seats__c = 5;

		update sfLicenses;


		CHANNEL_ORDERS__Service_Order_Detail__c sod2= [select Id, CHANNEL_ORDERS__Quantity__c, CHANNEL_ORDERS__Partner_Order__r.CHANNEL_ORDERS__Order_Type__c, CHANNEL_ORDERS__Partner_Order__c from CHANNEL_ORDERS__Service_Order_Detail__c
														where CHANNEL_ORDERS__Partner_Order__r.CHANNEL_ORDERS__Customer_Org_ID__c = :licenses[2].sfLma__Subscriber_Org_ID__c
															 and CHANNEL_ORDERS__Partner_Order__r.CHANNEL_ORDERS__Order_Type__c = 'Reduction'];

		System.debug('sod2 ==> ' + sod2.CHANNEL_ORDERS__Partner_Order__r.CHANNEL_ORDERS__Order_Type__c);
		set<id> soIds = LMAHelperClass.orderSubmitDetermination(false);

		EDA__c eda = [select Id, AutoSubmit__c from EDA__c where Service_Order__c =: sod2.CHANNEL_ORDERS__Partner_Order__c];
		System.assertEquals(true, eda.AutoSubmit__c);
		Test.stopTest();

	}


}