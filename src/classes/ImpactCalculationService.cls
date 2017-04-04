public class ImpactCalculationService
{
    private IncidentImpactCalculationInterface impactCalculator;
    private Map<String, Impact_Score_Multiplier__c> multiplierMap;
    private GainsightImpactCalculationInterface gainsightImpactCalculation;
    private AccountImpactCalculationInterface accountImpactCalculation;

    private ImpactCalculationService()
    {
        this.multiplierMap = new Map<String, Impact_Score_Multiplier__c>();
        Map<String, Impact_Score_Multiplier__c> settingMap = Impact_Score_Multiplier__c.getAll();
        // convert key values to lower case
        if(settingMap != null && settingMap.size() > 0){
            for(Impact_Score_Multiplier__c multiplier : settingMap.values()){
                multiplierMap.put(multiplier.Name.toLowerCase(), multiplier);
            }
        }
    }

    public ImpactCalculationService(IncidentImpactCalculationInterface impactCalculator)
    {
        this();

        this.impactCalculator = impactCalculator;
    }

    public ImpactCalculationService(GainsightImpactCalculationInterface gainsightImpactCalculation)
    {
        this();

        this.gainsightImpactCalculation = gainsightImpactCalculation                                           ;
    }

    public ImpactCalculationService(AccountImpactCalculationInterface accountImpactCalculation)
    {
        this();

        this.accountImpactCalculation = accountImpactCalculation;
    }

    public void CalculateIncidentNetScore(Case[] caseList)
    {
        for(Case caseRecord : caseList)
        {
            //calculate the net score
            Double severityScore = caseRecord.Severity__c == null
                    ? 0
                    : impactCalculator.CalculateIncidentSeverityScore(caseRecord.Severity__c, GetMultiplierValue('severity'));
            system.debug('CalculateIncidentNetScore(): severityScore - ' + severityScore + ' , Severity__c - ' + caseRecord.Severity__c);

            Double businessImpactScore = caseRecord.Business_Impacted__c == null
                    ? 0
                    : impactCalculator.CalculatePercentBusinessImpactedScore(caseRecord.Business_Impacted__c, GetMultiplierValue('business impacted'));
            system.debug('CalculateIncidentNetScore(): businessImpactScore - ' + businessImpactScore + ' , Business_Impacted__c - ' + caseRecord.Business_Impacted__c);

            Double workaroundScore = caseRecord.Workaround_Available__c == null
                    ? 0
                    : impactCalculator.CalculateWorkaroundAvailablePointsScore(caseRecord.Workaround_Available__c, GetMultiplierValue('workaround'));
            system.debug('CalculateIncidentNetScore(): workaroundScore - ' + workaroundScore + ' , Workaround_Available__c - ' + caseRecord.Workaround_Available__c);

            Double workaroundQualityScore = caseRecord.Quality_of_Workaround__c == null
                    ? 0
                    : impactCalculator.CalculateWorkaroundQualityPointsScore(caseRecord.Quality_of_Workaround__c, GetMultiplierValue('workaround quality'));
            system.debug('CalculateIncidentNetScore(): workaroundQualityScore - ' + workaroundQualityScore + ' , Quality_of_Workaround__c - ' + caseRecord.Quality_of_Workaround__c);

            Double securityScore = caseRecord.Security_Issue__c == null
                    ? 0
                    : impactCalculator.CalculateSecurityIssueScore(caseRecord.Security_Issue__c, GetMultiplierValue('is security issue'));
            system.debug('CalculateIncidentNetScore(): securityScore - ' + securityScore + ' , Security_Issue__c - ' + caseRecord.Security_Issue__c);

            Double knownIssueScore = caseRecord.Related_to_Previous_Known_Issue__c == null
                    ? 0
                    : impactCalculator.CalculateRelatedKnownIssueScore(caseRecord.Related_to_Previous_Known_Issue__c, GetMultiplierValue('is known issue'));
            system.debug('CalculateIncidentNetScore(): knownIssueScore - ' + knownIssueScore + ' , Related_to_Previous_Known_Issue__c ' + caseRecord.Related_to_Previous_Known_Issue__c);

            Double netScore = severityScore + businessImpactScore + workaroundScore + workaroundQualityScore + securityScore + knownIssueScore;
            system.debug('CalculateIncidentNetScore(): netScore - ' + netScore);
            //store the net score
            caseRecord.Incident_Net_Score__c = netScore;

        }
    } // end of CalculateIncidentNetScore()

    public void CalculateGainsightNetScore(JBCXM__CustomerInfo__c[] customInfoList){
        List<Account> accountUpdateList = new List<Account>();

        for(JBCXM__CustomerInfo__c customerInfoRecord :customInfoList) {

            // Calculate the Gainsight Score
            Double outStandingIncidentScore = customerInfoRecord.JBCXM_OpenCases__c == null
                    ? 0
                    : this.gainsightImpactCalculation.CalculateOutstandingIncidentCaseScore((Integer) customerInfoRecord.JBCXM_OpenCases__c, GetMultiplierValue('outstanding incidents'));
            system.debug('CalculateGainsightNetScore(): outStandingIncidentScore - ' + outStandingIncidentScore + ' , JBCXM_OpenCases__c - ' + customerInfoRecord.JBCXM_OpenCases__c);

            Double incidentsOpenedLastSixMonthsScore = customerInfoRecord.JBCXM_CreatedCases__c == null
                    ? 0
                    : this.gainsightImpactCalculation.CalculateIncidentsOpenedLastSixMonthsScore((Integer) customerInfoRecord.JBCXM_CreatedCases__c, GetMultiplierValue('incidents opened last six months'));
            system.debug('CalculateGainsightNetScore(): incidentsOpenedLastSixMonthsScore - ' + incidentsOpenedLastSixMonthsScore + ' , 	JBCXM_CreatedCases__c - ' + customerInfoRecord.JBCXM_CreatedCases__c);

            Double mttrIncidentScore = customerInfoRecord.JBCXM_MTTR_IN_Weeks__c == null
                    ? 0
                    : this.gainsightImpactCalculation.CalculateMttrIncidentScore((Integer) customerInfoRecord.JBCXM_MTTR_IN_Weeks__c, GetMultiplierValue('mttr last six months'));
            system.debug('CalculateGainsightNetScore(): mttrIncidentScore - ' + mttrIncidentScore + ' ,JBCXM_MTTR_IN_Weeks__c - ' + customerInfoRecord.JBCXM_MTTR_IN_Weeks__c);

            Double annualContractValueScore = customerInfoRecord.JBCXM__ASV__c == null
                    ? 0
                    : this.gainsightImpactCalculation.CalculateAnnualContractValueScore(customerInfoRecord.JBCXM__ASV__c, GetMultiplierValue('annual contract value'));
            system.debug('CalculateGainsightNetScore(): annualContractValueScore - ' + annualContractValueScore + ' , JBCXM__ASV__c - ' + customerInfoRecord.JBCXM__ASV__c);

            Double creditGivenLastTwelveMonths = customerInfoRecord.JBCXM_Credits__c == null
                    ? 0
                    : this.gainsightImpactCalculation.CalculateCreditGivenLastTwelveMonths(customerInfoRecord.JBCXM_Credits__c, GetMultiplierValue('credits last 12 months'));
            system.debug('CalculateGainsightNetScore(): creditGivenLastTwelveMonths - ' + creditGivenLastTwelveMonths + ' , JBCXM_Credits__c - ' + customerInfoRecord.JBCXM_Credits__c);

            Double healthScore = customerInfoRecord.JBCXM__CurScoreId__r == null || customerInfoRecord.JBCXM__CurScoreId__r.JBCXM__Score__c == null
                    ? 0
                    : this.gainsightImpactCalculation.CalculateHealthScore((Integer) customerInfoRecord.JBCXM__CurScoreId__r.JBCXM__Score__c, GetMultiplierValue('health score'));
            system.debug('CalculateGainsightNetScore(): healthScore - ' + healthScore + ' , JBCXM__CurScoreId__r.JBCXM__Score__c - ' + customerInfoRecord.JBCXM__CurScoreId__r.JBCXM__Score__c);

            Double netScore = outStandingIncidentScore + incidentsOpenedLastSixMonthsScore + mttrIncidentScore + annualContractValueScore + creditGivenLastTwelveMonths + healthScore;
            system.debug('CalculateGainsightNetScore(): netScore - ' + netScore);

            // Store the Gainsight score on the account record
            if (customerInfoRecord.JBCXM__Account__r.Gainsight_Net_Score__c != netScore) {
                Account accountUpdatedRecord = new Account(Id = customerInfoRecord.JBCXM__Account__c, Gainsight_Net_Score__c = netScore);

                accountUpdateList.add(accountUpdatedRecord);
            }
        }

        if(accountUpdateList.size() > 0)
        {
            Database.SaveResult[] saveResults = Database.update(accountUpdateList, false);
            for(Database.SaveResult result :saveResults){
                if(result.isSuccess() == false){
                    system.debug('CalculateGainsightNetScore(): error - '+ result.getErrors()[0]);
                    try{
                        inContactBaseClass.sendErrorEmail(
                                result.getErrors()[0].getMessage() + ' ' + 'Class.ImpactCalculationService.CalculateGainsightNetScore',
                                result.getId()
                        );
                    } catch(System.EmailException emailEx){
                    }

                }
            }
        }

    } // end of CalculateGainsightNetScore()

    public void CalculateAccountNetScore(Account[] accountList){

        List<Account> accountUpdateList = new List<Account>();
        // Loop through the accounts and update the account net score
        for(Account accountRecord : accountList){

            Double ageOfCustomerInMonthsScore = accountRecord.Age_of_Customer_in_Months__c == null
                    ? 0
                    : this.accountImpactCalculation.CalculateAgeOfCustomerInMonthsScore((Integer)accountRecord.Age_of_Customer_in_Months__c, GetMultiplierValue('age of customer'));
            system.debug('CalculateAccountNetScore(): ageOfCustomerInMonthsScore - ' + ageOfCustomerInMonthsScore + ' , Age_of_Customer_in_Months__c - ' + accountRecord.Age_of_Customer_in_Months__c);

            Double riskOfLeavingScore = accountRecord.Risk_of_Leaving__c == null
                    ? 0
                    : this.accountImpactCalculation.CalculateRiskOfLeavingScore(accountRecord.Risk_of_Leaving__c , GetMultiplierValue('risk of leaving'));
            system.debug('CalculateAccountNetScore(): riskOfLeavingScore - ' + riskOfLeavingScore + ' , Risk_of_Leaving__c - ' + accountRecord.Risk_of_Leaving__c);

            Double gyrColor = accountRecord.GYRStatus__c == null
                    ? 0
                    : this.accountImpactCalculation.CalculateGYRColor(accountRecord.GYRStatus__c);
            system.debug('CalculateAccountNetScore(): gyrColor - ' + gyrColor + ' , GYRStatus__c - ' + accountRecord.GYRStatus__c);

            Double strategicAccountScore = accountRecord.CustomerSegment__c == null
                    ? 0
                    : this.accountImpactCalculation.CalculateStrategicAccountScore(accountRecord.CustomerSegment__c, GetMultiplierValue('strategic account'));
            system.debug('CalculateAccountNetScore(): strategicAccountScore - ' + strategicAccountScore + ' , CustomerSegment__c - ' + accountRecord.CustomerSegment__c);

            Double partnerAccountScore = accountRecord.IsPartner__c == null
                    ? 0
                    : this.accountImpactCalculation.CalculatePartnerAccountScore(accountRecord.IsPartner__c, GetMultiplierValue('partner account'));
            system.debug('CalculateAccountNetScore(): partnerAccountScore - ' + partnerAccountScore + ' , IsPartner__c - ' + accountRecord.IsPartner__c);

            Double brandVisibilityScore = accountRecord.Brand_Visibility__c == null
                    ? 0
                    : this.accountImpactCalculation.CalculateBrandVisibilityScore(accountRecord.Brand_Visibility__c, GetMultiplierValue('brand visibility'));
            system.debug('CalculateAccountNetScore(): brandVisibilityScore - ' + brandVisibilityScore + ' , Brand_Visibility__c - ' + accountRecord.Brand_Visibility__c);

            Double industryLeaderScore = accountRecord.Industry_Leadership_Vocality__c == null
                    ? 0
                    : this.accountImpactCalculation.CalculateIndustryLeaderScore(accountRecord.Industry_Leadership_Vocality__c, GetMultiplierValue('industry leadership/vocality'));
            system.debug('CalculateAccountNetScore(): industryLeaderScore - ' + industryLeaderScore + ' , Industry_Leadership_Vocality__c- ' + accountRecord.Industry_Leadership_Vocality__c);

            Double socialMediaPresenceScore = accountRecord.Social_Media_Presence__c == null
                    ? 0
                    : this.accountImpactCalculation.CalculateSocialMediaPresenceScore(accountRecord.Social_Media_Presence__c, GetMultiplierValue('social media presence'));
            system.debug('CalculateAccountNetScore(): socialMediaPresenceScore - ' + socialMediaPresenceScore + ' , Social_Media_Presence__c ' + accountRecord.Social_Media_Presence__c);

            Double currentReferenceScore = accountRecord.Referenceable__c == null
                    ? 0
                    : this.accountImpactCalculation.CalculateCurrentReferenceScore(accountRecord.Referenceable__c, GetMultiplierValue('currently referenceable'));
            system.debug('CalculateAccountNetScore(): currentReferenceScore - ' + currentReferenceScore + ' , Referenceable__c ' + accountRecord.Referenceable__c);

            Double netScore = ageOfCustomerInMonthsScore + riskOfLeavingScore + gyrColor + strategicAccountScore + partnerAccountScore + brandVisibilityScore + industryLeaderScore  + socialMediaPresenceScore + currentReferenceScore;

            system.debug('CalculateAccountNetScore(): netScore - ' + netScore);

            // Store the account net score on the account record
            if (accountRecord.Account_Net_Score__c  != netScore) {
                accountRecord.Account_Net_Score__c = netScore;
                accountUpdateList.add(accountRecord);
            }
        }
        // update account net score
        if(accountUpdateList.size() > 0)
        {
            Database.SaveResult[] saveResults = Database.update(accountUpdateList, false);
            for(Database.SaveResult result :saveResults){
                if(result.isSuccess() == false){
                    system.debug('CalculateAccountNetScore(): error - '+ result.getErrors()[0]);
                    try{
                        inContactBaseClass.sendErrorEmail(
                                result.getErrors()[0].getMessage() + ' ' + 'Class.ImpactCalculationService.CalculateAccountNetScore',
                                result.getId()
                        );
                    } catch(System.EmailException emailEx){
                    }

                }
            }
        }

    }

    private Double GetMultiplierValue(String key)
    {
        //if the key doesn't exist, return 1 as the multiplier.
        if(multiplierMap.containsKey(key))
        {
            return multiplierMap.get(key).Multiplier__c;
        }
        else
        {
            return 1;
        }
    }
}