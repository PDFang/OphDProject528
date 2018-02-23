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

            Double priorityScore = caseRecord.Priority == null
                    ? 0
                    : impactCalculator.CalculateIncidentPriorityScore(caseRecord.Priority, GetMultiplierValue('incident priority'));
            system.debug('CalculateIncidentNetScore(): priorityScore - ' + priorityScore + ' , Severity__c - ' + caseRecord.Priority);

            Double securityScore = caseRecord.Security_Issue__c == null
                    ? 0
                    : impactCalculator.CalculateSecurityIssueScore(caseRecord.Security_Issue__c, GetMultiplierValue('is security issue'));
            system.debug('CalculateIncidentNetScore(): securityScore - ' + securityScore + ' , Security_Issue__c - ' + caseRecord.Security_Issue__c);

            Double knownIssueScore = caseRecord.Related_to_Previous_Known_Issue__c == null
                    ? 0
                    : impactCalculator.CalculateRelatedKnownIssueScore(caseRecord.Related_to_Previous_Known_Issue__c, GetMultiplierValue('is known issue'));
            system.debug('CalculateIncidentNetScore(): knownIssueScore - ' + knownIssueScore + ' , Related_to_Previous_Known_Issue__c ' + caseRecord.Related_to_Previous_Known_Issue__c);

            Double repeatIssueScore = caseRecord.RepeatIssue__c == null
                    ? 0
                    : impactCalculator.CalculateRepeatIssueScore(caseRecord.RepeatIssue__c, GetMultiplierValue('repeat issue'));
            system.debug('CalculateIncidentNetScore(): repeatIssueScore - ' + repeatIssueScore + ' , Severity__c - ' + caseRecord.RepeatIssue__c);

            Double netScore = severityScore + securityScore + knownIssueScore + priorityScore + repeatIssueScore;
            system.debug('CalculateIncidentNetScore(): netScore - ' + netScore);
            //store the net score
            caseRecord.Incident_Net_Score__c = netScore;

        }
    } // end of CalculateIncidentNetScore()

    public void CalculateGainsightNetScore(JBCXM__CustomerInfo__c[] customInfoList){
        List<Account> accountUpdateList = new List<Account>();

        for(JBCXM__CustomerInfo__c customerInfoRecord :customInfoList) {

            // Calculate the Gainsight Score

            Double mrrValueScore = customerInfoRecord.JBCXM__MRR__c == null
                    ? 0
                    : this.gainsightImpactCalculation.CalculateMRRScore(customerInfoRecord.JBCXM__MRR__c, GetMultiplierValue('mrr'));
            system.debug('CalculateGainsightNetScore(): mrrValueScore - ' + mrrValueScore + ' , JBCXM__MRR__c - ' + customerInfoRecord.JBCXM__MRR__c);

            Double creditGivenLastTwelveMonths = customerInfoRecord.JBCXM_Credits__c == null
                    ? 0
                    : this.gainsightImpactCalculation.CalculateCreditGivenLastTwelveMonths(customerInfoRecord.JBCXM_Credits__c, GetMultiplierValue('credits last 12 months'));
            system.debug('CalculateGainsightNetScore(): creditGivenLastTwelveMonths - ' + creditGivenLastTwelveMonths + ' , JBCXM_Credits__c - ' + customerInfoRecord.JBCXM_Credits__c);

            Double healthScore = customerInfoRecord.JBCXM__CurScoreId__r == null || customerInfoRecord.JBCXM__CurScoreId__r.JBCXM__Score__c == null
                    ? 0
                    : this.gainsightImpactCalculation.CalculateHealthScore((Integer) customerInfoRecord.JBCXM__CurScoreId__r.JBCXM__Score__c, GetMultiplierValue('health score'));
            system.debug('CalculateGainsightNetScore(): healthScore - ' + healthScore + ' , JBCXM__CurScoreId__r.JBCXM__Score__c - ' + customerInfoRecord.JBCXM__CurScoreId__r.JBCXM__Score__c);

            Double netScore = mrrValueScore + creditGivenLastTwelveMonths + healthScore;
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
            Database.Error[] errors = new Database.Error[]{};
            for(Database.SaveResult result :saveResults){
                if(result.isSuccess() == false){
                    system.debug('CalculateGainsightNetScore(): error - '+ result.getErrors()[0]);
                    errors.addAll(result.getErrors());
                }
            }
            if(errors.size() > 0) {
                try {
                    inContactBaseClass.sendErrorEmail(
                            errors[0].getMessage() + ' ' + 'No of errors ' +  errors.size() + ' ' + 'Class.ImpactCalculationService.CalculateGainsightNetScore',
                            null
                    );
                } catch (System.EmailException emailEx) {}
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

            /*Double gyrColor = accountRecord.GYRStatus__c == null
                    ? 0
                    : this.accountImpactCalculation.CalculateGYRColor(accountRecord.GYRStatus__c);
            system.debug('CalculateAccountNetScore(): gyrColor - ' + gyrColor + ' , GYRStatus__c - ' + accountRecord.GYRStatus__c);*/

            Double strategicAccountScore = accountRecord.CustomerSegment__c == null
                    ? 0
                    : this.accountImpactCalculation.CalculateStrategicAccountScore(accountRecord.CustomerSegment__c, GetMultiplierValue('strategic account'));
            system.debug('CalculateAccountNetScore(): strategicAccountScore - ' + strategicAccountScore + ' , CustomerSegment__c - ' + accountRecord.CustomerSegment__c);

            Double partnerAccountScore = accountRecord.RecordType.Name == null
                    ? 0
                    : this.accountImpactCalculation.CalculatePartnerAccountScore(accountRecord.RecordType.Name, GetMultiplierValue('partner account'));
            system.debug('CalculateAccountNetScore(): partnerAccountScore - ' + partnerAccountScore + ' , RecordTypeName - ' + accountRecord.RecordType.Name);

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

            Double netScore = ageOfCustomerInMonthsScore + riskOfLeavingScore + strategicAccountScore + partnerAccountScore + brandVisibilityScore + industryLeaderScore  + socialMediaPresenceScore + currentReferenceScore;

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
            Database.Error[] errors = new Database.Error[]{};
            for(Database.SaveResult result :saveResults){
                if(result.isSuccess() == false){
                    system.debug('CalculateAccountNetScore(): error - '+ result.getErrors()[0]);
                    errors.addAll(result.getErrors());
                }
            }
            if(errors.size() > 0) {
                try {
                    inContactBaseClass.sendErrorEmail(
                            errors[0].getMessage() + ' ' + 'No of errors ' +  errors.size() + ' ' + 'Class.ImpactCalculationService.CalculateAccountNetScore',
                            null
                    );
                } catch (System.EmailException emailEx) {}
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