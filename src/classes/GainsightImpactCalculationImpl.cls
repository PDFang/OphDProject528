public with sharing class GainsightImpactCalculationImpl implements GainsightImpactCalculationInterface {

    public Double CalculateOutstandingIncidentCaseScore(Integer openCaseCount, Double multiplier){
        Double score;
        if( openCaseCount > 5){
            score = 1;
        } else if(openCaseCount > 3){
            score = .75;
        } else if(openCaseCount > 1){
            score = .5;
        } else if (openCaseCount == 1){
            score = .25;
        } else {
            score = 0;
        }

        return score * multiplier;
    }

   public  Double CalculateIncidentsOpenedLastSixMonthsScore(Integer openIssueCount, Double multiplier) {
        Double score;
        if(openIssueCount >= 30){
            score = 1;
        } else if(openIssueCount >= 25){
            score = .75;
        } else if(openIssueCount >= 20){
            score = .5;
        } else if (openIssueCount >= 15){
            score = .25;
        } else {
            score = 0;
        }

        return score * multiplier;
    }

    public Double CalculateMttrIncidentScore(Integer openIssueCount, Double multiplier)
    {
        Double score;
        if (openIssueCount >= 6) {
            score = 1;
        } else if (openIssueCount >= 4) {
            score = .75;
        } else if (openIssueCount >= 2) {
            score = .5;
        } else if (openIssueCount >= 1) {
            score = .25;
        } else {
            score = 0;
        }

        return score * multiplier;
    }

    public Double CalculateAnnualContractValueScore(Decimal annualContractValue, Double multiplier){
        Double score;

        if (annualContractValue >= 500000) {
            score = 1;
        } else if (annualContractValue >= 300000) {
            score = .75;
        } else if (annualContractValue >= 100000) {
            score = .5;
        } else if (annualContractValue >= 25000) {
            score = .25;
        } else {
            score = 0;
        }

        return score * multiplier;
    }

    public Double CalculateCreditGivenLastTwelveMonths(Decimal creditGiven, Double multiplier){
        Double score;

        if (creditGiven >= 5000) {
            score = 1;
        } else if (creditGiven >= 3000) {
            score = .75;
        } else if (creditGiven >= 2000) {
            score = .5;
        } else if (creditGiven >= 1) {
            score = .25;
        } else {
            score = 0;
        }

        return score * multiplier;
    }

    public Double CalculateHealthScore(Integer healthScore, Double multiplier){
        Double score;

        if (healthScore >= 75) {
            score = 0;
        } else if (healthScore >= 50) {
            score = .5;
        } else {
            score = 1;
        }

        return score * multiplier;
    }
}