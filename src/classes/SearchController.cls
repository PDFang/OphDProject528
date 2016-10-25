public class SearchController {

    @AuraEnabled
    public static list<Case> findCases(string key)
    {
        string searchKey = '%' + key + '%';
        return [select Id, Subject, CaseNumber from Case where subject like :searchkey limit 10];
    }
        
    
}