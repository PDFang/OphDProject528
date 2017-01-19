/**
 * Created by arnab.karsarkar on 1/9/2017.
 */

public class KendoGanttData implements Comparable{

    public string  ProjectId {get; set;}
    public string  ProjectName {get; set;}
    public Date EndDate {get; set;}
    public Date StartDate {get; set;}
    public string ParentId {get; set;}
    public decimal GlobalPriority{get;set;}
    public decimal PercentComplete{get;set;}
    public boolean Expanded{get;set;}
    public boolean Summary{get;set;}
    public string ProgramColor{get; set;}
    public string TeamColor{get; set;}
    public string Team{get; set;}
    public string Program{get; set;}
    public integer DurationDays{get; set;}
    public string TShirtSize{get; set;}
    public string ProjectManager{get; set;}
    public string ProjectStatus{get; set;}
    public string ProductChannel{get;set;}
    public string ProgramFontColor{get;set;}
    public string TeamFontColor{get;set;}
    public string FormattedStartDt{get;set;}
    public string FormattedEndDt{get;set;}
    public string  ProjectSummary {get; set;}

    public Integer compareTo(Object compareTo) {

        KendoGanttData compareToProj = (KendoGanttData)compareTo;
        Integer returnValue = 0;
        if (ParentId > compareToProj.ParentId) {
            // Set return value to a positive value.
            returnValue = 1;
        } else if (ParentId  < compareToProj.ParentId) {
            // Set return value to a negative value.
            returnValue = -1;
        }

        return returnValue;
    }


}