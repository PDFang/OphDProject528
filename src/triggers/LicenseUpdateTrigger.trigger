trigger LicenseUpdateTrigger on sfLma__License__c (after update) {
    
    
    set<Id> acctIds = new set<Id>();        
    string sandboxInstancePrefix = 'CS';
    Map<Id, Double> mpSeatNumber = new map<Id, Double>();
    map<Id, string> mpOrderType = new map<Id, string>();
    if(trigger.isUpdate && !LMAHelperClass.isLMAHelperClassCalled){
        for(sfLma__License__c lic : trigger.new){
        // if the Status is changed to Active 
        if(lic.sfLma__Status__c == 'Active' 
           && !lic.sfLma__Instance__c.containsIgnoreCase(sandboxInstancePrefix)
           && lic.sfLma__Status__c != trigger.oldMap.get(lic.Id).sfLma__Status__c
           && lic.sfLma__Subscriber_Org_ID__c != '')
          {
               
               acctIds.add(lic.sfLma__Account__c);
              mpOrderType.put(lic.sfLma__Subscriber_Org_ID__c, 'Initial');
              mpSeatNumber.put(lic.sfLma__Subscriber_Org_ID__c, lic.sfLma__Seats__c);
          }
        
            else if(lic.sfLma__Seats__c != trigger.oldMap.get(lic.Id).sfLma__Seats__c
                   && lic.sfLma__Seats__c > 0
                   && lic.sfLma__Subscriber_Org_ID__c != ''
                   && !lic.sfLma__Instance__c.containsIgnoreCase(sandboxInstancePrefix)
                   && lic.sfLma__Status__c == 'Active')
            {
                acctIds.add(lic.sfLma__Account__c);    
                double theDifference = lic.sfLma__Seats__c - trigger.oldMap.get(lic.Id).sfLma__Seats__c;
                system.debug('theDifference ==>' +theDifference);
                if(lic.sfLma__Seats__c > trigger.oldMap.get(lic.Id).sfLma__Seats__c){
                    
                    mpOrderType.put(lic.sfLma__Subscriber_Org_ID__c, 'Add-On');
                    mpSeatNumber.put(lic.sfLma__Subscriber_Org_ID__c, theDifference);	
                     
                }   
                else{
                    mpOrderType.put(lic.sfLma__Subscriber_Org_ID__c, 'Reduction');
                    mpSeatNumber.put(lic.sfLma__Subscriber_Org_ID__c, theDifference);	                    
                }
                    
                
            }
            else if(lic.sfLma__Expiration__c != null && !lic.sfLma__Instance__c.containsIgnoreCase(sandboxInstancePrefix)
                    && lic.sfLma__Expiration__c != trigger.oldMap.get(lic.Id).sfLma__Expiration__c
                    && lic.sfLma__Status__c != 'Uninstalled'  && lic.sfLma__Status__c != 'Trial')
            {
                     
                     acctIds.add(lic.sfLma__Account__c);    
                     mpOrderType.put(lic.sfLma__Subscriber_Org_ID__c, 'Cancellation Order');
                     mpSeatNumber.put(lic.sfLma__Subscriber_Org_ID__c, lic.sfLma__Seats__c);    
                        
             }
         
     else if(lic.sfLma__Status__c != trigger.oldMap.get(lic.Id).sfLma__Status__c
            && lic.sflma__status__c == 'Uninstalled'
             && !lic.sfLma__Instance__c.containsIgnoreCase(sandboxInstancePrefix) )
     	{
        	 		 acctIds.add(lic.sfLma__Account__c);    
                     mpOrderType.put(lic.sfLma__Subscriber_Org_ID__c, 'Cancellation Order');
                     mpSeatNumber.put(lic.sfLma__Subscriber_Org_ID__c, lic.sfLma__Seats__c);
            
     	}
            
    }
    
    system.debug('acctIDs == > ' + acctIds );
    system.debug('mpOrderType == > ' +  mpOrderType);    
    if(acctIds.size() > 0)
        LMAHelperClass.CreateCustomer(acctIds, trigger.new, mpOrderType, mpSeatNumber);
    }      
        
}