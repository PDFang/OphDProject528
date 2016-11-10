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


        Map<String,Set<String>> resellCustomerClusters = new Map<String,Set<String>>();
        Map<String,ProductEventMap__c> nodeMap = ProductEventMap__c.getAll();
        ImplementedProduct__c[] implementedProducts = new ImplementedProduct__c[]{};

        //ProductPlatformMap__c nodeMap = new ProductPlatformMap__c();
        String node;
        String[] nodes = new String[]{};
        String[] productList = new String[]{};

        Set<Id> accountIdSet = new Set<Id>();
        accountIdSet.add(customer.Id);

        if(customer.RecordType.Name == 'Resell Partner')
        {

                for(Account child :[
                        SELECT Id, inContact_Cluster__c, Verint_Cluster__c, NICE_QM_Cluster__c, NICE_WFM_Cluster__c, RecordType.Name
                        FROM Account
                        WHERE ParentId = :customer.Id
                ]){
                    accountList.add(child);
                }
/*
                implementedProducts = [SELECT Product__c FROM ImplementedProduct__c WHERE Account__c IN :childAccounts.keySet() AND GoLiveDate__c != NULL];
                system.debug('implementedProducts => ' + implementedProducts);
                for(Account resellAccount:childAccounts.values())
                {
                    resellCustomerClusters = ResellCustomerClusterMap(resellCustomerClusters, resellAccount.inContact_Cluster__c, 'inContact');
                    resellCustomerClusters = ResellCustomerClusterMap(resellCustomerClusters, resellAccount.Verint_Cluster__c, 'Verint');
                    resellCustomerClusters = ResellCustomerClusterMap(resellCustomerClusters, resellAccount.NICE_WFM_Cluster__c, 'NWFM');
                    resellCustomerClusters = ResellCustomerClusterMap(resellCustomerClusters, resellAccount.NICE_QM_Cluster__c, 'NQM');
                }
*/
        }
        else
        {
            //implementedProducts = [SELECT Product__c FROM ImplementedProduct__c WHERE Account__c = :customer.Id AND GoLiveDate__c != NULL];
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

        Map<String, ProductEventMap__c> productEventMap = ProductEventMap__c.getAll();
        if(productEventMap.isEmpty()){
            return platforms;
        }

        productEventMap = new Map<String, ProductEventMap__c>();
        for(ProductEventMap__c productEvent : productEventMap.values()){
            if(!productEvent.DoNotPost__c){
                continue;
            }
            productEventMap.put(productEvent.ImplementedProduct__c, productEvent);
        }
        if(productEventMap.isEmpty()){
            return platforms;
        }

        for(ImplementedProduct__c ip :impProductList)
        {
            node = ''; // arnab changes here
            ProductEventMap__c productEvent = productEventMap.get(ip.Product__c);
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
/*
            if(productEvent.HasClusters__c && customer.RecordType.Name != 'Resell Partner')
            {
                if(customer.inContact_Cluster__c != NULL && productEvent.Platform__c.startsWith('Cluster'))
                    node = productEvent.Platform__c.replaceFirst('Cluster', customer.inContact_Cluster__c.trim());
                if(customer.Verint_Cluster__c != NULL && productEvent.Platform__c.startsWith('Verint')) // arnab
                    node = productEvent.Platform__c.replaceFirst('Verint', customer.Verint_Cluster__c.trim());
                if(customer.NICE_WFM_Cluster__c != NULL && productEvent.Platform__c.startsWith('NWFM')) // arnab
                    node = productEvent.Platform__c.replaceFirst('NWFM', customer.NICE_WFM_Cluster__c.trim());
                if(customer.NICE_QM_Cluster__c != NULL && productEvent.Platform__c.startsWith('NQM')) // arnab
                    node = productEvent.Platform__c.replaceFirst('NQM', customer.NICE_QM_Cluster__c.trim());

            }
            else if(productEvent.HasClusters__c && customer.RecordType.Name == 'Resell Partner' && !resellCustomerClusters.isEmpty())
            {

                //system.debug('platform => ' + productEvent.Platform__c);
                //system.debug('product => ' + productEvent.Product__c);
                //loop through resell customer notes
                //if(productEvent.Platform__c.startsWith('Cluster'))
                if(productEvent.Platform__c.startsWith('Cluster') && resellCustomerClusters.containsKey('inContact'))
                {
                    for(string resellCluster:resellCustomerClusters.get('inContact'))
                    {
                        platforms.add(productEvent.Platform__c.replace('Cluster',resellCluster));
                    }
                } else if(productEvent.Platform__c.startsWith('Verint') && resellCustomerClusters.containsKey('Verint'))
                {

                    for(string resellCluster:resellCustomerClusters.get('Verint'))
                    {
                        platforms.add(productEvent.Platform__c.replace('Verint',resellCluster));
                    }
                }else if(productEvent.Platform__c.startsWith('NWFM') && resellCustomerClusters.containsKey('NWFM'))
                {

                    for(string resellCluster:resellCustomerClusters.get('NWFM'))
                    {
                        platforms.add(productEvent.Platform__c.replace('NWFM',resellCluster));
                    }
                }else if(productEvent.Platform__c.startsWith('NQM') && resellCustomerClusters.containsKey('NQM'))
                {

                    for(string resellCluster:resellCustomerClusters.get('NQM'))
                    {
                        platforms.add(productEvent.Platform__c.replace('NQM',resellCluster));
                    }
                }
            }
*/
            else
            {
                //node = productEvent.Platform__c;
                platforms.add(productEvent.Platform__c);
            }

            // system.debug('platforms == > ' + platforms);
            products.add(productEvent.Product__c);
            //system.debug(productEvent.ImplementedProduct__c + ' --- ' + i.Product__c);
            //system.debug(productEvent.Product__c);

            //system.debug(productEvent.ImplementedProduct__c + ' --- ' + i.Product__c);
/*
            if(node != null)
            {
                platforms.add(node);
            }
*/
        }

        nodes.addAll(platforms);
        productList.addAll(products);
        //ProductNode pn = new ProductNode(productList, nodes);
        //return pn;
        return platforms;
    }
/*
    private static Map<String,Set<String>> ResellCustomerClusterMap(Map<String,Set<String>> rcClusterMap, String clusterField, string platform)
    {
        if(clusterField != NULL)
        {
            if(rcClusterMap.containsKey(platform))
            {
                rcClusterMap.get(platform).add(clusterField);
            }
            else
            {
                rcClusterMap.put(platform,new Set<String>{clusterField});
            }
        }

        return rcClusterMap;
    }
*/
}