/**
 * Created by ravish.chawla on 3/20/2017.
 */

public with sharing class KnownIssuesImpactCalcStub implements KnownIssuesImpactCalculationInterface
{
    public Decimal NumberIncidentsTiedToIssue { get; set; }
    public Decimal DaysIssuePresent { get; set; }
    public Decimal DollarAmountTiedToIssue { get; set; }
    public Decimal RecentReleaseBreak { get; set; }


    public Decimal CalculateNumberIncidentsTiedToIssue(integer issueCount,  decimal multiplier) {
        return this.NumberIncidentsTiedToIssue;

    }

    public Decimal CalculateDaysIssuePresent(integer numOfDays, decimal multiplier){
        return this.DaysIssuePresent;

    }

    public Decimal CalculateDollarAmountTiedToIssue(decimal accountSum,  decimal multiplier) {
        return this.DollarAmountTiedToIssue;

    }

    public Decimal CalculateRecentReleaseBreak(boolean isRecentRelease, decimal multiplier){
        return this.RecentReleaseBreak;

    }
}