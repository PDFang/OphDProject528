/**
 * Created by arnab.karsarkar on 4/3/2017.
 */

public with sharing class KIDataItemClass {
    public string   KICaseId {get; set;}
    public string   KINumber {get; set;}
    public string   KISubject {get; set;}
    public string   KIStatus {get; set;}
    public decimal  KIScore{get; set;}
    public String   KIPriority{get; set;}
    public DateTime KICreatedDate {get; set;}
    public string   KIFormattedCreatedDt{get;set;}
    public integer  KIAge{get;set;}
    public decimal  KIASVValue{get;set;}
    public string   KIScoreChange{get;set;}
    public integer  KINumOfIncidents{get;set;}

    public string   KIJIRAId {get; set;}
    public string   KIJIRALink {get; set;}
    public String   KIJIRATeam{get; set;}
    public String   KIJIRAStatus{get; set;}
    public string   KIJIRAIteration{get;set;}
}