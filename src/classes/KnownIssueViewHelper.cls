/**
 * Created by william.nelson on 4/3/2017.
 */

//KIDataItemClass

public with sharing class KnownIssueViewHelper {




    public static String GetKnownIsssues(string filterData, integer offsetInteger){
        map<string, string> filterDataMap = new map<string, string>();
        if(filterData != '' && filterData != null){
            JSONParser parser = JSON.createParser(filterData);
            while (parser.nextToken() != null) {
                if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                    FilterDataClass fd = (FilterDataClass) parser.readValueAs(FilterDataClass.class);
                    string fieldName = GetFieldMaps(fd.fieldName);
                    filterDataMap.put(fieldName, fd.fieldValue);
                }
            }
        }
        return null;

    }




    private static List<Case> QueryCases(Map<string,string> filterData,  integer offsetIntger){
        string knownIssueQuery = 'Select Id,Broken_by_Recent_Release__c, CaseNumber, Subject, KIImpactScore__c,'
                + ' KIImpactScoreHistorical__c, Status, Subject,Priority, CreatedDate,TfsWorkItem__r.Release__c,'
                + ' TfsWorkItem__r.TFSExternalID__c, TfsWorkItem__r.Team__c, TfsWorkItem__r.State__c'
                + ' From Case '
                + ' WHERE RecordType.Name = \'Known Issue\' '
                + ' AND isClosed = false and Status not in (\'Released - Confirm Resolution\',\'No Fix\')';

        if(filterData.size() > 0)
            knownIssueQuery += GetFilterString(filterData);

        knownIssueQuery += ' Limit 100 Offset ' + offsetIntger;
        List<Case> listresult = Database.query(knownIssueQuery);
        return listresult;
    }

    private static string GetFilterString(Map<string,string> filterData){
        string query;
        for(string fieldName : filterData.keySet()) {
            query += ' And ' +  fieldName + ' like %'  + filterData.get(fieldName)  + '% ';
        }
        return query;
    }

    private static string GetFieldMaps(string fieldName){
        if(fieldName == 'KINumber')
            return 'CaseNumber';
        if(fieldName == 'KITFSId')
            return 'TfsWorkItem__r.TFSExternalID__c';
        if(fieldName == 'KISubject')
            return 'Subject';
        if(fieldName == 'KITFSTeam')
            return 'TfsWorkItem__r.Team__c';
        if(fieldName == 'KIPriority')
            return 'Priority';
        if(fieldName == 'KITFSStatus')
            return 'TfsWorkItem__r.State__c';
        if(fieldName == 'KITFSIteration')
            return 'TfsWorkItem__r.Release__c';

        return null;
    }

    //Wrapper Class
    public class KnownIssuDataWrapper{
        public list<KIDataItemClass> KIDataItems{get; set;}
        public integer pageSize{get; set;}

        public KnownIssuDataWrapper(){
            KIDataItems = new list<KIDataItemClass>();
            pageSize = 0;
        }
    }

    //Filter Data Class
    public class FilterDataClass{
        public string FieldName{get; set;}
        public string FieldValue{get; set;}

    }

}