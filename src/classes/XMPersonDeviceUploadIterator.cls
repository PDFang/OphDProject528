global class XMPersonDeviceUploadIterator implements Iterator<XMContactWrapper>{

    global class XMContactWrapper{

        public String email {get; set;}
        public List<Contact> contacts {get; set;}

        XMContactWrapper(String email){
            contacts = new List<Contact>();
            this.email = email;
        }
    }

    List<XMContactWrapper> xmContacts {get; set;}
    Integer i {get; set;}

    public XMPersonDeviceUploadIterator(){

        xmContacts = new List<XMContactWrapper>();
        Map<String, XMContactWrapper> wrapperMap = new Map<String, XMContactWrapper>();
        for(Contact cont : [
                SELECT Id, FirstName, LastName, Email, xmPerson__c, xmPerson__r.xmPersonUID__c
                FROM Contact
                WHERE Deactivated__c = false AND Email != NULL
                AND Contact_Role__c INCLUDES ('Event Notification','Maintenance Notification')
                order by Email, CreatedDate
        ]){
            XMContactWrapper wrapper = wrapperMap.get(cont.Email);
            if(wrapper == null){
                wrapper = new XMContactWrapper(cont.Email);
                wrapperMap.put(cont.Email, wrapper);
            }
            wrapper.contacts.add(cont);
        }
        xmContacts.addAll(wrapperMap.values());

        i = 0;

        system.debug('XMPersonDeviceUploadIterator(): xmContacts - ' + xmContacts);

    }

    global boolean hasNext(){
        if(i >= xmContacts.size()) {
            return false;
        } else {
            return true;
        }
    }

    global XMContactWrapper next(){

        if(hasNext()){
            i++;
            return xmContacts[i-1];
        }
        return null;

    }

}