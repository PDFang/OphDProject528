@isTest
public class XMRestPersonTests {
    public static testMethod void createPerson_WillReturnCorrectJson(){
        XMRestPeopleMockHttpGenerator httpMock = new XMRestPeopleMockHttpGenerator(200,'Complete','[{"Name": "sForceTest1"}]',null);

        XMPersonModel person = new XMPersonModel();
        person.firstName = 'Bob';
        person.lastName = 'Marly';


        test.startTest();

        Test.setMock(HttpCalloutMock.class, httpMock);
        XMRestPerson service = new XMRestPerson();

        XMPersonModel createdRecord = service.createPerson(person);

        test.stopTest();

        // System should automatically create this as externally owned since this is coming from salesforce
        system.assert(createdRecord.externallyOwned, 'createPerson_WillReturnCorrectJson() - Extermally Owned not true ');
        system.assertEquals(createdRecord.firstName, person.firstName);
        system.assertEquals(createdRecord.lastName, person.lastName);
        system.assert(createdRecord.recipientType == 'PERSON');
    }

    public static testMethod void getXmPersonModelByXmattersId_ReturnsCorrectPerson(){
        XMRestPeopleMockHttpGenerator httpMock = new XMRestPeopleMockHttpGenerator(200,'Complete','[{"Name": "sForceTest1"}]',null);

        XMPersonModel person = new XMPersonModel();
        person.firstName = 'Bob';
        person.lastName = 'Marly';


        test.startTest();

        Test.setMock(HttpCalloutMock.class, httpMock);
        XMRestPerson service = new XMRestPerson();

        XMPersonModel createdRecord = service.createPerson(person);

        test.stopTest();

        // System should automatically create this as externally owned since this is coming from salesforce
        system.assert(createdRecord.externallyOwned, 'createPerson_WillReturnCorrectJson() - Extermally Owned not true ');
        system.assertEquals(createdRecord.firstName, person.firstName);
        system.assertEquals(createdRecord.lastName, person.lastName);
        system.assert(createdRecord.recipientType == 'PERSON');
    }
}