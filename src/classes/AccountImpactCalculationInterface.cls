public interface AccountImpactCalculationInterface {
    Double CalculateAgeOfCustomerInMonthsScore(Integer months, Double multiplier);
    Double CalculateRiskOfLeavingScore(String risk, Double multiplier);
    String CalculateGYRColor(Double score);
    Double CalculateStrategicAccountScore(String strategicAccount, Double multiplier);
    Double CalculatePartnerAccountScore(String partnerAccount, Double multiplier);
    Double CalculateBrandVisibilityScore(String brandVisible, Double multiplier);
    Double CalculateIndustryLeaderScore(String industryLeader, Double multiplier);
    Double CalculateSocialMediaPresenceScore(String socialMediaPresence, Double multiplier);
    Double CalculateCurrentReferenceScore(String referencable, Double multiplier);
}