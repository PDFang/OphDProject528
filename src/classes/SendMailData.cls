/**
 * Created by william.nelson on 11/14/2017.
 */

public with sharing class SendMailData {
public Id CaseId {get;set;}
public string caseNumber {get;set;}
public string AccountNumber {get;set;}
public string Message {get;set;}
public string Header{get;set;}
public Id AccountId {get;set;}
public List<string> emailAddress{get;set;}
public string CaseLink {get;set;}
public string CreatorName {get;set;}
}