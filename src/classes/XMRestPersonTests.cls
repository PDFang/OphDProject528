@isTest
public class XMRestPersonTests {
    public static testMethod void createPerson_WillReturnCorrectJson(){
        XMRestPeopleMockHttpGenerator httpMock = new XMRestPeopleMockHttpGenerator(200,'Complete','[{"Name": "sForceTest1"}]',null);

        XMPersonModel person = new XMPersonModel();
        person.firstName = 'Bob';
        person.lastName = 'Marly';
        person.targetName = 'TBD';
        person.externallyOwned = true;
        person.status = 'TESTED';
        person.externalKey = 'DoesntMatter';


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

    // Testing getting a record
    public static testMethod void getXmPersonModelByXmattersId_ReturnsCorrectPerson(){
        XMRestPeopleMockHttpGenerator httpMock = new XMRestPeopleMockHttpGenerator(200,'Complete','[{"Name": "sForceTest1"}]',null);

        XMPersonModel person = new XMPersonModel();
        person.firstName = 'Bob';
        person.lastName = 'Marly';


        test.startTest();

        Test.setMock(HttpCalloutMock.class, httpMock);
        XMRestPerson service = new XMRestPerson();

        XMPersonModel createdRecord = service.getXmPersonModelByXmattersId('testId');

        test.stopTest();

        // System should automatically create this as externally owned since this is coming from salesforce
        system.assert(createdRecord.externallyOwned, 'createPerson_WillReturnCorrectJson() - Extermally Owned not true ');
        system.assertEquals(createdRecord.firstName, person.firstName);
        system.assertEquals(createdRecord.lastName, person.lastName);
        system.assert(createdRecord.recipientType == 'PERSON');
        system.assert('1451a630-4d44-46e6-84ba-6b966dbfa715' == createdRecord.id);
    }

    public static testMethod void modifyPerson_WillReturnCorrectJson(){
        XMRestPeopleMockHttpGenerator httpMock = new XMRestPeopleMockHttpGenerator(200,'Complete Inactivate','[{"Name": "sForceTest1","Status":"INACTIVE"}]',null);

        XMPersonModel person = new XMPersonModel();
        person.id = 'test';
        person.status = 'INACTIVE';


        test.startTest();

        Test.setMock(HttpCalloutMock.class, httpMock);
        XMRestPerson service = new XMRestPerson();

        XMPersonModel modifiedRecord = service.modifyPerson(person);

        test.stopTest();

        // System should automatically create this as externally owned since this is coming from salesforce
        system.assertEquals('INACTIVE', modifiedRecord.status);

    }

    public static testMethod void createPerson_FailureCodeWillThrowCorrectException(){
        XMRestPeopleMockHttpGenerator httpMock = new XMRestPeopleMockHttpGenerator(415,'Complete','[{"Name": "sForceTest1"}]',null);
        XMCalloutException testException = null;

        XMPersonModel person = new XMPersonModel();
        person.firstName = 'Bob';
        person.lastName = 'Marly';
        person.targetName = 'TBD';
        person.externallyOwned = true;
        person.status = 'TESTED';
        person.externalKey = 'DoesntMatter';


        test.startTest();

        Test.setMock(HttpCalloutMock.class, httpMock);
        XMRestPerson service = new XMRestPerson();

        try{
            XMPersonModel createdRecord = service.createPerson(person);
        } catch(XMCalloutException calloutException){
            testException = calloutException;
        }

        test.stopTest();

        system.assert(415 == testException.HttpStatusCode, 'Http Status code does not match expected');
        system.assert('Could not process request.' == testException.getMessage());
    }
}