/**
 * Created by ravish.chawla on 3/20/2017.
 */

public with sharing class KnownIssuesImpactCalcStub implements KnownIssuesImpactCalculationInterface
{
    public Decimal NumberIncidentsTiedToIssue { get; set; }
    public Decimal DaysIssuePresent { get; set; }
    public Decimal Priority { get; set; }
    public Decimal RecentReleaseBreak { get; set; }
    public Decimal SecurityIssue {get; set;}


    public Decimal CalculateNumberIncidentsTiedToIssue(integer issueCount,  decimal multiplier) {
        return this.NumberIncidentsTiedToIssue;

    }

    public Decimal CalculateDaysIssuePresent(integer numOfDays, decimal multiplier){
        return this.DaysIssuePresent;

    }

    public Decimal CalculatePriorityScore(string priority,  decimal multiplier) {
        return this.Priority;

    }

    public Decimal CalculateRecentReleaseBreak(boolean isRecentRelease, decimal multiplier){
        return this.RecentReleaseBreak;

    }

    public Decimal CalculateSecurityIssue(boolean securityIssue, decimal multiplier){
        return this.SecurityIssue;

    }
}