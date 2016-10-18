global class inContactTrustWebService 
{
    webservice static CustomerNodeEvents SelectTrustNodesByCustomerAndDaysBack(integer account_no, integer daysBack)
    {
        
        String[] customerNodes;
        TrustNode[] trustNodes;
        
        ProductNode pn = inContactTrustWebService.SelectTrustNodeByCustomer(account_no);
        trustNodes = inContactTrustWebService.SelectEventsByNodesAndDaysBack(pn,daysBack, account_no);
        
        CustomerNodeEvents cne = new CustomerNodeEvents(pn.nodes, trustNodes);
        
        return cne;
    }
    
    webservice static List<MaintenanceNotification> SelectMaintenanceNotificationsByCustomerAndDates(integer account_no, datetime startDate, datetime endDate)
    {
        List<MaintenanceNotification> notifications = new List<MaintenanceNotification>();
        Case[] notificationCases = new Case[]{};
        Case[] notificationSpecificCases = new Case[]{};
        String nodeString = '';
        String productString = '';
        String queryString;
        String[] nodes = new String[]{};
        
        ProductNode prodNodes = inContactTrustWebService.SelectTrustNodeByCustomer(account_no);
        nodes = prodNodes.nodes;
        
        
        if(nodes != null)
        {
            nodeString = QueryFilterParse(nodes);
        }
        
        if(prodNodes.products != null)
        {
            productString = QueryFilterParse(prodNodes.products);
        }
        
        if(productString != '' && nodeString != '')
        {
            
            queryString = 'SELECT Id, ProductImpacted__c, CaseNumber, Carrier__c, Description, Subject, EventStartDateTime__c, EventEndDateTime__c, EventType__c, PlatformsImpacted__c FROM Case WHERE NonEvent__c = false AND InternalEvent__c = false AND ProductImpacted__c IN (' + productString + ') AND PlatformsImpacted__c includes (' + nodeString + ') AND ((EventStartDateTime__c >= :startDate AND EventStartDateTime__c <= :endDate) OR (EventEndDateTime__c >= :startDate AND EventEndDateTime__c <= :endDate)) AND ID NOT IN(SELECT Event__c FROM EventAccount__c WHERE Account__r.CadebillAccountNo__c = ' + account_no + ' AND Excluded__c = true) AND RecordType.Name = \'Maintenance Notification\'';
            system.debug(queryString);
            notificationCases = Database.Query(queryString);
        }
        
        queryString = 'SELECT Id, CaseNumber, ProductImpacted__c, Carrier__c, Description, Subject, EventStartDateTime__c, EventEndDateTime__c, EventType__c, PlatformsImpacted__c FROM Case WHERE ID IN(SELECT Event__c FROM EventAccount__c WHERE Account__r.CadebillAccountNo__c = ' + account_no + ' and Excluded__c = false) AND NonEvent__c = false AND InternalEvent__c = false AND ((EventStartDateTime__c >= :startDate AND EventStartDateTime__c <= :endDate) OR (EventEndDateTime__c >= :startDate AND EventEndDateTime__c <= :endDate)) AND RecordType.Name = \'Maintenance Notification\'';        
        notificationSpecificCases = Database.Query(queryString);
        
        if(!notificationSpecificCases.isEmpty())
        {
            notificationCases.addAll(notificationSpecificCases);
        }
        
        if(!notificationCases.isEmpty())
        {
            for(Case e:notificationCases)
            {
                if(e.EventStartDateTime__c != null)
                {
                    system.debug(e.Id);
                    MaintenanceNotification mn = new MaintenanceNotification(e.EventStartDateTime__c,e.EventEndDateTime__c, e.Subject, e.Description, e.EventType__c, e.Carrier__c, e.PlatformsImpacted__c, e.CaseNumber, e.ProductImpacted__c);
                    notifications.add(mn);
                }
            }
        }
        
        return notifications;
    }
    
    webservice static List<Case> SelectKnownIssuesByCustomer(integer account_no, string searchFilter)
    {
        Case[] knownIssueCases = new Case[]{};
        Case[] knownIssueSpecificCases = new Case[]{};
        SiteConfiguration__c siteConfig = new SiteConfiguration__c();
        String retentionDays;
        String nodeString = '';
        String productString = '';
        String queryString;
        String[] nodes = new String[]{};
        
        siteConfig = SiteConfiguration__c.getInstance(inContactBaseClass.OrgId15Digit);
        system.debug(UserInfo.getOrganizationId());
        //set retentionDays
        if(siteConfig.DaysToDisplayKnownIssues__c == null)
        { 
            retentionDays = '0';
        }
        else
        {
            retentionDays = string.valueOf(integer.valueOf(siteConfig.DaysToDisplayKnownIssues__c));
        }
        
        ProductNode prodNodes = inContactTrustWebService.SelectTrustNodeByCustomer(account_no);
        ProductNode allCustomerNodes = inContactTrustWebService.SelectAllCustomerNodes();
        nodes = prodNodes.nodes;
        
        if(nodes != null)
        {
        	nodes.addAll(allCustomerNodes.nodes);
        }
        else
        {
            nodes = allCustomerNodes.nodes;
        }
        
        if(nodes != null)
        {
            nodeString = QueryFilterParse(nodes);
        }
        
        Set<string> products = new Set<string>();
        if(prodNodes.products != null)
        {
            products.addAll(prodNodes.products);
        }
        
        if(allCustomerNodes.products != null)
        {
            products.addAll(allCustomerNodes.products);
        }
        
        if(!products.isEmpty())
        {
            productString = QueryFilterParse(new List<string>(products));
        }
        
        system.debug(productString);
        system.debug(nodeString);
        if(productString != '' && nodeString != '')
        {
            
            queryString = 'SELECT Id, LatestPublicUpdate__c, PlatformsReleased__c, CaseNumber, CreatedDate, ClosedDate, Subject, Summary__c, Steps_to_Recreate__c, Workaround__c, Status, LastModifiedDate, ProductImpacted__c, PlatformsImpacted__c, Release__c, (SELECT CaseNumber FROM KnownIssues__r) FROM Case WHERE (IsClosed = false OR ClosedDate = LAST_N_DAYS:' + retentionDays + ') AND IsVisibleInSelfService = true AND ProductImpacted__c IN (' + productString + ') AND PlatformsImpacted__c includes (' + nodeString + ') AND ID NOT IN(SELECT Event__c FROM EventAccount__c WHERE Account__r.CadebillAccountNo__c = ' + account_no + ' AND Excluded__c = true) AND RecordType.Name = \'Known Issue\' ' + searchFilter;
            system.debug(queryString);
            knownIssueCases = Database.Query(queryString);
        }
        
        queryString = 'SELECT Id, LatestPublicUpdate__c, PlatformsReleased__c, CaseNumber, CreatedDate, ClosedDate, Subject, Summary__c, Steps_to_Recreate__c, Workaround__c, Status, LastModifiedDate, ProductImpacted__c, PlatformsImpacted__c, Release__c, (SELECT CaseNumber FROM KnownIssues__r) FROM Case WHERE (IsClosed = false OR ClosedDate = LAST_N_DAYS:' + retentionDays + ') AND IsVisibleInSelfService = true AND ID IN(SELECT Event__c FROM EventAccount__c WHERE Account__r.CadebillAccountNo__c = ' + account_no + ' and Excluded__c = false) AND  RecordType.Name = \'Known Issue\' ' + searchFilter;       
        knownIssueSpecificCases = Database.Query(queryString);
        
        if(!knownIssueSpecificCases.isEmpty())
        {
            knownIssueCases.addAll(knownIssueSpecificCases);
        }
        /*
        if(!knownIssueCases.isEmpty())
        {
            for(Case e:knownIssueCases)
            {
                if(e.EventStartDateTime__c != null)
                {
                    system.debug(e.Id);
                    KnownIssue ki = new KnownIssue(e.CreatedDate, e.ClosedDate, e.Subject, e.Summary__c, e.Steps_to_Recreate__c, e.Workaround__c, e.Status, e.CaseNumber);
                    knownIssues.add(ki);
                }
            }
        }
        */
        return knownIssueCases;
    }
    
    webservice static ProductNode SelectAllCustomerNodes()
    {
        Set<String> platforms = new Set<String>();
        Set<String> products = new Set<String>();
        String[] nodes = new String[]{};
        String[] productList = new String[]{};
        Map<String,ProductEventMap__c> nodeMap = ProductEventMap__c.getAll();
        
        for(ProductEventMap__c pem:nodeMap.values())
        {
            if(pem.AllCustomers__c)
            {
                products.add(pem.Product__c);
                platforms.add(pem.Platform__c);
            }
        }
        
        nodes.addAll(platforms);
        productList.addAll(products);
        ProductNode pn = new ProductNode(productList, nodes);
        return pn;
    }
    

    webservice static ProductNode SelectTrustNodeByCustomer(integer account_no)
    {
        Set<String> platforms = new Set<String>();
        Set<String> products = new Set<String>();
        Map<String,Set<String>> resellCustomerClusters = new Map<String,Set<String>>();
        Map<String,ProductEventMap__c> nodeMap = ProductEventMap__c.getAll();
        ImplementedProduct__c[] implementedProducts = new ImplementedProduct__c[]{};
        Account customer = new Account();
        
        //ProductPlatformMap__c nodeMap = new ProductPlatformMap__c();
        String node;
        String[] nodes = new String[]{};
        String[] productList = new String[]{};
        
        if([SELECT COUNT() FROM Account WHERE CadebillAccountNo__c = :account_no] > 0)
        {
            customer = [SELECT ID, inContact_Cluster__c, Verint_Cluster__c, NICE_WFM_Cluster__c, NICE_QM_Cluster__c, RecordType.Name FROM Account WHERE CadebillAccountNo__c = :account_no LIMIT 1];
        }
        else 
        {
            return new ProductNode();
        }
        
        if(customer.RecordType.Name == 'Resell Partner')
        {
            if([SELECT COUNT() FROM Account WHERE ParentId = :customer.Id] > 0)
            {
                Map<Id, Account> childAccounts = new Map<Id,Account>([SELECT Id, inContact_Cluster__c, Verint_Cluster__c, NICE_QM_Cluster__c, NICE_WFM_Cluster__c, RecordType.Name FROM Account WHERE ParentId = :customer.Id]);
                childAccounts.put(customer.Id,customer);
                implementedProducts = [SELECT Product__c FROM ImplementedProduct__c WHERE Account__c IN :childAccounts.keySet() AND GoLiveDate__c != NULL];
                system.debug('implementedProducts => ' + implementedProducts);
                for(Account resellAccount:childAccounts.values())
                {
                    resellCustomerClusters = ResellCustomerClusterMap(resellCustomerClusters, resellAccount.inContact_Cluster__c, 'inContact');
                    resellCustomerClusters = ResellCustomerClusterMap(resellCustomerClusters, resellAccount.Verint_Cluster__c, 'Verint');
                    resellCustomerClusters = ResellCustomerClusterMap(resellCustomerClusters, resellAccount.NICE_WFM_Cluster__c, 'NWFM');
                    resellCustomerClusters = ResellCustomerClusterMap(resellCustomerClusters, resellAccount.NICE_QM_Cluster__c, 'NQM');
                }
            }
        }
        else
        {
            implementedProducts = [SELECT Product__c FROM ImplementedProduct__c WHERE Account__c = :customer.Id AND GoLiveDate__c != NULL];
        }
        
        if(!implementedProducts.isEmpty())
        {
            for(ImplementedProduct__c i:implementedProducts)
            {
                node = ''; // arnab changes here
                for(ProductEventMap__c pem:nodeMap.values())
                {
                    
                    if(pem.ImplementedProduct__c == i.Product__c && !pem.DoNotPost__c)
                    {
                       
                        if(pem.HasClusters__c && customer.RecordType.Name != 'Resell Partner')
                        {
                            if(customer.inContact_Cluster__c != NULL && pem.Platform__c.startsWith('Cluster'))
                           	    node = pem.Platform__c.replaceFirst('Cluster', customer.inContact_Cluster__c.trim());
                            if(customer.Verint_Cluster__c != NULL && pem.Platform__c.startsWith('Verint')) // arnab 
                            	node = pem.Platform__c.replaceFirst('Verint', customer.Verint_Cluster__c.trim());
                            if(customer.NICE_WFM_Cluster__c != NULL && pem.Platform__c.startsWith('NWFM')) // arnab 
                            	node = pem.Platform__c.replaceFirst('NWFM', customer.NICE_WFM_Cluster__c.trim());
                            if(customer.NICE_QM_Cluster__c != NULL && pem.Platform__c.startsWith('NQM')) // arnab 
                            	node = pem.Platform__c.replaceFirst('NQM', customer.NICE_QM_Cluster__c.trim());
                            
                        }
                        else if(pem.HasClusters__c && customer.RecordType.Name == 'Resell Partner' && !resellCustomerClusters.isEmpty())
                        {
                            
                            //system.debug('platform => ' + pem.Platform__c);
                            //system.debug('product => ' + pem.Product__c);
                            //loop through resell customer notes
                            //if(pem.Platform__c.startsWith('Cluster'))
                            if(pem.Platform__c.startsWith('Cluster') && resellCustomerClusters.containsKey('inContact'))
                            {
                                for(string resellCluster:resellCustomerClusters.get('inContact'))
                                {
                                    platforms.add(pem.Platform__c.replace('Cluster',resellCluster));
                                }
                            } else if(pem.Platform__c.startsWith('Verint') && resellCustomerClusters.containsKey('Verint'))
                            {
                                
                                for(string resellCluster:resellCustomerClusters.get('Verint'))
                                {
                                    platforms.add(pem.Platform__c.replace('Verint',resellCluster));
                                }
                            }else if(pem.Platform__c.startsWith('NWFM') && resellCustomerClusters.containsKey('NWFM'))
                            {
                                
                                for(string resellCluster:resellCustomerClusters.get('NWFM'))
                                {
                                    platforms.add(pem.Platform__c.replace('NWFM',resellCluster));
                                }
                            }else if(pem.Platform__c.startsWith('NQM') && resellCustomerClusters.containsKey('NQM'))
                            {
                                
                                for(string resellCluster:resellCustomerClusters.get('NQM'))
                                {
                                    platforms.add(pem.Platform__c.replace('NQM',resellCluster));
                                }
                            }
                        }
                        else
                        {
                            node = pem.Platform__c;
                        }
                        
                       // system.debug('platforms == > ' + platforms);
                        products.add(pem.Product__c);
                        //system.debug(pem.ImplementedProduct__c + ' --- ' + i.Product__c);
                        //system.debug(pem.Product__c);
                    }
                    //system.debug(pem.ImplementedProduct__c + ' --- ' + i.Product__c);
                      
                }
                
              if(node != null)
                {
                    platforms.add(node);
                }
            }
        }
        
        nodes.addAll(platforms);
        productList.addAll(products);
        ProductNode pn = new ProductNode(productList, nodes);
        return pn;
        
    }
    
    webservice static TrustNode[] SelectEventsByNodesAndDaysBack(ProductNode prodNodes, integer daysBack, integer account_no)
    {
        Case[] events = new Case[]{};
        Case[] eventSpecific = new Case[]{};
        TrustNode[] trustNodes = new TrustNode[]{};
        String nodeString = '';
        String productString = '';
        String queryString;
        String[] nodes = new String[]{};
        
        nodes = prodNodes.nodes;
        
        if(nodes != null)
        {
            nodeString = QueryFilterParse(nodes);
        }
        
        if(prodNodes.products != null)
        {
            productString = QueryFilterParse(prodNodes.products);
        }
        
        system.debug('nodeString => ' + nodeString);
        system.debug('productString => ' + productString);
        
        if(productString != '' && nodeString != '')
        {
            
            queryString = 'SELECT Id, Subject, EventStartDateTime__c, EventEndDateTime__c, EventType__c, PlatformsImpacted__c FROM Case WHERE NonEvent__c = false AND InternalEvent__c = false AND ProductImpacted__c IN (' + productString + ') AND PlatformsImpacted__c includes (' + nodeString + ') AND (EventStartDateTime__c >= LAST_N_DAYS:' + string.valueOf(daysBack) + ' OR EventEndDateTime__c >= LAST_N_DAYS:' + string.valueOf(daysBack) + ' OR EventEndDateTime__c = NULL) AND ID NOT IN(SELECT Event__c FROM EventAccount__c WHERE Account__r.CadebillAccountNo__c = ' + account_no + ' AND Excluded__c = true) AND RecordType.Name = \'Event\'';
            system.debug(queryString);
            events = Database.Query(queryString);
        }
        
        queryString = 'SELECT Id, Subject, EventStartDateTime__c, EventEndDateTime__c, EventType__c, PlatformsImpacted__c FROM Case WHERE ID IN(SELECT Event__c FROM EventAccount__c WHERE Account__r.CadebillAccountNo__c = ' + account_no + ' AND Excluded__c = false) AND NonEvent__c = false AND InternalEvent__c = false AND (EventStartDateTime__c >= LAST_N_DAYS:' + string.valueOf(daysBack) + ' OR EventEndDateTime__c >= LAST_N_DAYS:' + string.valueOf(daysBack) + ' OR EventEndDateTime__c = NULL) AND RecordType.Name = \'Event\'';        
        eventSpecific = Database.Query(queryString);
        
        if(!eventSpecific.isEmpty())
        {
            events.addAll(eventSpecific);
        }
        
        if(!events.isEmpty())
        {
            for(Case e:events)
            {
                if(e.EventStartDateTime__c != null)
                {
                    system.debug(e.Id);
                    TrustNode tn = new TrustNode(e.EventStartDateTime__c,e.EventEndDateTime__c, e.Id, e.PlatformsImpacted__c,e.EventType__c);
                    trustNodes.add(tn);
                }
            }
        }
        
        return trustNodes;
        
    }
    
    webservice static EventNodeList SelectEventsByNodeAndDate(string node, date eventDate)
    {
        EventNodeList enl = new EventNodeList(node, eventDate);
        date datePlusOne = eventDate + 1;
        List<RCA__c> rcas = new List<RCA__c>();
        List<CaseComment> comments = new List<CaseComment>();
        Map<Id,Case> cases = new Map<Id,Case>([SELECT Id, CaseNumber, Subject, EventStartDateTime__c, EventEndDateTime__c, EventType__c, Status, Description, CustomersMayExperienceTheFollowing__c, CustomerAction__c, Priority FROM Case WHERE NonEvent__c = false AND InternalEvent__c = false AND RecordType.Name = 'Event' AND PlatformsImpacted__c INCLUDES (:node) AND ((EventStartDateTime__c >= :eventDate AND EventStartDateTime__c < :datePlusOne) OR (EventEndDateTime__c >= :eventDate AND EventEndDateTime__c < :datePlusOne) OR (EventStartDateTime__c <= :eventDate AND EventEndDateTime__c >= :eventDate) OR (EventStartDateTime__c <= :eventDate AND EventEndDateTime__c = NULL))]);
        
        enl.events = cases.values();
        rcas = [SELECT ID, Event__c, Event__r.EventStartDateTime__c, Event__r.EventEndDateTime__c, r.RootCause__c, r.Resolution__c, r.RFECreator__r.Name, r.DescriptionOfIssue__c, r.CorrectiveActions__c, r.ContributingFactors__c From RCA__c r WHERE RFEPublished__c = true AND Event__c IN :cases.keySet()];
        comments = [SELECT ParentId, CreatedDate, CommentBody FROM CaseComment WHERE IsPublished = true AND ParentId IN :cases.keySet() ];
        
        enl.eventLogs = comments;
        enl.rFEs = rcas;        
        return enl;
    }
    
    webservice static TrustNode[] SelectIntelligentNetworkEvents(integer daysBack)
    {
        Case[] events = new Case[]{};
        TrustNode[] trustNodes = new TrustNode[]{};
        Map<String,ProductEventMap__c> nodeMap = ProductEventMap__c.getAll();
        
        
        String products = '';
        String queryString;
        
        for(ProductEventMap__c pem:nodeMap.values())
        {
            if(pem.AllCustomers__c)
            {
                if(products == '')
                {
                    products = '\'' + pem.Product__c + '\'';
                }
                else
                {
                    products = products + ',' + '\'' + pem.Product__c + '\'';
                }
            }
        }
        
        queryString = 'SELECT Id, Subject, EventStartDateTime__c, EventEndDateTime__c, EventType__c, PlatformsImpacted__c FROM Case WHERE NonEvent__c = false AND InternalEvent__c = false AND ProductImpacted__c IN (' + products + ') AND (EventStartDateTime__c >= LAST_N_DAYS:' + string.valueOf(daysBack) + ' OR EventEndDateTime__c >= LAST_N_DAYS:' + string.valueOf(daysBack) + ' OR EventEndDateTime__c = NULL) AND RecordType.Name = \'Event\'';
        system.debug(queryString);
        events = Database.Query(queryString);
        
        if(!events.isEmpty())
        {
            for(Case e:events)
            {
                TrustNode tn = new TrustNode(e.EventStartDateTime__c,e.EventEndDateTime__c, e.Id, e.PlatformsImpacted__c,e.EventType__c);
                trustNodes.add(tn);
            }
        }
        
        return trustNodes;
    }
    
    
    
   // New added method - Arnab
     webservice static List<Event_Platform_Definition__c>  getPlatformDefinitions (Integer account_no){
		
		ProductNode pn = inContactTrustWebService.SelectTrustNodeByCustomer(account_no);
        Map<String,Event_Platform_Definition__c> definitionsMap = Event_Platform_Definition__c.getAll();
        List<Event_Platform_Definition__c> lstPlatformDef = new List<Event_Platform_Definition__c>();
 
         if(pn.nodes != null && pn.nodes.size() > 0)
         {
                        for (string platformName : pn.nodes) // loop though all the platforms
            {
                for (Event_Platform_Definition__c epd : definitionsMap.values()) // Go through the custom settings
                {
                    if (platformName.contains(epd.Name)) // check to see if the platform name matches the name, filter only those records
                    {
                        // add to the list
                        lstPlatformDef.add(epd);
                    }
                    else if(epd.Name == 'Intelligent Network')
                        lstPlatformDef.add(epd);
    
                }
            }
                
         }
         else {
             lstPlatformDef.add(definitionsMap.get('Intelligent Network'));
         }
       return lstPlatformDef;
	   }
    
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
 
    private static string QueryFilterParse(List<String> stringArray)
    {
        string returnString = '';
        
        for(String s:stringArray)
        {
            if(s!=null)
            {
                if(returnString == '')
                {
                    returnString = '\'' + s + '\'';
                }
                else
                {
                    returnString = returnString + ',' + '\'' + s + '\'';
                }
            }
        }
        
        return returnString;
    }
    
    global class CustomerNodeEvents
    {
        webservice String[] customerNodes;
        webservice TrustNode[] trustNodes;
        
        public CustomerNodeEvents(String[] nodes, TrustNode[] tNodes)
        {
            customerNodes = nodes;
            trustNodes = tNodes;
        }
        
        public CustomerNodeEvents()
        {
            
        }
    }
    

    global class TrustNode
    {
        webservice datetime eventStartDate;
        webservice datetime eventEndDate;
        webservice string caseId;
        webservice string nodes;
        webservice string eventType;
        
        public TrustNode(datetime startDate,datetime endDate,string cId, string nodeString, string eType)
        {
            eventStartDate = startDate;
            eventEndDate = endDate;
            caseId = cId;
            nodes = nodeString;
            eventType = eType;
        }
        
        public TrustNode()
        {
            
        }
    }
    
    global class EventNodeList
    {
        webservice date eventDate;
        webservice string node;
        webservice Case[] events;
        webservice CaseComment[] eventLogs;
        webservice RCA__c[] rFEs;
        
        public EventNodeList(string trustNode, date eDate)
        {
            eventDate = eDate;
            node = trustNode;
        }
        
        public EventNodeList()
        {
            
        }
    }
    
global class ProductNode
    {
        webservice String[] products;
        webservice String[] nodes;
        
        public ProductNode(String[] productList, String[] nodeList)
        {
            products = productList;
            nodes = nodeList;
        }
        
        public ProductNode()
        {
            
        }
    }
    
    global class MaintenanceNotification
    {
        webservice datetime startDate;
        webservice datetime endDate;
        webservice string subject;
        webservice string description;
        webservice string eventType;
        webservice string carrier;
        webservice string platform;
        webservice string caseNumber;
        webservice string productImpacted;
        
        public MaintenanceNotification(datetime startDateCon, datetime endDateCon, string subjectCon, string descriptionCon, string eventTypeCon, string carrierCon, string platformCon, string cNumber, string eventProductImpacted)
        {
            startDate = startDateCon;
            endDate = endDateCon;
            subject = subjectCon;
            description = descriptionCon;
            eventType = eventTypeCon;
            carrier = carrierCon;
            platform = platformCon;
            caseNumber = cNumber;
            productImpacted = eventProductImpacted;
        }
    }
    
    global class KnownIssue
    {
        webservice datetime createdDate;
        webservice datetime closedDate;
        webservice string subject;
        webservice string summary;
        webservice string recreateSteps;
        webservice string workAround;
        webservice string status;
        webservice string caseNumber;
        
        public KnownIssue(datetime createdDateCon, datetime closedDateCon, string subjectCon, string summaryCon, string recreateStepsCon, string workAroundCon, string statusCon, string cNumber)
        {
            createdDate = createdDateCon;
            closedDate = closedDateCon;
            subject = subjectCon;
            summary = summaryCon;
            recreateSteps = recreateStepsCon;
            workAround = workAroundCon;
            status = statusCon;
            caseNumber = cNumber;
        }
        
    }
}