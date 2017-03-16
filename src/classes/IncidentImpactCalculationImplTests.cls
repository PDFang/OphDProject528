@isTest
public class IncidentImpactCalculationImplTests {

    static testMethod void CalculateIncidentSeverityScore_ReturnsCorrectScore(){
        IncidentImpactCalculationImplementation imp = new IncidentImpactCalculationImplementation();

        double severityOneResult = imp.CalculateIncidentSeverityScore('s1', 5);
        double severityTwoResult = imp.CalculateIncidentSeverityScore('s2', 2);
        double invalidSeverityResult = imp.CalculateIncidentSeverityScore('InvalidSeverity', 2);

        system.assertEquals(severityOneResult, 5, 'Severity 1 Calculation is Incorrect');
        system.assertEquals(severityTwoResult, 1, 'Severity 2 Calculation is Incorrect');
        system.assertEquals(invalidSeverityResult, 0, 'Unknown Severity Calculation is Incorrect');
    }

    static testMethod void CalculatePercentBusinessImpactedScore_ReturnsCorrectCalculatedScore() {
        IncidentImpactCalculationImplementation imp = new IncidentImpactCalculationImplementation();

        double seventyFivePercentGreater = imp.CalculatePercentBusinessImpactedScore('>75%', 5);
        double fiftyToSeventyFive = imp.CalculatePercentBusinessImpactedScore('50-75%', 5);
        double twentyFiveToFifty = imp.CalculatePercentBusinessImpactedScore('25-50%', 5);
        double defaultCase = imp.CalculatePercentBusinessImpactedScore('Unknown Percent', 5);

        system.assertEquals(5, seventyFivePercentGreater, '75 Percent or Greater Calculation is Incorrect');
        system.assertEquals(3.75, fiftyToSeventyFive, '50 - 75 percent calculation is Incorrect');
        system.assertEquals(2.5, twentyFiveToFifty, '25 - 50 Percent Calculation is Incorrect');
        system.assertEquals(0, defaultCase, 'Defauclt Percent Calculation is Incorrect');
    }

    static testMethod void CalculateWorkaroundAvailablePointsScore_ReturnsCorrectCalculatedScore(){
        IncidentImpactCalculationImplementation imp = new IncidentImpactCalculationImplementation();

        double workAroundAvailable = imp.CalculateWorkaroundAvailablePointsScore('yes', 5);
        double noWorkAroundAvailable = imp.CalculateWorkaroundAvailablePointsScore('no', 1);
        double unknownValue = imp.CalculateWorkaroundAvailablePointsScore('maybe', 1);

        system.assertEquals(0, workAroundAvailable, 'Workaround = Yes calculation is Incorrect');
        system.assertEquals(1, noWorkAroundAvailable, 'Workaround = No calculation is Incorrect');
        system.assertEquals(1, unknownValue, 'Workaround = Unknown value calculation is Incorrect');
    }

    static testMethod void CalculateWorkaroundQualityPointsScore_ReturnsCorrecCalculatedScore() {
        IncidentImpactCalculationImplementation imp = new IncidentImpactCalculationImplementation();

        double lowQualityWorkAround = imp.CalculateWorkaroundQualityPointsScore('low', 5);
        double mediumQualityWorkAround = imp.CalculateWorkaroundQualityPointsScore('medium', 5);
        double defaultQualityWorkAround = imp.CalculateWorkaroundQualityPointsScore('high', 5);

        system.assertEquals(5, lowQualityWorkAround, 'Workaround Quality = low calculation is Incorrect');
        system.assertEquals(2.5, mediumQualityWorkAround, 'Workaround Quality = medium calculation is Incorrect');
        system.assertEquals(0, defaultQualityWorkAround, 'Workaround Quality = Unknown/High calculation is Incorrect');
    }

    static testMethod void CalculateSecurityIssueScore_ReturnsCorrectCalculatedScore(){
        IncidentImpactCalculationImplementation imp = new IncidentImpactCalculationImplementation();

        double secuityImpactYes = imp.CalculateSecurityIssueScore('yes', 5);
        double securityImpactNo = imp.CalculateSecurityIssueScore('no', 5);
        double secrityImpactUnknown = imp.CalculateSecurityIssueScore('maybe', 5);

        system.assertEquals(5, secuityImpactYes, 'Security Issue = yes calculation is Incorrect');
        system.assertEquals(0, securityImpactNo, 'Security Issue = no calculation is Incorrect');
        system.assertEquals(0, secrityImpactUnknown, 'Security Issue = Unknown calculation is Incorrect');
    }

    static testMethod void CalculateRelatedKnownIssueScore_ReturnsCorrectCalculatedScore(){
        IncidentImpactCalculationImplementation imp = new IncidentImpactCalculationImplementation();
        
        double knownIssueYes = imp.CalculateRelatedKnownIssueScore('yes', 5);
        double knownIssueNo = imp.CalculateRelatedKnownIssueScore('no', 5);
        double knownIssueUnknown = imp.CalculateRelatedKnownIssueScore('maybe', 5);

        system.assertEquals(5, knownIssueYes, 'Known Issue = yes calculation is Incorrect');
        system.assertEquals(0, knownIssueNo, 'Known Issue = no calculation is Incorrect');
        system.assertEquals(0, knownIssueUnknown, 'Known Issue = Unknown calculation is Incorrect');
    }
}