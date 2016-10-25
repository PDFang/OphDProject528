public class IdeasController {
	
    public IdeasController(){
        
    }
    
    public pagereference addToCache(){
        try{
            String paramValue = ApexPages.currentPage().getParameters().get('AccountId');
            Cache.SessionPartition partition = Cache.Session.getPartition('local.TESTPARTITION');
            system.debug(partition.contains('AccountId'));
            if(partition.contains('AccountId') == false){
				partition.put('AccountId', paramValue);
            }
        }catch(Exception ex){
            system.debug(ex);
        }            
        return null;
    }
    
}