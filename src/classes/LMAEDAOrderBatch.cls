/**
 * Created by william.nelson on 8/21/2017.
 */

global class LMAEDAOrderBatch implements Database.Batchable<Sobject>, Database.Stateful, Database.AllowsCallouts  {

    private string queryString;
    private boolean exceptionOccured;
    global List<String> processedServiceOrderIds = new List<String>();
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

        //try{
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
							insert cloneOrder;

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

							if(!Test.isRunningTest())
								CHANNEL_ORDERS.ServiceOrderProcessor.sendOrder(cloneOrder.Id);
							s.Status__c = 'Processed';
	                        eda.Status__c = 'Submitted';
							processedServiceOrderIds.Add(s.Service_Order__r.Name);
							System.debug('s.Status__c processed =>' + s.Status__c);


                    }
                   Catch(Exception ex){
                       s.Status__c = 'Failed';
	                   eda.Status__c = 'Failed';
                       System.debug('s.Status__c falied =>' + s.Status__c);

                       System.debug('ex =>' + ex.getMessage());
                   }
	                update eda;
                }

                update scope;
            }
//        }Catch(Exception ex){
//            exceptionOccured = true;
//            String body = 'An error occured - ' + ex.getMessage() + ' at the stack ' + ex.getStackTraceString();
//            SendEmail('Error Occured in Batch Class - LMAEDAOrderBatch', body);
//        }
    }

    global void finish(Database.BatchableContext BC)
    {
        if(processedServiceOrderIds.size() > 0){
	        System.debug('processedServiceOrderIds =>' + processedServiceOrderIds);
            String body = 'We have submitted - ' + processedServiceOrderIds.size() + ' orders.  Below are all the service orders <br/> ' + processedServiceOrderIds;

            SendEmail('Processed Orders for LMA', body);
        }

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