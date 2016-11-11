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

    // Get all the platforms
    public static Set<String> getPlatformsByCustomer(Integer cadebillAccountNo)
    {
        Set<String> platforms = new Set<String>();
        Set<String> products = new Set<String>();

        List<Account> accountList = [
                SELECT ID, inContact_Cluster__c, Verint_Cluster__c, NICE_WFM_Cluster__c, NICE_QM_Cluster__c, RecordType.Name
                FROM Account
                WHERE CadebillAccountNo__c = :cadebillAccountNo LIMIT 1
        ];
        if(accountList.isEmpty()){
            return platforms;
        }
        Account customer = accountList[0];
        system.debug('**** DEBUG: getPlatformsByCustomer(): customer - ' + customer);

        Map<String,ProductEventMap__c> productEventMap = ProductEventMap__c.getAll();
        if(productEventMap.isEmpty()){
            return platforms;
        }
        List<ProductEventMap__c> productEventList = new List<ProductEventMap__c>(productEventMap.values());
        productEventMap = new Map<String, ProductEventMap__c>();
        for(ProductEventMap__c productEvent : productEventList){
            if(productEvent.DoNotPost__c){
                continue;
            }
            productEventMap.put(productEvent.ImplementedProduct__c, productEvent);
        }
        system.debug('**** DEBUG: getPlatformsByCustomer(): productEventMap - ' + productEventMap);
        if(productEventMap.isEmpty()){
            return platforms;
        }

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

        List<ImplementedProduct__c> impProductList = new List<ImplementedProduct__c>();
        for(ImplementedProduct__c ip :[
                SELECT Account__c, Product__c FROM ImplementedProduct__c
                WHERE Account__c IN :accountList AND GoLiveDate__c != NULL
        ]){
            impProductList.add(ip);
        }

        if(impProductList.isEmpty()){
            return platforms;
        }

        for(ImplementedProduct__c ip :impProductList)
        {
            //node = ''; // arnab changes here
            system.debug('**** DEBUG: getPlatformsByCustomer(): ip - ' + ip);
            ProductEventMap__c productEvent = productEventMap.get(ip.Product__c);
            system.debug('**** DEBUG: getPlatformsByCustomer(): productEvent - ' + productEvent);
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
                            platforms.add(platform);

                        }
                    }
                }
            }
            else
            {
                platforms.add(productEvent.Platform__c);
            }

            products.add(productEvent.Product__c);

        }

        system.debug('platforms == > ' + platforms);
        return platforms;

    } // end of getPlatformsByCustomer()


}