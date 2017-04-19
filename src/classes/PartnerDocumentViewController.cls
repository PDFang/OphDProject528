public class PartnerDocumentViewController {
	
    public List<ContentDocument> documentList{get; private set;}
    
    public PartnerDocumentViewController(){
        documentList = new List<ContentDocument>();
        for(ContentDocument document : [SELECT FileType,Id,LatestPublishedVersionId,Title FROM ContentDocument]){
            documentList.add(document);
        }
    }
}