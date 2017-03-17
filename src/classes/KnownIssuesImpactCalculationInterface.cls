/**
 * Created by arnab.karsarkar on 3/15/2017.
 */

public interface KnownIssuesImpactCalculationInterface {
    // Known Issue related Methods
    Decimal CalculateDaysIssuePresent(integer numOfDays, decimal multiplier);
    Decimal CalculateNumberIncidentsTiedToIssue (integer issueCount,  decimal multiplier);
    Decimal CalculateDollarAmountTiedToIssue(decimal accountSum,  decimal multiplier);
    Decimal CalculateRecentReleaseBreak(boolean isRecentRelease,  decimal multiplier);

}