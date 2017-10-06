/**
 * Created by william.nelson on 4/3/2017.
 */

//KIDataItemClass

public with sharing class KnownIssueViewHelper {

    public static final integer PageSize = 50000;
    public static map<string, string> filterDataMap;
    public static map<string, string> searchDataMap;


    public static String GetKnownIsssues(){
        AppConfiguration__c config = AppConfiguration__c.getInstance();


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
            dataItem.KIJIRAId = ki.JIRA_Key__c;
            dataItem.KIJIRALink = config.JIRA_Bug_URL__c + ki.JIRA_Key__c; // use AppConfiguration custom settings
            dataItem.KIJIRAIteration = ki.JIRA_Sprint__c;
            dataItem.KIJIRATeam = ki.JIRA_Team__c;
            dataItem.KIJIRAStatus = ki.JIRA_Status__c;
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
        set<string> valueset = new set<string>();
        string knownIssueQuery;
        string thisFieldName = GetFieldMaps(fieldName);
        knownIssueQuery = 'Select Id, ' + thisFieldName  + ' FROM Case ';
        filterDataMap.put(thisFieldName, fieldValue);
        searchDataMap.put(thisFieldName, 'Like');
        knownIssueQuery  +=  FormQueryString(filterDataMap);
        knownIssueQuery  += ' order by ' + thisFieldName + ' desc Limit 20 ';
        system.debug('knownIssue query => ' + knownIssueQuery);
        list<Case> knownIssueLists = Database.query(knownIssueQuery);

        for(Case ki : knownIssueLists){
            string value;
            if(!valueset.contains(value)){
                if(thisFieldName == 'KITFSIDText__c')
                    valueset.add(string.valueOf(ki.KITFSIDText__c));
                else if (thisFieldName == 'TfsWorkItem__r.State__c')
                    valueset.add(ki.TfsWorkItem__r.State__c);
                else if (thisFieldName == 'TfsWorkItem__r.Team__c')
                    valueset.add(ki.TfsWorkItem__r.Team__c);
                else if (thisFieldName == 'TfsWorkItem__r.Iteration__c')
                    valueset.add(ki.TfsWorkItem__r.Iteration__c);
                else{
                    value = (string) ki.get(thisFieldName);
                    valueset.add(value);
                }
            }
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
                + ' KIImpactScoreHistorical__c, Status, Subject,Priority, CreatedDate,JIRA_Sprint__c, JIRA_Bug_Link__c, '
                + ' JIRA_Key__c, JIRA_Team__c, JIRA_Status__c'
                + ' From Case ';

                knownIssueQuery += FormQueryString(new map<string, string>());
                knownIssueQuery += ' Order BY KIImpactScore__c desc NULLS LAST ';

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
            return 'KITFSIDText__c';
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
            return 'TfsWorkItem__r.Iteration__c';

        return fieldName;
    }
    //Wrapper Class
    public class KnownIssuDataWrapper{
        public list<KIDataItemClass> KIDataItems{get; set;}

        public KnownIssuDataWrapper(){
            KIDataItems = new list<KIDataItemClass>();
         }
    }

}