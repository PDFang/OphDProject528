global class CaseAttachmentExtension extends ConsoleRemoteActions
{
    public boolean isFileInternal { get; set; }
    private final Case c;
    public Attachment fileToUpload { get; set; }
    public String referenceVariable {get;set;}
      
      

    public CaseAttachmentExtension(ApexPages.StandardController controller) {
        this.c = (Case)controller.getRecord();
        fileToUpload = new Attachment();
        fileToUpload.Body = null;
        isFileInternal = false;
    }

    public PageReference CreateAttachment() 
    {
        if(ApexPages.hasMessages(ApexPages.severity.ERROR)) 
        {            
            return null;
        }
    
    
        try
        {
            CaseAttachment attachmentToInsert = new CaseAttachment(fileToUpload , !isFileInternal , c.Id);
            attachmentToInsert.SaveAttachment();
        }
        catch(DmlException ex)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getDmlMessage(0)));
        }
        referenceVariable  = 'attachment-tab';
        fileToUpload.clear();
        isFileInternal = false;
        fileToUpload = new Attachment();
        return null;
    }


}