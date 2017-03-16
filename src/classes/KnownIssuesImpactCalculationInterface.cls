/**
 * Created by arnab.karsarkar on 3/15/2017.
 */

public interface KnownIssuesImpactCalculationInterface {
    // Known Issue related Methods
    Decimal CalculateDaysIssuePresent(integer numOfDays, integer multiplier);
    Decimal CalculateNumberIncidentsTiedToIssue (integer issueCount,  integer multiplier);
    Decimal CalculateDollarAmountTiedToIssue(decimal accountSum,  integer multiplier);
    Decimal CalculateRecentReleaseBreak(boolean isRecentRelease,  integer multiplier);

}