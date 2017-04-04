/**
 * Created by arnab.karsarkar on 4/3/2017.
 */

public with sharing class KIDataItemClass {
    public string  KICaseId {get; set;}
    public string  KINumber {get; set;}
    public string  KITFSId {get; set;}
    public string  KISubject {get; set;}
    public string  KIStatus {get; set;}
    public decimal KIScore{get; set;}
    public String  KITFSTeam{get; set;}
    public String  KIPriority{get; set;}
    public String  KITFSStatus{get; set;}
    public DateTime    KICreatedDate {get; set;}
    public string  KIFormattedCreatedDt{get;set;}
    public integer KIAge{get;set;}
    public string  KITFSIteration{get;set;}
    public decimal KIASVValue{get;set;}
    public list<String> KIAccounts{get;set;}
    public integer KINumOfIncidents{get;set;}

}