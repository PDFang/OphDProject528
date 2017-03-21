/**
 * Created by arnab.karsarkar on 3/15/2017.
 */

public with sharing class KnownIssueImpactCalculationClass {

    private KnownIssuesImpactCalculationInterface impactCalculator;
    private Map<String, Impact_Score_Multiplier__c> multiplierMap;
    private map<Id, integer> KnownIssueIncidentCounts;
    private map<Id, double> KnownIssueIncidentMaxScore;
    private map<Id, integer> KnownIssueIncidentAge;
    private map<Id, double> KnownIssueASVMap;
    private set<id> accountIds;

    public KnownIssueImpactCalculationClass(KnownIssuesImpactCalculationInterface impactCalculator)
    {
        //store the impactCalculator and the multiplier map for this.
        this.impactCalculator = impactCalculator;
        this.multiplierMap = Impact_Score_Multiplier__c.getAll();
        KnownIssueIncidentCounts  = new map<Id, integer>();
        KnownIssueIncidentAge = new map<Id, integer>();
        KnownIssueIncidentMaxScore= new map<Id, double>();
        KnownIssueASVMap = new map<Id, double>();
        accountIds = new set<id>();
    }

    public void CalculateKnownIssueScore(list<Case> knownIssueList){
        if(knownIssueList.isEmpty())
            return;

        set<Id> KnownIssueIds = new set<Id>();
        map<Id, set<Id>> KnownIssueAccounts = new map<Id, set<Id>>();
        double netKnownIssueScore;
        list<Case> updKnowIssueList = new list<Case>();

        for(case c: knownIssueList){
            KnownIssueIds.add(c.Id);
        }

        Try{
            GetIncidentValues(KnownIssueIds);
            KnownIssueAccounts = GetAccountsAssociated(KnownIssueIds);
            GetAccountASVValue(KnownIssueAccounts);

            /*system.debug('KnownIssueIncidentAge =>' + KnownIssueIncidentAge);
            system.debug('KnownIssueIncidentAge =>' + KnownIssueIncidentCounts);
            system.debug('KnownIssueIncidentAge =>' + KnownIssueASVMap);*/

            for(Case KnownIssuCase : knownIssueList){
                Case newCase = new Case(Id = KnownIssuCase.Id);
                newCase.TotalDaysBugPresent__c = KnownIssueIncidentAge.get(KnownIssuCase.Id);
                newCase.NumberOfIncidents__c = KnownIssueIncidentCounts.get(KnownIssuCase.Id);
                newCase.ASVValue__c = KnownIssueASVMap.get(KnownIssuCase.Id);

                netKnownIssueScore = impactCalculator.CalculateNumberIncidentsTiedToIssue(KnownIssueIncidentCounts.get(KnownIssuCase.Id), GetMultiplierValue('IncidentCount'));
                system.debug('netKnownIssueScore 1 =>' + netKnownIssueScore);
                netKnownIssueScore += impactCalculator.CalculateDaysIssuePresent(KnownIssueIncidentAge.get(KnownIssuCase.Id), GetMultiplierValue('IncidentAge'));
                system.debug('netKnownIssueScore 2 =>' + netKnownIssueScore);
                netKnownIssueScore += KnownIssueIncidentMaxScore.get(KnownIssuCase.Id);
                system.debug('netKnownIssueScore 3 =>' + netKnownIssueScore);
                netKnownIssueScore += impactCalculator.CalculateDollarAmountTiedToIssue(KnownIssueASVMap.get(KnownIssuCase.Id), GetMultiplierValue('ASVMultiplier'));
                system.debug('netKnownIssueScore 4 =>' + netKnownIssueScore);
                netKnownIssueScore += impactCalculator.CalculateRecentReleaseBreak(GetBrokenByRelease(KnownIssuCase), GetMultiplierValue('BrokenByRelease'));
                system.debug('netKnownIssueScore 5 =>' + netKnownIssueScore);
                newCase.KIImpactScore__c = netKnownIssueScore;
                updKnowIssueList.add(newCase);
            }

            update updKnowIssueList;
            string body = 'Successfully Updated ' + knownIssueList.size() + ' known issues';
            string subject = 'Success';
            if(!Test.isRunningTest())
                SendEmail(subject, body);

        }Catch(Exception ex){
            string body = 'There is an exception occured - ' + ex.getMessage() + ' at line number ' + ex.getLineNumber();
            string subject = 'Error Occured';
            SendEmail(subject, body);
        }
    }

    private boolean GetBrokenByRelease(case c){
        if(c.Broken_by_Recent_Release__c == 'Yes')
                return true;
        else
                return false;
    }

    private void GetIncidentValues(set<Id> knownIssueIds) {
        AggregateResult[] groupedResults = [
                select KnownIssue__c, Min(CreatedDate) MINDT, Count(Id) CNTID, MAX(IncidentImpactScore__c) MAXSCORE
                from Case
                where KnownIssue__c in :KnownIssueIds
                and RecordType.Name = 'Incident'
                group by KnownIssue__c
        ];
        for (AggregateResult ar : groupedResults)  {
            system.debug('Count =>' + ar.get('CNTID'));
            Id knownIssueId = (ID)ar.get('KnownIssue__c');
            KnownIssueIncidentCounts.put(knownIssueId, Integer.valueOf(ar.get('CNTID')));
            Date minimumDate = Date.valueOf(ar.get('MINDT'));
            integer incidentOpeDays = minimumDate.daysBetween(system.today());
            KnownIssueIncidentAge.put(knownIssueId, incidentOpeDays);
            double maxScore = 0.0;
            if(ar.get('MAXSCORE') != null) {
                maxScore = double.valueOf(ar.get('MAXSCORE'));
            }
            KnownIssueIncidentMaxScore.put(knownIssueId,maxScore);
        }
    }

    //
    private map<Id, set<Id>> GetAccountsAssociated(Set<id> KnownIssueIds){
        map<Id, set<Id>> knownIssueAccountIds = new map<Id, set<Id>>();
        for(Case incidents : [select Id, KnownIssue__c, AccountId from Case where KnownIssue__c in : KnownIssueIds and RecordType.Name = 'Incident']){
            accountIds.add(incidents.AccountId);
            if(knownIssueAccountIds.containsKey(incidents.KnownIssue__c))
                    knownIssueAccountIds.get(incidents.KnownIssue__c).add(incidents.AccountId);// existing knownissue
            else
                    knownIssueAccountIds.put(incidents.KnownIssue__c, new set<Id>{incidents.AccountId});// new knownissue
        }
        return knownIssueAccountIds;
    }

    private void GetAccountASVValue( map<Id, set<Id>> KnownIssueAccounts){
        map<Id, Double> accountASVMap = new map<Id, Double>();

        for(JBCXM__CustomerInfo__c customerInfo : [select Id, JBCXM__ASV__c, JBCXM__Account__c
                                                   FROM JBCXM__CustomerInfo__c
                                                    where JBCXM__Account__c in : accountIds]){

            if(customerInfo.JBCXM__ASV__c != null && customerInfo.JBCXM__ASV__c != 0){
                double ASVinMil = customerInfo.JBCXM__ASV__c.divide(1000000, 2);
                accountASVMap.put(customerInfo.JBCXM__Account__c, ASVinMil);
            }
            else
                accountASVMap.put(customerInfo.JBCXM__Account__c, 0);
        }

        system.debug('KnownIssueAccounts =>' + KnownIssueAccounts);
        for(Id kiId : KnownIssueAccounts.keySet()){
            double totalASVVal = 0.0;
            for(Id acctId : KnownIssueAccounts.get(kiId)){
                if(accountASVMap.containsKey(acctId)){
                    totalASVVal += accountASVMap.get(acctId);
                }
            }
            KnownIssueASVMap.put(kiId, totalASVVal);
        }
    }


    private Decimal GetMultiplierValue(String key)
    {
        //if the key doesn't exist, return 1 as the multiplier
        decimal multiplier = 1.0;
        if(multiplierMap.containsKey(key))
        {
            multiplier = multiplier.setScale(2);
            multiplier = multiplierMap.get(key).Multiplier__c;
            return multiplier;
        }
        else
        {
            return 1.0;
        }
    }

    private void SendEmail(string subject, string body){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {'Arnab.KarSarkar@incontact.com', 'Ravish.Chawla@incontact.com', 'William.Nelson@incontact.com'};
        mail.setToAddresses(toAddresses);
        mail.setSubject(subject);
        mail.setHtmlBody(body);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }

}