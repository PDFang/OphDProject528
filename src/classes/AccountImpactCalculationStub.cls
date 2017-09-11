public with sharing class AccountImpactCalculationStub implements AccountImpactCalculationInterface {
    public Double AgeOfCustomerInMonthsScore { get; set; }
    public Double RiskOfLeavingScore { get; set; }
    public Double GRYColor { get; set; }
    public Double StrategicAccountScore { get; set; }
    public Double PartnerAccountScore { get; set; }
    public Double BrandVisibilityScore { get; set; }
    public Double IndustryLeaderScore { get; set; }
    public Double SocialMediaPresenceScore { get; set; }
    public Double CurrentReferenceScore { get; set; }

    public Double CalculateAgeOfCustomerInMonthsScore(Integer months, Double multiplier){
        return AgeOfCustomerInMonthsScore;
    }

    public Double CalculateRiskOfLeavingScore(String risk, Double multiplier){
        return RiskOfLeavingScore;
    }

    public Double CalculateGYRColor(String score){
        return GRYColor;
    }

    public Double CalculateStrategicAccountScore(String strategicAccount, Double multiplier){
        return StrategicAccountScore;
    }

    public Double CalculatePartnerAccountScore(Boolean partnerAccount, Double multiplier){
        return PartnerAccountScore;
    }

    public Double CalculatePartnerAccountScore(String recordTypeName, Double multiplier){
        return PartnerAccountScore;
    }

    public Double CalculateBrandVisibilityScore(String brandVisible, Double multiplier){
        return BrandVisibilityScore;
    }

    public Double CalculateIndustryLeaderScore(String industryLeader, Double multiplier){
        return IndustryLeaderScore;
    }

    public Double CalculateSocialMediaPresenceScore(String socialMediaPresence, Double multiplier){
        return SocialMediaPresenceScore;
    }

    public Double CalculateCurrentReferenceScore(Boolean referencable, Double multiplier){
        return CurrentReferenceScore;
    }
}