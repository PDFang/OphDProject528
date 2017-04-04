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

        list<Case> knownIssueLists = QueryCases(filterDataMap, offsetInteger);
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
            dataItem.KIASVValue = ki.ASVValue__c;
            dataItem.KITFSId = string.valueOf(ki.TfsWorkItem__r.TFSExternalID__c);
            dataItem.KITFSIteration = ki.TfsWorkItem__r.Release__c;
            dataItem.KITFSTeam = ki.TfsWorkItem__r.Team__c;
            dataItem.KITFSStatus = ki.TfsWorkItem__r.State__c;
            dataItem.KIAge = date.valueOf(ki.CreatedDate).daysBetween(system.today());
            dataItem.KIFormattedCreatedDt = GetformattedDate(date.valueOf(ki.CreatedDate));

            dataItems.add(dataItem);
        }

        KnownIssuDataWrapper kiDataWrapper = new KnownIssuDataWrapper();
        kiDataWrapper.KIDataItems = dataItems;
        kiDataWrapper.pageSize = GetCountOfCases(filterDataMap);

        return JSON.serialize(kiDataWrapper);
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


    private static integer GetCountOfCases(Map<string,string> filterData){
        string knownIssueQuery =  FormQueryString(filterData);
        List<Case> listresult = Database.query(knownIssueQuery);
        return listresult.size();
    }

    private static list<case> QueryCases(Map<string,string> filterData,  integer offsetIntger){
        string knownIssueQuery =  FormQueryString(filterData);
        knownIssueQuery += ' Limit 10 Offset ' + offsetIntger;
        List<Case> listresult = Database.query(knownIssueQuery);
        return listresult;
    }

    private static string FormQueryString(Map<string,string> filterData){
        string knownIssueQuery = 'Select Id,Broken_by_Recent_Release__c, CaseNumber, KIImpactScore__c,NumberOfIncidents__c,ASVValue__c,  '
                + ' KIImpactScoreHistorical__c, Status, Subject,Priority, CreatedDate,TfsWorkItem__r.Release__c,'
                + ' TfsWorkItem__r.TFSExternalID__c, TfsWorkItem__r.Team__c, TfsWorkItem__r.State__c'
                + ' From Case '
                + ' WHERE RecordType.Name = \'Known Issue\' '
                + ' AND isClosed = false and Status not in (\'Released - Confirm Resolution\',\'No Fix\')';

        if(filterData.size() > 0)
            knownIssueQuery += GetFilterString(filterData);
        return knownIssueQuery;
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