@isTest
public class AccountImpactCalculationImplTests {

    public static testMethod void CalculateAgeOfCustomerInMonthsScore_WillReturnCorrectScore(){
        AccountImpactCalculationImpl imp = new AccountImpactCalculationImpl();

        Double monthsGreaterThanTwelve = imp.CalculateAgeOfCustomerInMonthsScore(13, 5);
        Double monthsGreaterThanSix = imp.CalculateAgeOfCustomerInMonthsScore(7, 4);
        Double monthsGreaterThanThree = imp.CalculateAgeOfCustomerInMonthsScore(4, 5);
        Double defaultCaseMonthsLessThanThree = imp.CalculateAgeOfCustomerInMonthsScore(1, 5);

        system.assertEquals(0, monthsGreaterThanTwelve, 'CalculateAgeOfCustomerInMonths > 12 calculation is Incorrect');
        system.assertEquals(2, monthsGreaterThanSix, 'CalculateAgeOfCustomerInMonths = > 6 calculation is Incorrect');
        system.assertEquals(3.75, monthsGreaterThanThree, 'CalculateAgeOfCustomerInMonths = > 3 calculation is Incorrect');
        system.assertEquals(5, defaultCaseMonthsLessThanThree, 'CalculateAgeOfCustomerInMonths = > default calculation is Incorrect');
    }

    public static testMethod void CalculateRiskOfLeavingScore_WillReturnCorrectScore(){
        AccountImpactCalculationImpl imp = new AccountImpactCalculationImpl();

        Double riskOfLeavingThree = imp.CalculateRiskOfLeavingScore('High', 5);
        Double riskOfLeavingTwo = imp.CalculateRiskOfLeavingScore('Medium', 5);
        Double riskOfLeavingDefault = imp.CalculateRiskOfLeavingScore('Low', 5);

        system.assertEquals(5, riskOfLeavingThree, 'CalculateRiskOfLeavingScore = High calculation is Incorrect');
        system.assertEquals(2.5, riskOfLeavingTwo, 'CalculateRiskOfLeavingScore =  Medium calculation is Incorrect');
        system.assertEquals(0, riskOfLeavingDefault, 'CalculateRiskOfLeavingScore = default calculation is Incorrect');
    }

    public static testMethod void CalculateGYRColor_WillReturnCorrectScore(){
        AccountImpactCalculationImpl imp = new AccountImpactCalculationImpl();

        Double redGyrColor = imp.CalculateGYRColor('Red');
        Double yellowGyrColor = imp.CalculateGYRColor('Yellow');
        Double defaultGyrColor = imp.CalculateGYRColor('Not red or yellow');

        system.assertEquals(1, redGyrColor, 'CalculateGYRColor = Red calculation is Incorrect');
        system.assertEquals(.5, yellowGyrColor, 'CalculateGYRColor = Yellow   calculation is Incorrect');
        system.assertEquals(0, defaultGyrColor, 'CalculateGYRColor = default calculation is Incorrect');
    }

    public static testMethod void CalculateStrategicAccountScore_WillReturnCorrectScore(){
        AccountImpactCalculationImpl imp = new AccountImpactCalculationImpl();

        Double stategicScore = imp.CalculateStrategicAccountScore('Strategic', 5);
        Double defaultScore = imp.CalculateStrategicAccountScore('Not Stategic', 1);

        system.assertEquals(5, stategicScore, 'CalculateStrategicAccountScore = Stategic calculation is Incorrect');
        system.assertEquals(0, defaultScore, 'CalculateStrategicAccountScore = Yellow   calculation is Incorrect');
    }

    public static testMethod void CalculatePartnerAccountScore_WillReturnCorrectScore(){
        AccountImpactCalculationImpl imp = new AccountImpactCalculationImpl();

        Double partnerTrueScore = imp.CalculatePartnerAccountScore(true, 5);
        Double defaultScore = imp.CalculatePartnerAccountScore(false, 1);

        system.assertEquals(5, partnerTrueScore, 'CalculatePartnerAccountScore = true calculation is Incorrect');
        system.assertEquals(0, defaultScore, 'CalculatePartnerAccountScore = false calculation is Incorrect');
    }

    public static testMethod void CalculateBrandVisibilityScore_WillReturnCorrectScore(){
        AccountImpactCalculationImpl imp = new AccountImpactCalculationImpl();

        Double partnerTrueScore = imp.CalculateBrandVisibilityScore('yes', 5);
        Double defaultScore = imp.CalculateBrandVisibilityScore('no', 1);

        system.assertEquals(5, partnerTrueScore, 'CalculateBrandVisibilityScore = yes calculation is Incorrect');
        system.assertEquals(0, defaultScore, 'CalculateBrandVisibilityScore = no calculation is Incorrect');
    }

    public static testMethod void CalculateIndustryLeaderScore_WillReturnCorrectScore(){
        AccountImpactCalculationImpl imp = new AccountImpactCalculationImpl();

        Double industryLeaderYesScore = imp.CalculateIndustryLeaderScore('yes', 5);
        Double defaultScore = imp.CalculateIndustryLeaderScore('no', 1);

        system.assertEquals(5, industryLeaderYesScore, 'CalculateIndustryLeaderScore = yes calculation is Incorrect');
        system.assertEquals(0, defaultScore, 'CalculateIndustryLeaderScore = no calculation is Incorrect');
    }

    public static testMethod void CalculateSocialMediaPresenceScore_WillReturnCorrectScore(){
        AccountImpactCalculationImpl imp = new AccountImpactCalculationImpl();

        Double mediaPresenceYesScore = imp.CalculateSocialMediaPresenceScore('yes', 5);
        Double defaultScore = imp.CalculateSocialMediaPresenceScore('no', 1);

        system.assertEquals(5, mediaPresenceYesScore, 'CalculateSocialMediaPresenceScore = yes calculation is Incorrect');
        system.assertEquals(0, defaultScore, 'CalculateSocialMediaPresenceScore = no calculation is Incorrect');
    }

    public static testMethod void CalculateCurrentReferenceScore_WillReturnCorrectScore(){
        AccountImpactCalculationImpl imp = new AccountImpactCalculationImpl();

        Double referenceYesScore = imp.CalculateCurrentReferenceScore(true, 5);
        Double defaultScore = imp.CalculateCurrentReferenceScore(false, 1);

        system.assertEquals(5, referenceYesScore, 'CalculateCurrentReferenceScore = true calculation is Incorrect');
        system.assertEquals(0, defaultScore, 'CalculateCurrentReferenceScore = false calculation is Incorrect');
    }
}