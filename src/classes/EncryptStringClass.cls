public class EncryptStringClass {
    
    // the key you want to use to encrypt
    public static string EncodeString(string key, map<string, string> authString)
    {
        String objType;
        string encodedString;
        string profileId = Userinfo.getProfileId();
        Blob cryptoKey = Blob.valueOf(key);// use the key
	
        if(authString.containsKey('UserName'))
            	encodedString = encryptString(authString.get('UserName'), cryptoKey);
        else if(authString.containsKey('Password'))
                encodedString = encryptString(authString.get('Password'), cryptoKey);
        else if(authString.containsKey('Authorization')) 
            encodedString = 'Basic' + encryptString(authString.get('Authorization'), cryptoKey);
        
        return encodedString;
    }

    // encode the strings
	private static string encryptString(string toEncrypt, Blob cryptoKey) 
    {
		Blob blobVal = Blob.valueOf(toEncrypt);
		Blob encryptedData = Crypto.encryptWithManagedIV('AES256', cryptoKey, blobVal);
		string enCodedString = EncodingUtil.base64Encode(encryptedData);
		return enCodedString;

	}

}