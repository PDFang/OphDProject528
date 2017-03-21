/**
 * Created by ravish.chawla on 3/20/2017.
 */

@isTest
public class KnownIssuesImpactCalcImplementationTests {

    static testMethod void CalculateNumberIncidentsTiedToIssue_ReturnsCorrectCalcualteScore(){
        KnownIssuesImpactCalcImplementation knownIssImpCalImplTest = new KnownIssuesImpactCalcImplementation();

        Decimal issueCountZero = knownIssImpCalImplTest.CalculateNumberIncidentsTiedToIssue(0, 0);
        Decimal issueCountLTFour = knownIssImpCalImplTest.CalculateNumberIncidentsTiedToIssue(3, 1);
        Decimal issueCountLTSeven = knownIssImpCalImplTest.CalculateNumberIncidentsTiedToIssue(6, 2);
        Decimal issueCountLTTen = knownIssImpCalImplTest.CalculateNumberIncidentsTiedToIssue(9, 3);
        Decimal issueCountElse = knownIssImpCalImplTest.CalculateNumberIncidentsTiedToIssue(11, 4);
        Decimal issueCountNegative = knownIssImpCalImplTest.CalculateNumberIncidentsTiedToIssue(-1, -5);

        system.assertEquals(issueCountZero, 0, 'Issue Count Zero calculation is incorrect');
        system.assertEquals(issueCountLTFour, 1, 'Issue Count Four calculation is incorrect');
        system.assertEquals(issueCountLTSeven, 8, 'Issue Count Seven calculation is incorrect');
        system.assertEquals(issueCountLTTen, 21, 'Issue Count Ten calculation is incorrect');
        system.assertEquals(issueCountElse, 40, 'Issue Count Else calculation is incorrect');
        system.assertEquals(issueCountNegative, -5, 'Negative Issue Count calculation is incorrect');
    }

    static testMethod void CalculateDaysIssuePresent_ReturnsCorrectCalculatedScore() {
        KnownIssuesImpactCalcImplementation knownIssImpCalImplTest = new KnownIssuesImpactCalcImplementation();

        Decimal numOfDaysLTOne = knownIssImpCalImplTest.CalculateDaysIssuePresent(0, 0);
        Decimal numOfDaysLTFour = knownIssImpCalImplTest.CalculateDaysIssuePresent(3, 1);
        Decimal numOfDaysLTSeven = knownIssImpCalImplTest.CalculateDaysIssuePresent(6, 2);
        Decimal numOfDaysLTTen = knownIssImpCalImplTest.CalculateDaysIssuePresent(9, 3);
        Decimal numOfDaysElse = knownIssImpCalImplTest.CalculateDaysIssuePresent(11, 4);
        Decimal numOfDaysNegative = knownIssImpCalImplTest.CalculateDaysIssuePresent(-1, -5);

        system.assertEquals(numOfDaysLTOne, 0, 'Number Of Days less than one calculation is incorrect');
        system.assertEquals(numOfDaysLTFour, 0.25, 'Number Of Days less than four calculation is incorrect');
        system.assertEquals(numOfDaysLTSeven, 8, 'Number Of Days less than seven calculation is incorrect');
        system.assertEquals(numOfDaysLTTen, 21, 'INumber Of Days less than ten calculation is incorrect');
        system.assertEquals(numOfDaysElse, 40, 'Number Of Days else calculation is incorrect');
        system.assertEquals(numOfDaysNegative, 0, 'Negative Number Of Days calculation is incorrect');
    }

    static testMethod void CalculateDollarAmountTiedToIssue_ReturnsCorrectCalculatedScore(){
        KnownIssuesImpactCalcImplementation knownIssImpCalImplTest = new KnownIssuesImpactCalcImplementation();

        Decimal accountSumLTOne = knownIssImpCalImplTest.CalculateDollarAmountTiedToIssue(0, 0);
        Decimal accountSumLTTwo = knownIssImpCalImplTest.CalculateDollarAmountTiedToIssue(1, 1);
        Decimal accountSumLTThree = knownIssImpCalImplTest.CalculateDollarAmountTiedToIssue(3, 2);
        Decimal accountSumLTFive = knownIssImpCalImplTest.CalculateDollarAmountTiedToIssue(5, 3);
        Decimal accountSumLTElse = knownIssImpCalImplTest.CalculateDollarAmountTiedToIssue(9, 4);
        Decimal accountSumLTNegative = knownIssImpCalImplTest.CalculateDollarAmountTiedToIssue(-1, -5);

        system.assertEquals(accountSumLTOne, 0, 'Account Sum less than one calculation is incorrect');
        system.assertEquals(accountSumLTTwo, 1, 'Account Sum less than two calculation is incorrect');
        system.assertEquals(accountSumLTThree, 8, 'Account Sum less than three calculation is incorrect');
        system.assertEquals(accountSumLTFive, 21, 'Account Sum less than five calculation is incorrect');
        system.assertEquals(accountSumLTElse, 40, 'Account Sum else calculation is incorrect');
        system.assertEquals(accountSumLTNegative, 0, 'Negative Account Sum calculation is incorrect');
    }

    static testMethod void CalculateRecentReleaseBreak_ReturnsCorrecCalculatedScore() {
        KnownIssuesImpactCalcImplementation knownIssImpCalImplTest = new KnownIssuesImpactCalcImplementation();

        Decimal isRecentReleaseTrue = knownIssImpCalImplTest.CalculateRecentReleaseBreak(true, 1);
        Decimal isRecentReleaseFalse = knownIssImpCalImplTest.CalculateRecentReleaseBreak(false, 1);

        system.assertEquals(isRecentReleaseTrue, 10, 'Recent Release True calculation is incorrect');
        system.assertEquals(isRecentReleaseFalse, 0, 'Recent Release False calculation is incorrect');
    }
}