/**
 * Created by arnab.karsarkar on 10/17/2016.
 */

public without sharing class PartnerBrandingDisplayController {

    @AuraEnabled
    public static string findBrandingImage()
    {
        string userId = UserInfo.getUserId();
        string fileName = '';
        string accountId;
        String currAcctId = [select Contact.AccountId from User where Id = :userId limit 1].Contact.AccountId;

        if(currAcctId != '' && currAcctId != null)
        {
            Account userAccount = [select Id, ParentId, RecordType.Name,  Parent.RecordType.Name  from Account where (Id = :currAcctId or ParentId = :currAcctId)
                                   limit 1];


            if(userAccount.RecordType.Name.contains('Partner') ||
                    userAccount.Parent.RecordType.Name.contains('Partner'))
            {
                if(userAccount.ParentId != null)
                    accountId = userAccount.ParentId;
                else
                    accountId = userAccount.Id;
            }

            PartnerBranding__c[] brandingImage = [select FileName__c from PartnerBranding__c where  PartnerAccount__c = :accountId and IsDisplayBrand__c = true];

            if(brandingImage.size() > 0)
            {
                fileName = brandingImage[0].FileName__c;


            }
            if(fileName == '' || fileName == null)
                fileName = 'inContactLogo';

            system.debug('fileName >' + fileName);
            return fileName;
        }

        fileName =  'inContactLogo';
        return fileName;


    }

}