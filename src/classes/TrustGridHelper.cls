/**
 * Created by mohandaas.rangaswamy on 11/9/2016.
 */

public class TrustGridHelper {

    private static final Map<String, String> clusterFieldMap = new Map<String, String>{
        //'inContact' => 'inContact_Cluster__c',
        'Cluster' => 'inContact_Cluster__c',
        'Verint' => 'Verint_Cluster__c',
        'NWFM' => 'NICE_WFM_Cluster__c',
        'NQM' => 'NICE_QM_Cluster__c'

    };

    private Integer cadebillAccountNo;
    private Set<String> platformSet = null;
    private Set<String> productSet = null;
    public Account customer;

    public static list<string> Platforms = null;

    public Set<String> getPlatforms(){
        return platformSet == null ? new Set<String>() : platformSet;
    }

    // Constructor
    public TrustGridHelper(Integer cadebillAccountNo){ //, Date startDate, Integer daysBack){
        
        this.cadebillAccountNo = cadebillAccountNo;
        //this.startDate = startDate;
        //this.daysBack = daysBack;
        platformSet = new Set<String>();
        productSet = new Set<String>();

        List<Account> accountList = [
                SELECT ID, inContact_Cluster__c, Verint_Cluster__c, NICE_WFM_Cluster__c, NICE_QM_Cluster__c, RecordType.Name
                FROM Account
                WHERE CadebillAccountNo__c = :cadebillAccountNo LIMIT 1
        ];
        if(accountList.isEmpty()){
            throw new TrustGridException('No account found.');
        }
        customer = accountList[0];
        findPlatformsAndProducts();
        
    } // end of Constructor


    // Get platforms and products impacted
    private void findPlatformsAndProducts()
    {

        List<Account> accountList = new List<Account>();
        accountList.add(customer);
        
        Map<String,ProductEventMap__c> productEventMap = ProductEventMap__c.getAll();
        if(productEventMap.isEmpty()){
            return;
        }
        List<ProductEventMap__c> productEventList = new List<ProductEventMap__c>(productEventMap.values());
        productEventMap = new Map<String, ProductEventMap__c>();
        for(ProductEventMap__c productEvent : productEventList){
            if(productEvent.DoNotPost__c){
                continue;
            }
            if(productEvent.AllCustomers__c){
                platformSet.add(productEvent.Platform__c);
                productSet.add(productEvent.Product__c);
            }
            if(productEvent.ImplementedProduct__c != null) {
                productEventMap.put(productEvent.ImplementedProduct__c, productEvent);
            }
        }
       // system.debug('**** DEBUG: findPlatformsAndProducts(): productEventMap - ' + productEventMap);
        if(productEventMap.isEmpty()){
            return;
        }
        
        // select child accounts
        if(customer.RecordType.Name == 'Resell Partner')
        {
            for(Account child :[
                    SELECT Id, inContact_Cluster__c, Verint_Cluster__c, NICE_QM_Cluster__c, NICE_WFM_Cluster__c, RecordType.Name
                    FROM Account
                    WHERE ParentId = :customer.Id
            ]){
                accountList.add(child);
            }
        }
        
        // select implemented products
        List<ImplementedProduct__c> impProductList = new List<ImplementedProduct__c>();
        for(ImplementedProduct__c ip :[
                SELECT Account__c, Product__c FROM ImplementedProduct__c
                WHERE Account__c IN :accountList AND GoLiveDate__c != NULL
        ]){
            impProductList.add(ip);
        }
        system.debug('**** DEBUG: findPlatformsAndProducts(): impProductList - ' + impProductList);
        if(impProductList.isEmpty()){
            return;
        }

        for(ImplementedProduct__c ip :impProductList)
        {
            ProductEventMap__c productEvent = productEventMap.get(ip.Product__c);
          //  system.debug('**** DEBUG: findPlatformsAndProducts(): productEvent - ' + productEvent);
            if(productEvent == null){
                continue;
            }

            if(productEvent.HasClusters__c){
                for(Account account : accountList){
                    for(String cluster : clusterFieldMap.keySet()){
                        String fieldName = clusterFieldMap.get(cluster);
                        String accountCluster = (String)account.get(fieldName);
                        if(accountCluster != null && productEvent.Platform__c.startsWith(cluster)){
                            String platform = productEvent.Platform__c.replaceFirst(cluster, accountCluster);
                            platformSet.add(platform);

                        }
                    }
                }
            }
            else
            {
                platformSet.add(productEvent.Platform__c);
            }
            productSet.add(productEvent.Product__c);
        }

      //  system.debug('**** DEBUG: findPlatformsAndProducts(): platformSet - ' + platformSet);
        system.debug('**** DEBUG: findPlatformsAndProducts(): productSet  - ' + productSet);

    } // end of findPlatformsAndProducts()

