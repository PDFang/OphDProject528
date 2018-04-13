/**
 * Created by arnab.karsarkar on 2/26/2018.
 */
@IsTest
public class LeadCloneExtentionTest {

	public static testMethod void TestLeadCloneExtension()
	{
	//create new lead for test
			Lead l = new Lead();
			l.FirstName = 'test';
			l.LastName = 'test';
			l.Email = 'test@incontact.com';
			l.Company = 'inContact';

			insert l;

			ApexPages.StandardController stdCtrl = new ApexPages.StandardController(l);
			LeadCloneExtention lc = new LeadCloneExtention(stdCtrl);

	//lc.cloneLead.LastName = 'test';
			lc.Save();

	}

}