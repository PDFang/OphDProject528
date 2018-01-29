/**
 * Created by Arnab KarSarkar on 1/22/2018.
 */
/// THIS IS WORK IN PROGRESS..NOT COMPLETED
@IsTest
public class xMNotificationHistoryControllerTest {


    public static void setup(){
        //setup test data

        Id rtCustOther = '01270000000Lrn4AAC';

        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.CadebillAccountNo__c = 9999999;
        acc.NICE_QM_Cluster__c = 'EN1';
        acc.NICE_WFM_Cluster__c = 'NWFM 1-2';
        acc.Verint_Cluster__c = 'V1';
        acc.inContact_Cluster__c =  'C9';

        insert acc;

        xmPerson__c person = new xmPerson__c(
                xmPersonUID__c = 'aefgh-1234-cdeft'
        );
        insert person;

      /*  Map<String, RecordTypeInfo> recordTypeMap = Schema.SObjectType.Contact.getRecordTypeInfosByName();
        Contact testContact = new Contact(
                FirstName = 'XMPersonManagementControllerTest',
                LastName = 'Contact',
                Email = 'contact1@incontact.com',
                RecordTypeId = recordTypeMap.get(CUSTOMER_CONTACT).getRecordTypeId(),
                AccountId = acc.Id,
                xmPerson__c = person.Id
        );

        insert testContact;*/


    }

}

