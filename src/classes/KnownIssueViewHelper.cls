/**
 * Created by william.nelson on 4/3/2017.
 */

//KIDataItemClass

public with sharing class KnownIssueViewHelper {

    public static final integer PageSize = 50000;
    public static map<string, string> filterDataMap;
    public static map<string, string> searchDataMap;


    public static String GetKnownIsssues(){

        list<Case> knownIssueLists = QueryCases();
        list<KIDataItemClass> dataItems = new list<KIDataItemClass>();
        for(Case ki : knownIssueLists){
            KIDataItemClass dataItem = new KIDataItemClass();
            dataItem.KICaseId = ki.Id;
            dataItem.KINumber = ki.CaseNumber;
            dataItem.KIStatus = ki.Status;
            dataItem.KIPriority = ki.Priority;
            dataItem.KISubject = ki.Subject;
            dataItem.KIScore = ki.KIImpactScore__c;
            dataItem.KICreatedDate = ki.CreatedDate;
            dataItem.KINumOfIncidents = Integer.valueOf(ki.NumberOfIncidents__c);
            dataItem.KIASVValue = ki.ASVValue__c == null ? null : ki.ASVValue__c.setScale(2);
            dataItem.KITFSId = string.valueOf(ki.TfsWorkItem__r.TFSExternalID__c);
            dataItem.KITFSLink = 'http://corptfsapp01.ucn.net:8080/tfs/DefaultCollection/inContact/_workitems#_a=edit&id=' + dataItem.KITFSId;
            dataItem.KITFSIteration = ki.TfsWorkItem__r.Release__c;
            dataItem.KITFSTeam = ki.TfsWorkItem__r.Team__c;
            dataItem.KITFSStatus = ki.TfsWorkItem__r.State__c;
            dataItem.KIAge = date.valueOf(ki.CreatedDate).daysBetween(system.today());
            dataItem.KIFormattedCreatedDt = GetformattedDate(date.valueOf(ki.CreatedDate));
            dataItem.KIScoreChange = ki.KIImpactScore__c > ki.KIImpactScoreHistorical__c ? 'Up'
                    : ki.KIImpactScore__c < ki.KIImpactScoreHistorical__c ? 'Down' : 'NoChnage';
            dataItems.add(dataItem);
        }

        KnownIssuDataWrapper kiDataWrapper = new KnownIssuDataWrapper();
        kiDataWrapper.KIDataItems = dataItems;


        return JSON.serialize(kiDataWrapper);
    }

    public static string GetSpecificFieldValue(string fieldName, string fieldValue){
        filterDataMap = new map<string, string>();
        searchDataMap = new map<string, string>();
        string knownIssueQuery;
        string thisFieldName = GetFieldMaps(fieldName);
        knownIssueQuery = 'Select Id, ' + thisFieldName  + ' FROM Case ';
        filterDataMap.put(thisFieldName, fieldValue);
        searchDataMap.put(thisFieldName, 'Like');
        knownIssueQuery  +=  FormQueryString(filterDataMap);
        knownIssueQuery  += ' order by ' + thisFieldName + ' desc Limit 20 ';
        system.debug('knownIssue query => ' + knownIssueQuery);
        list<Case> knownIssueLists = Database.query(knownIssueQuery);
        set<string> valueset = new set<string>();
        for(Case ki : knownIssueLists){
            string value;
            if(!valueset.contains(value)){
                value = (string) ki.get(thisFieldName);
                valueset.add(value);
            }

            //options.add(new DropDownValues(ki.Id, value));
        }

        return JSON.serialize(valueset);
    }


    private static string GetformattedDate(date dt){
        if(dt != null)
        {
            integer month = dt.month();
            integer day = dt.day();
            integer year = dt.year();

            string formattedDate = month + '/' + day + '/' + year;

            return formattedDate;
        }

        return null;

    }



    private static list<case> QueryCases(){

        string knownIssueQuery = 'Select Id,Broken_by_Recent_Release__c, CaseNumber, KIImpactScore__c,NumberOfIncidents__c,ASVValue__c,  '
                + ' KIImpactScoreHistorical__c, Status, Subject,Priority, CreatedDate,TfsWorkItem__r.Release__c, TfsWorkItem__r.TFSItemLink__c, '
                + ' TfsWorkItem__r.TFSExternalID__c, TfsWorkItem__r.Team__c, TfsWorkItem__r.State__c'
                + ' From Case   WHERE RecordType.Name = \'Known Issue\' '
                + ' AND isClosed = false and Status not in (\'Released - Confirm Resolution\',\'No Fix\')'
                + ' Order BY KIImpactScore__c desc NULLS LAST ';

        system.debug('knownIssueQuery =>' + knownIssueQuery);
        List<Case> listresult = Database.query(knownIssueQuery);
        return listresult;
    }

    private static string FormQueryString(Map<string,string> filterData){
        string knownIssueQuery = ' WHERE RecordType.Name = \'Known Issue\' '
                + ' AND isClosed = false and Status not in (\'Released - Confirm Resolution\',\'No Fix\')';

        if(filterData.size() > 0)
            knownIssueQuery += GetFilterString(filterData, searchDataMap);
        return knownIssueQuery;
    }

    private static string GetFilterString(Map<string,string> filterData, map<string, string> searchType){
        string query = '';
        for(string fieldName : filterData.keySet()) {
            string fieldValue = filterData.get(fieldName);
            if(searchType.get(fieldName) == 'Like')
                query += ' And ' +  fieldName + ' like \'%'  +  fieldValue + '%\' ';

        }
        return query;
    }

    private static string GetFieldMaps(string fieldName){
        if(fieldName == 'KI')
            return 'CaseNumber';
        if(fieldName == 'TFS Id')
            return 'TfsWorkItem__r.TFSExternalID__c';
        if(fieldName == 'Subject')
            return 'Subject';
        if(fieldName == 'KI Status')
            return 'Status';
        if(fieldName == 'Team')
            return 'TfsWorkItem__r.Team__c';
        if(fieldName == 'Priority')
            return 'Priority';
        if(fieldName == 'TFS Status')
            return 'TfsWorkItem__r.State__c';
        if(fieldName == 'Iteration')
            return 'TfsWorkItem__r.Release__c';
        if(fieldName == 'Age')
            return 'CreatedDate';
        if(fieldName == 'Created')
            return 'CreatedDate';

        return fieldName;
    }
    //Wrapper Class
    public class KnownIssuDataWrapper{
        public list<KIDataItemClass> KIDataItems{get; set;}

        public KnownIssuDataWrapper(){
            KIDataItems = new list<KIDataItemClass>();
         }
    }

    //Filter Data Class
    public class FilterDataClass{
        public string FieldName{get; set;}
        public string FieldValue{get; set;}
        public string SearchType{get;set;}

    }


}