public class QuoteSectionTemplateClass {
	
	public String SectionName {get;set;}
	public String SectionNotes {get;set;}
	public String SectionCategory1 {get;set;}
	public String SectionCategory2 {get;set;}
	public Decimal Subtotal {get;set;}
	public Boolean HasCustomerDiscount {get;set;}
	public Quote_Item__c[] Items1 {get;set;}
	public Quote_Item__c[] Items2 {get;set;}
	
	public String Subtotal_Software{get;set;}
	public String Subtotal_Hardware{get;set;}
	public String Subtotal_Services{get;set;}
	public String Subtotal_AMC{get;set;}
	public String Subtotal_Total{get;set;}
	

}