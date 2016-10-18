/**
 * Created by arnab.karsarkar on 10/13/2016.
 */

public without sharing class UploadPartnerBrandingImageController {

    public PartnerBranding__c partnerBranding{get;set;}
  /**  public StaticResource resource {
        get {
            if (resource == null)
                resource = new StaticResource();
            return resource;
        }
    set;

} **/

    MetadataService.MetadataPort service = createService();
    MetadataService.StaticResource resource = new MetadataService.StaticResource();
    public Attachment attachment {
        get {
            if (attachment == null)
                attachment = new Attachment();
            return attachment;
        }
        set;
    }

    public UploadPartnerBrandingImageController(ApexPages.standardcontroller controller)
    {
        partnerBranding = new PartnerBranding__c();


    }

    public PageReference upload()
    {
        String error = '';
        if(attachment.Body == null)
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Please choose a file to upload.'));
            return null;
        }

        resource.content = EncodingUtil.base64Encode(attachment.Body);
        resource.fullName = partnerBranding.FileName__c;
        resource.ContentType = 'image/png';
        resource.CacheControl = 'Public';

        try
        {
            MetadataService.SaveResult[] results = service.createMetadata(new List<MetadataService.Metadata> { resource });
            for(MetadataService.SaveResult sr : results)
            {
               if(!sr.success)
               {
                   for(MetadataService.Error err : sr.errors)
                   {
                       error += err.message;
                   }
               }
            }

            if(error != '')
            {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Error in uploading file - ' + error));
                return null;
            }

            system.debug('partnerBranding ==>' + partnerBranding);
            if(partnerBranding.PartnerAccount__c != null)
            {
               insert partnerBranding;
            }

        }
        catch(Exception ex)
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Error in uploading file - ' + ex.getMessage()));
            return null;
        }
        finally {
            attachment = new Attachment();

        }

        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'File uploaded successfully'));
        return null;
    }

    public static MetadataService.MetadataPort createService()
    {
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();
        return service;
    }

}