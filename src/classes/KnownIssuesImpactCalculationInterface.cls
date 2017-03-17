/**
 * Created by arnab.karsarkar on 3/15/2017.
 */

public interface KnownIssuesImpactCalculationInterface {
    // Known Issue related Methods
    Decimal CalculateDaysIssuePresent(integer numOfDays, double multiplier);
    Decimal CalculateNumberIncidentsTiedToIssue (integer issueCount,  double multiplier);
    Decimal CalculateDollarAmountTiedToIssue(decimal accountSum,  double multiplier);
    Decimal CalculateRecentReleaseBreak(boolean isRecentRelease,  double multiplier);

}