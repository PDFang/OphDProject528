/**
 * Created by william.nelson on 11/30/2016.
 */
public class ChartData
{
    public string  ProjectId {get; set;}
    public string  ProjectName {get; set;}
    public integer  StartDateDay{get; set;}
    public integer  StartDateMonth{get; set;}
    public integer  StartDateYear{get; set;}
    public integer  EndDateDay{get; set;}
    public integer  EndDateMonth{get; set;}
    public integer  EndDateYear{get; set;}
    public integer DurationDays{get; set;}
    public decimal PercentComplete{get; set;}
    public string Dependency{get;set;}
    public string Type{get;set;}
}