public class PartnerDocumentController {

 

    private final ContentVersion contentVersion;

 
	// TOdo
    public PartnerDocumentController () {

        this.contentVersion = [SELECT Title,VersionData,VersionNumber,FileType  FROM ContentVersion WHERE ContentDocumentId = '0693C000000Cj7u' LIMIT 1 ];
    }

 

    /*public ContentVersion cv 
           {
               get {
                   return this.contentVersion;
               }
           } 
     
 
    
     public string pdf {
        get {
            return EncodingUtil.Base64Encode(contentVersion.VersionData);
        }
    }*/
    
    @RemoteAction
    public static string getPDFContent(){
        ContentVersion contentVersion;
        contentVersion = [SELECT Title,VersionData,VersionNumber,FileType  FROM ContentVersion WHERE Id = '0683C000000CjBkQAK' LIMIT 1 ];
        return EncodingUtil.Base64Encode(contentVersion.VersionData);
        
    }
    
}