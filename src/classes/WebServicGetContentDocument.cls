/**
 * Created by arnab.karsarkar on 4/20/2017.
 */
@RestResource(urlMapping = '/GetDocumentId/*')
global class WebServicGetContentDocument {

    @HttpGet
    global static string getDocumentId(){

        ContentVersion contentVersion;
        contentVersion = [SELECT Title,VersionData,VersionNumber,FileType  FROM ContentVersion WHERE Id = '0683C000000CjBkQAK' LIMIT 1 ];

       return EncodingUtil.Base64Encode(contentVersion.VersionData);
    }
}