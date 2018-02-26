/**
 * Created by ravish.chawla on 3/20/2017.
 */

@isTest
public class KnownIssuesImpactCalcImplementationTests {

    static testMethod void CalculateNumberIncidentsTiedToIssue_ReturnsCorrectCalculateScore(){
        KnownIssuesImpactCalcImplementation knownIssImpCalImplTest = new KnownIssuesImpactCalcImplementation();

        Decimal issueCountZero = knownIssImpCalImplTest.CalculateNumberIncidentsTiedToIssue(0, 1);
        Decimal issueCountLTFour = knownIssImpCalImplTest.CalculateNumberIncidentsTiedToIssue(3, 1);
        Decimal issueCountLTSeven = knownIssImpCalImplTest.CalculateNumberIncidentsTiedToIssue(6, 2);
        Decimal issueCountLTTen = knownIssImpCalImplTest.CalculateNumberIncidentsTiedToIssue(9, 3);
        Decimal issueCountElse = knownIssImpCalImplTest.CalculateNumberIncidentsTiedToIssue(11, 4);
        Decimal issueCountNegative = knownIssImpCalImplTest.CalculateNumberIncidentsTiedToIssue(-1, -5);

        system.assertEquals(issueCountZero, 1, 'Issue Count Zero calculation is incorrect');
        system.assertEquals(issueCountLTFour, 1, 'Issue Count Four calculation is incorrect');
        system.assertEquals(issueCountLTSeven, 4, 'Issue Count Seven calculation is incorrect');
        system.assertEquals(issueCountLTTen, 6, 'Issue Count Ten calculation is incorrect');
        system.assertEquals(issueCountElse, 12, 'Issue Count Else calculation is incorrect');
        system.assertEquals(issueCountNegative, -5, 'Negative Issue Count calculation is incorrect');
    }

    static testMethod void CalculateDaysIssuePresent_ReturnsCorrectCalculatedScore() {
        KnownIssuesImpactCalcImplementation knownIssImpCalImplTest = new KnownIssuesImpactCalcImplementation();

        Decimal numOfDaysLTOne = knownIssImpCalImplTest.CalculateDaysIssuePresent(0, 1);
        Decimal numOfDaysLTFour = knownIssImpCalImplTest.CalculateDaysIssuePresent(3, 1);
        Decimal numOfDaysLTThirty = knownIssImpCalImplTest.CalculateDaysIssuePresent(14, 2);
        Decimal numOfDaysGTThirty = knownIssImpCalImplTest.CalculateDaysIssuePresent(33, 3);

        system.assertEquals(numOfDaysLTOne, 1, 'Number Of Days less than one calculation is incorrect');
        system.assertEquals(numOfDaysLTFour, 1, 'Number Of Days less than four calculation is incorrect');
        system.assertEquals(numOfDaysLTThirty, 4, 'Number Of Days less than thirty calculation is incorrect');
        system.assertEquals(numOfDaysGTThirty, 9, 'INumber Of Days less than ten calculation is incorrect');
    }

    static testMethod void CalculateRecentReleaseBreak_ReturnsCorrectCalculatedScore() {
        KnownIssuesImpactCalcImplementation knownIssImpCalImplTest = new KnownIssuesImpactCalcImplementation();

        Decimal isRecentReleaseTrue = knownIssImpCalImplTest.CalculateRecentReleaseBreak(true, 1);
        Decimal isRecentReleaseFalse = knownIssImpCalImplTest.CalculateRecentReleaseBreak(false, 1);

        system.assertEquals(isRecentReleaseTrue, 1, 'Recent Release True calculation is incorrect');
        system.assertEquals(isRecentReleaseFalse, 0, 'Recent Release False calculation is incorrect');
    }



    static testMethod void CalculateSecurityIssue_ReturnsCorrectCalculatedScore() {
        KnownIssuesImpactCalcImplementation knownIssImpCalImplTest = new KnownIssuesImpactCalcImplementation();

        Decimal isSecurityIssueTrue = knownIssImpCalImplTest.CalculateSecurityIssue(true, 1);
        Decimal isSecurityIssueFalse = knownIssImpCalImplTest.CalculateSecurityIssue(false, 1);

        system.assertEquals(isSecurityIssueTrue, 1, 'Security Issue True calculation is incorrect');
        system.assertEquals(isSecurityIssueFalse, 0, 'Security Issue False calculation is incorrect');
    }

    static testMethod void CalculatePriorityScore_ReturnsCorrecCalculatedScore() {
        KnownIssuesImpactCalcImplementation knownIssImpCalImplTest = new KnownIssuesImpactCalcImplementation();

        Decimal priorityOne = knownIssImpCalImplTest.CalculatePriorityScore('p1', 2);
        Decimal priorityTwo = knownIssImpCalImplTest.CalculatePriorityScore('p2', 1);
        Decimal priorityElse = knownIssImpCalImplTest.CalculatePriorityScore('p99', 1);

        system.assertEquals(priorityOne, 2, 'Priority One calculation is incorrect');
        system.assertEquals(priorityTwo, .5, 'Priority Two calculation is incorrect');
        system.assertEquals(priorityElse, 0, 'Priority Else calculation is incorrect');
    }
}