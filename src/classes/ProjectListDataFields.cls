/**
 * Created by arnab.karsarkar on 2/9/2017.
 */

public with sharing class ProjectListDataFields {
    public string   ProjectId {get; set;}
    public string   ProjectName {get; set;}
    public string   RequestedDeliveryDate {get; set;}
    public string   ExpectedDeliveryDate {get; set;}
    public decimal  Priority{get;set;}
    public decimal  PercentComplete{get;set;}
    public string   ProjectOwner{get; set;}
    public string   ProjectStatus{get; set;}
    public string   ProductChannel{get;set;}
    public string   ProjectType{get;set;}
    public string   RecordTypeName{get;set;}
    public string   ProjectSummary {get; set;}
    public decimal  OtherPriority {get; set;}
    public string   DeliveryChannel {get; set;}
    public string   RequestChannel {get; set;}
    public boolean  isPriorityMismatch {get; set;}
    public Date  CreatedDate {get; set;}
}