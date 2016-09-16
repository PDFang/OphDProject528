global class SharepointDocumentAccess
{    
    @future(callout=true)
    public static void CreateCustomerLibraryAsync(Set<String> customerAccountNumber)
    {
		
        SharepointDocumentService.DocumentServiceSoap soap = SharepointAuthentication();
		for (string acctNum : customerAccountNumber){
			soap.CreateCustomerLibrary(acctNum);
		}
        
    }
    webService static Boolean CreateCustomerLibrary(String customerAccountNumber) 
    {
		Set<String> stActNums = new Set<String>();
		stActNums.add(customerAccountNumber);
        CreateCustomerLibraryAsync(stActNums); 
        return true;
    }
    private static SharepointDocumentService.DocumentServiceSoap SharepointAuthentication()
    {
        SharepointDocumentService.AuthenticationHeader authHeader = new SharepointDocumentService.AuthenticationHeader();
        authHeader.Username = InContactConfiguration.DocumentUserName;
        authHeader.Password = InContactConfiguration.DocumentPassword;
        
        SharepointDocumentService.DocumentServiceSoap soap = new SharepointDocumentService.DocumentServiceSoap();
        soap.AuthenticationHeader = authHeader;
        soap.timeout_x = 120000; //2 minutes
         
        return soap;
    }     
}