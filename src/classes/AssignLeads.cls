public global class AssignLeads{
  
  public static Boolean assignAlreadyCalled=FALSE;
  
      public static boolean assignAlreadyCalled(){
          return assignAlreadyCalled;
      }
      
  @future
  public static void assign(List<Id> lIds){
      assignAlreadyCalled=TRUE;    
      List<Lead> leads=[SELECT Id FROM Lead WHERE Id IN: lIds];    
      For (lead l:leads){
            Database.DMLOptions dmo = new Database.DMLOptions();      
            dmo.assignmentRuleHeader.useDefaultRule= true;       
            l.setOptions(dmo);    
            
      }
      update(leads);
  }
  
  static testMethod void TestReassignLeads()
  {
  	
  	//create a re-engaged lead
  	Lead l = new Lead();
  	l.Status = 'Re-engaged';
  	l.FirstName = 'test';
  	l.LastName = 'tester';
  	l.Phone = '(999)999-9999';
  	l.Company = 'test';
  	insert l;
  	
  	//update the lead to fire the trigger
  	l.LastName = 'tester';
  	update l;
  }
  
}