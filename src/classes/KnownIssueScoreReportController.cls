/**
 * Created by arnab.karsarkar on 4/3/2017.
 */

public with sharing class KnownIssueScoreReportController {

    public KnownIssueScoreReportController(){

    }

    @RemoteAction
    public static string GetKnownIssues (string filterData, integer offsetInteger ){
        string result = KnownIssueViewHelper.GetKnownIsssues(filterData, offsetInteger);
        return result;
    }
}