global class XMPersonDeviceUploadIterable implements iterable<XMPersonDeviceUploadIterator.XMContactWrapper>{


    global Iterator<XMPersonDeviceUploadIterator.XMContactWrapper> Iterator(){
        return new XMPersonDeviceUploadIterator();
    }

}