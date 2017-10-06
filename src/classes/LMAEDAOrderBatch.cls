/**
 * Created by william.nelson on 8/21/2017.
 */

global class LMAEDAOrderBatch implements Database.Batchable<Sobject>, Database.Stateful, Database.AllowsCallouts  {

    private string queryString;
    private boolean exceptionOccured;

    //public List<> groupChangeRequestList;
    global LMAEDAOrderBatch(){
        this.queryString = 'SELECT License__c, Service_Order__c, Service_Order__r.Name from EDA__c where AutoSubmit__c = true and Status__c = \'In Queue\'';
        System.debug('queryString =>' + this.queryString);
        exceptionOccured = false;
    }

    global Database.QueryLocator start(Database.BatchableContext BC)
    {

        return Database.getQueryLocator(this.queryString);

    }

    global void execute(Database.BatchableContext BC, List<EDA__c> scope)
    {

        System.debug('scope.size() =>' + scope);

        if(scope != null && scope.size() == 1){
            for(EDA__c s : scope){
                EDA__c eda;
                try{

						string orderId = s.Service_Order__c;
                        string queryOrder = getCreatableFieldsSOQL('CHANNEL_ORDERS__Service_Order__c');
                        queryOrder += ' WHERE ' + 'Id =: orderId ';
						CHANNEL_ORDERS__Service_Order__c originalOrder = (CHANNEL_ORDERS__Service_Order__c)Database.query(queryOrder);
						CHANNEL_ORDERS__Service_Order__c cloneOrder = originalOrder.clone(false, true);
						cloneOrder.CHANNEL_ORDERS__Date_Partner_Received_Customer_Order__c = system.today();
						cloneOrder.CHANNEL_ORDERS__Date_Customer_Accepted_SFDC_Svc_Agrmnt__c = system.today();
                        cloneOrder.CHANNEL_ORDERS__Service_Start_Date__c = system.today();
						Database.SaveResult sr = Database.insert(cloneOrder);

						// indert clone order detail
						string queryOrderDetails = getCreatableFieldsSOQL('CHANNEL_ORDERS__Service_Order_Detail__c');
                        queryOrderDetails += ' WHERE ' + 'CHANNEL_ORDERS__Partner_Order__c =: orderId';
						CHANNEL_ORDERS__Service_Order_Detail__c orginalOrderDetail = (CHANNEL_ORDERS__Service_Order_Detail__c)Database.query(queryOrderDetails);
                        CHANNEL_ORDERS__Service_Order_Detail__c cloneOrderDetail = orginalOrderDetail.clone(false, true);
                        cloneOrderDetail.CHANNEL_ORDERS__Partner_Order__c = cloneOrder.Id;
						insert cloneOrderDetail;

						eda = new EDA__c(License__c = s.License__c,
								Service_Order__c = cloneOrder.Id,
								AutoSubmit__c = true,
								Status__c = 'Processed');

						insert eda;

	                    if(sr.isSuccess()){
		                    System.debug('sr ==> ' + sr.getId());
		                    System.enqueueJob(new LMAEDAOrderSubmissionQueueable(new set<id>{sr.getId()}, new set<id>{s.Service_Order__c}));
	                    }



                }
               Catch(Exception ex){
                   s.Status__c = 'Failed';
                   eda.Status__c = 'Failed';
                   inContactBaseClass.SendErrorEmail(ex, s.Id);
                   System.debug('ex =>' + ex.getMessage());
               }
                update eda;
            }

            update scope;


        }

    }

    global void finish(Database.BatchableContext BC)
    {
	    AsyncApexJob a = [Select Id, Status,ExtendedStatus,NumberOfErrors, JobItemsProcessed,
			    TotalJobItems, CreatedBy.Email   from AsyncApexJob where Id =:BC.getJobId()];
	    String OrgId15Digit = UserInfo.getOrganizationId().left(15);
	    SiteConfiguration__c siteConfig = SiteConfiguration__c.getInstance(OrgId15Digit);
	    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
	    String[] toAddresses;
	    if(!test.isRunningTest()){
		    toAddresses = new String[]{siteConfig.DeveloperErrorEmail__c};
		    mail.setSenderDisplayName(siteConfig.DeveloperErrorFromName__c);
	    }
	    else{
		    toAddresses = new String[]{'test@test.com'};
		    mail.setSenderDisplayName('Test Sender');
	    }

	    mail.setToAddresses(toAddresses);
	    mail.setSubject('LMA Order Batch ' + a.Status);
	    mail.setPlainTextBody('Records processed ' + a.TotalJobItems + ' with '+ a.NumberOfErrors + ' failures.');
	    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }

	// Returns a dynamic SOQL statement for the whole object, includes only creatable fields since we will be inserting a cloned result of this query
	private static string getCreatableFieldsSOQL(String objectName){

		String selects = '';

		//if (whereClause == null || whereClause == ''){ return null; }

		// Get a map of field name and field token
		Map<String, Schema.SObjectField> fMap = Schema.getGlobalDescribe().get(objectName.toLowerCase()).getDescribe().Fields.getMap();
		list<string> selectFields = new list<string>();

		if (fMap != null){
			for (Schema.SObjectField ft : fMap.values()){ // loop through all field tokens (ft)
				Schema.DescribeFieldResult fd = ft.getDescribe(); // describe each field (fd)
				if (fd.isCreateable()){ // field is creatable
					selectFields.add(fd.getName());
				}
			}
		}

		if (!selectFields.isEmpty()){
			for (string s:selectFields){
				selects += s + ',';
			}
			if (selects.endsWith(',')){selects = selects.substring(0,selects.lastIndexOf(','));}

		}

		return 'SELECT ' + selects + ' FROM ' + objectName;

	}


}