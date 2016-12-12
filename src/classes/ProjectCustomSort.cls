/**
 * Created by arnab.karsarkar on 12/6/2016.
 */

public class ProjectCustomSort implements Comparable{

    public Project__c project;

    public ProjectCustomSort(Project__c proj){
        project = proj;
    }

    public Integer compareTo(Object compareTo) {
    // Cast argument to OpportunityWrapper
        ProjectCustomSort compareToProj = (ProjectCustomSort)compareTo;
    // The return value of 0 indicates that both elements are equal.
        Integer returnValue = 0;


        if (project.BattingOrder__c > compareToProj.project.BattingOrder__c) {
    // Set return value to a positive value.
                returnValue = 1;
            } else if (project.BattingOrder__c  < compareToProj.project.BattingOrder__c) {
    // Set return value to a negative value.
                returnValue = -1;
            }

        return returnValue;
    }
}
