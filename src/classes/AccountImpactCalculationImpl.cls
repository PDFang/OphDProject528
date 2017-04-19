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

        if(risk == 'High') {
            score = 1;
        }
        else if(risk == 'Medium') {
            score = .5;
        }
        else {
            score = 0;
        }

        return score * multiplier;
    }

    public Double CalculateGYRColor(String score){
        Double calculatedScore;

        if(score == 'Red') {
            calculatedScore = 1;
        }
        else if(score == 'Yellow') {
            calculatedScore = .5;
        }
        else {
            calculatedScore = 0;
        }

        return calculatedScore;
    }

    public Double CalculateStrategicAccountScore(String strategicAccount, Double multiplier){
        Double score;

        if(strategicAccount == 'Strategic') {
            score = 1;
        }
        else {
            score = 0;
        }

        return score * multiplier;
    }

    public Double CalculatePartnerAccountScore(Boolean partnerAccount, Double multiplier){
        Double score;

        if(partnerAccount == true) {
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

    public Double CalculateCurrentReferenceScore(Boolean referencable, Double multiplier){
        Double score;

        if(referencable == true) {
            score = 1;
        }
        else {
            score = 0;
        }

        return score * multiplier;
    }
}