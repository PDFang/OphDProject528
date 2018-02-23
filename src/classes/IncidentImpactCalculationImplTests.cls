@isTest
public class IncidentImpactCalculationImplTests {

    static testMethod void CalculateIncidentSeverityScore_ReturnsCorrectScore(){
        IncidentImpactCalculationImplementation imp = new IncidentImpactCalculationImplementation();

        double severityOneResult = imp.CalculateIncidentSeverityScore('s1', 5);
        double severityTwoResult = imp.CalculateIncidentSeverityScore('s2', 2);
        double severityThreeResult = imp.CalculateIncidentSeverityScore('s3', 2);
        double invalidSeverityResult = imp.CalculateIncidentSeverityScore('InvalidSeverity', 2);

        system.assertEquals(severityOneResult, 5, 'Severity 1 Calculation is Incorrect');
        system.assertEquals(severityTwoResult, 1, 'Severity 2 Calculation is Incorrect');
        system.assertEquals(severityThreeResult, .5, 'Severity 3 Calculation is Incorrect');
        system.assertEquals(invalidSeverityResult, 0, 'Unknown Severity Calculation is Incorrect');
    }

    static testMethod void CalculateIncidentPriorityScore_ReturnsCorrectScore(){
        IncidentImpactCalculationImplementation imp = new IncidentImpactCalculationImplementation();

        double priorityOneResult = imp.CalculateIncidentPriorityScore('p1', 5);
        double priorityTwoResult = imp.CalculateIncidentPriorityScore('p2', 2);
        double priorityThreeResult = imp.CalculateIncidentPriorityScore('p3', 2);
        double invalidPriorityResult = imp.CalculateIncidentPriorityScore('InvalidPriority', 2);

        system.assertEquals(priorityOneResult, 5, 'Priority 1 Calculation is Incorrect');
        system.assertEquals(priorityTwoResult, 1, 'Priority 2 Calculation is Incorrect');
        system.assertEquals(priorityThreeResult, .5, 'Priority 3 Calculation is Incorrect');
        system.assertEquals(invalidPriorityResult, 0, 'Unknown Priority Calculation is Incorrect');
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

    static testMethod void CalculateRepeatIssueScore_ReturnsCorrectCalculatedScore(){
        IncidentImpactCalculationImplementation imp = new IncidentImpactCalculationImplementation();

        double repeatIssueYes = imp.CalculateRepeatIssueScore('yes', 5);
        double repeatIssueNo = imp.CalculateRepeatIssueScore('no', 5);
        double repeatIssueUnknown = imp.CalculateRepeatIssueScore('maybe', 5);

        system.assertEquals(5, repeatIssueYes, 'Repeat Issue = yes calculation is Incorrect');
        system.assertEquals(0, repeatIssueNo, 'Repeat Issue = no calculation is Incorrect');
        system.assertEquals(0, repeatIssueUnknown, 'Repeat Issue = Unknown calculation is Incorrect');
    }
}