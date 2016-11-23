/**
 * Created by william.nelson on 11/21/2016.
 */

public with sharing class GanttChartTFSProjectHelper {

    public  List<TFSSprintDate__c>   GetIterationList(date startDate, date endDate)
    {
        List<TFSSprintDate__c> lstIterations =   [Select Name, Start_Date__c, End_Date__c from TFSSprintDate__c where Start_Date__c >=  :startDate  and  End_Date__c  <=  :endDate];
        return lstIterations;
    }

    public Project__c GetProjectByName (string Name){

        Project__c project = [Select id, Name from Project__c where name = :Name ];
        return project;

    }
}