    public List<Case> getEvents(Date startDate, date endDate)
    {

        List<Case> eventList = new List<Case>();

        String platformString = '';
        String queryString = '';
        if(productSet.size() > 0 && platformSet.size() > 0){
            for(String platform : platformSet){
                platformString += ( platformString.length() > 0 ? ',' : '') + '\'' + platform + '\'';
            }
            system.debug('**** DEBUG: platformString - ' + platformString);
            queryString = 'SELECT Id, Subject, EventStartDateTime__c, EventEndDateTime__c, EventType__c, PlatformsImpacted__c FROM Case '
                            + 'WHERE RecordType.Name = \'Event\' AND NonEvent__c = false AND InternalEvent__c = false '
                            + 'AND ProductImpacted__c IN :productSet AND PlatformsImpacted__c includes (' + platformString + ') '
                            + ' AND ((EventStartDateTime__c >= :endDate AND EventStartDateTime__c <= :startDate)'
                            + ' OR EventEndDateTime__c = NULL) AND ID NOT IN(SELECT Event__c FROM EventAccount__c WHERE Account__r.CadebillAccountNo__c = :cadebillAccountNo AND Excluded__c = true) ';
            system.debug('**** DEBUG: queryString - ' + queryString);
            eventList = Database.Query(queryString);
        }
        system.debug('**** DEBUG: eventList - ' + eventList);

        queryString = 'SELECT Id, Subject, EventStartDateTime__c, EventEndDateTime__c, EventType__c, PlatformsImpacted__c FROM Case '
                        + 'WHERE ID IN(SELECT Event__c FROM EventAccount__c WHERE Account__r.CadebillAccountNo__c = :cadebillAccountNo AND Excluded__c = false) '
                        + 'AND RecordType.Name = \'Event\' AND NonEvent__c = false AND InternalEvent__c = false  '
                        + ' AND ((EventStartDateTime__c >= :endDate AND EventStartDateTime__c <= :startDate )'
                        + ' OR EventEndDateTime__c = NULL)';
        List<Case> eventSpecificList = Database.Query(queryString);
        system.debug('**** DEBUG: eventSpecificList - ' + eventSpecificList);
        if(eventSpecificList.size() > 0)
        {
            eventList.addAll(eventSpecificList);
        }

        return eventList;

    } // end of getEvents()

    // Call inContactTrustWebservice
    public static List<Case> GetEventsByAccounts(Date startDate, date endDate, integer acctNo){
        integer daysBack = endDate.daysBetween(startDate);
        list<Case> lstCases = new list<Case>();
        Platforms = new list<string>();
        inContactTrustWebService.CustomerNodeEvents cn = inContactTrustWebService.SelectTrustNodesByCustomerAndDaysBackLocal(acctNo, daysBack);

        for(inContactTrustWebService.TrustNode tn : cn.trustNodes)
        {
            Case c = new Case(
                    Id = tn.caseId,
                    PlatformsImpacted__c = tn.nodes,
                    EventType__c = tn.eventType,
                    EventStartDateTime__c = tn.eventStartDate,
                    EventEndDateTime__c = tn.eventEndDate
            );

            lstCases.add(c);
        }

        Platforms = cn.customerNodes;
        return lstCases;



    }




}