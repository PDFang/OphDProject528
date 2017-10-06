/**
 * Created by arnab.karsarkar on 9/29/2017.
 */

public class LMAEDAOrderSubmissionQueueable implements Queueable {
	public set<id> newRecordIds;
	public set<id> oldRecordIds;
	public list<ProcessedRecord> recordList;

	public LMAEDAOrderSubmissionQueueable(set<id> cloneOrderIds, set<id> oldOrderIds){
		this.newRecordIds = cloneOrderIds;
		this.oldRecordIds = oldOrderIds;
		recordList = new list<ProcessedRecord>();
	}

	public void execute(QueueableContext context){

		list<EDA__c> cloneEDARecords = new list<EDA__c>([select Id,Name,Service_Order__c, Service_Order__r.Name, Status__c from EDA__c where Service_Order__c in : newRecordIds]);
		list<EDA__c> oldEDARecords = new list<EDA__c>([select Id,Name,Service_Order__c, Service_Order__r.Name, Status__c from EDA__c where Service_Order__c in : oldRecordIds]);

		System.debug('cloneEDARecords.size() ==>' + cloneEDARecords.size());

		for(integer i = 0; i < cloneEDARecords.size(); i++){
			try {
				System.debug('cloneEDARecords[i] ==>' + cloneEDARecords[i]);
				if (!Test.isRunningTest())
					CHANNEL_ORDERS.ServiceOrderProcessor.sendOrder(cloneEDARecords[i].Service_Order__c);
				oldEDARecords[i].Status__c = 'Processed';
				cloneEDARecords[i].Status__c = 'Submitted';
				ProcessedRecord record = new ProcessedRecord();
				record.EDAID = cloneEDARecords[i].Id;
				record.EDAName = cloneEDARecords[i].Name;
				record.ServiceOrderName = cloneEDARecords[i].Service_Order__r.Name;
				record.Status = 'Submitted';
				recordList.add(record);
				ProcessedRecord originalRecord = new ProcessedRecord();
				originalRecord.EDAID = cloneEDARecords[i].Id;
				originalRecord.EDAName = cloneEDARecords[i].Name;
				originalRecord.ServiceOrderName = cloneEDARecords[i].Service_Order__r.Name;
				originalRecord.Status = 'Processed';
				recordList.add(originalRecord);
			}Catch(Exception ex) {
				oldEDARecords[i].Status__c = 'Failed';
				cloneEDARecords[i].Status__c = 'Failed';
				ProcessedRecord failedRecord = new ProcessedRecord();
				failedRecord.EDAID = cloneEDARecords[i].Id;
				failedRecord.EDAName = cloneEDARecords[i].Name;
				failedRecord.ServiceOrderName = cloneEDARecords[i].Service_Order__r.Name;
				failedRecord.Status = 'Failed - Reason : ' + ex.getMessage();
				recordList.add(failedRecord);

				System.debug('ex =>' + ex.getMessage());
			}
		}

		system.debug('recordlist ==>' + recordList);


		update cloneEDARecords;
		update oldEDARecords;

		string emailbody = '<table align="center" border="1" cellpadding="0" cellspacing="0"><thead><th><b>EDA Id</b></th><th><b>Service Order Id</b></th><th><b>Status</b></th></thead><tbody>' ;
		String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
		for(ProcessedRecord record : recordList){
			String hrefValue = baseUrl + '/' + record.EDAID;
			emailbody += '<tr><td><a href="' + hrefValue + '">' + record.EDAName + '</a></td>';
			emailbody += '<td>' + record.ServiceOrderName + '</td>';
			emailbody += '<td>' + record.Status + '</td></tr>';
		}
		emailbody += '</tbody></table>';

		SendEmail('Processed Orders for LMA', emailbody);

	}



	private void SendEmail(string subject, string body){

		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		String OrgId15Digit = UserInfo.getOrganizationId().left(15);
		SiteConfiguration__c siteConfig = SiteConfiguration__c.getInstance(OrgId15Digit);
		String[] toAddresses = new String[]{};
		if(!Test.isRunningTest())
			toAddresses = new String[]{siteConfig.DeveloperErrorEmail__c};
		else
				toAddresses = new String[]{'test@Test.com'};
		mail.setToAddresses(toAddresses);
		mail.setSubject(subject);
		mail.setHtmlBody(body);
		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

	}

	public class ProcessedRecord{
		public string EDAID;
		public string EDAName;
		public string ServiceOrderName;
		Public string Status;
	}
}