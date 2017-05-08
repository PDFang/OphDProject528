@RestResource(urlMapping = '/GetDocumentMike/*')
global class WebServiceGetDocumentMike {

    @HttpGet
    global static string getDocumentId(){

        ContentVersion contentVersion;
        contentVersion = [SELECT Title,VersionData,VersionNumber,FileType  FROM ContentVersion WHERE ContentDocumentId = '0693C000000Cj7u' LIMIT 1 ];
        return contentVersion.VersionData.toString();
    }
}