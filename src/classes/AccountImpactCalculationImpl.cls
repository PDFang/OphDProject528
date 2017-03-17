public class AccountImpactCalculationImpl implements AccountImpactCalculationInterface {
    public Double CalculateAgeOfCustomerInMonthsScore(Integer months, Double multiplier){
        Double score;

        if(months > 12) {
            score = 0;
        }
        else if(months > 6) {
            score = .5;
        }
        else if(months > 3) {
            score = .75;
        }
        else {
            score = 1;
        }

        return score * multiplier;
    }

    public Double CalculateRiskOfLeavingScore(String risk, Double multiplier){
        Double score;

        if(risk == '3') {
            score = 1;
        }
        else if(risk == '2') {
            score = .5;
        }
        else {
            score = 0;
        }

        return score * multiplier;
    }

    public String CalculateGYRColor(Double score){
        String color;

        if(score == 1) {
            color = 'Red';
        }
        else if(score == .5) {
            color = 'Yellow';
        }
        else {
            color = 'Green';
        }

        return color;
    }

    public Double CalculateStrategicAccountScore(String strategicAccount, Double multiplier){
        Double score;

        if(strategicAccount == 'yes') {
            score = 1;
        }
        else {
            score = 0;
        }

        return score * multiplier;
    }

    public Double CalculatePartnerAccountScore(String partnerAccount, Double multiplier){
        Double score;

        if(partnerAccount == 'yes') {
            score = 1;
        }
        else {
            score = 0;
        }

        return score * multiplier;
    }

    public Double CalculateBrandVisibilityScore(String brandVisible, Double multiplier){
        Double score;

        if(brandVisible == 'yes') {
            score = 1;
        }
        else {
            score = 0;
        }

        return score * multiplier;
    }

    public Double CalculateIndustryLeaderScore(String industryLeader, Double multiplier){
        Double score;

        if(industryLeader == 'yes') {
            score = 1;
        }
        else {
            score = 0;
        }

        return score * multiplier;
    }

    public Double CalculateSocialMediaPresenceScore(String socialMediaPresence, Double multiplier){
        Double score;

        if(socialMediaPresence == 'yes') {
            score = 1;
        }
        else {
            score = 0;
        }

        return score * multiplier;
    }

    public Double CalculateCurrentReferenceScore(String referencable, Double multiplier){
        Double score;

        if(referencable == 'yes') {
            score = 1;
        }
        else {
            score = 0;
        }

        return score * multiplier;
    }
}