public without sharing class TrustGridApexController {

    static final Integer DAYS_BACK = 7;
    public static List<TrustGridRow> initTrustGrid(Integer cadebillAccountNo){

        List<TrustGridRow> trustGridList = new List<TrustGridRow>();
        Map<String, TrustGridRow> trustGridMap = new Map<String, TrustGridRow>();

        TrustGridHelper helper = new TrustGridHelper(cadebillAccountNo);
        Set<String> platformSet = helper.getPlatforms();
        system.debug(' initTrustGrid - ' + platformSet);

        for(String platform : platformSet){
            TrustGridRow row = new TrustGridRow(platform);
            trustGridMap.put( platform, row);
            for(Integer i=0; i < DAYS_BACK; i++){
                TrustGridRow.TrustGridCell cell = new TrustGridRow.TrustGridCell(system.today() - i);
                row.cellList.add(cell);
            }
            trustGridList.add(row);
        }
        system.debug(' trustGridMap - ' + trustGridMap);

        List<Case> eventList = helper.getEvents(system.today(), DAYS_BACK);
        system.debug(' eventList - ' + eventList);

        for(Case c : eventList){
            List<String> platformList = c.PlatformsImpacted__c.split(';');
            String eventStartDate = c.EventStartDateTime__c.format('MMM d');
            for(String platform : platformList){
                if(!trustGridMap.containsKey(platform)){
                    continue;
                }
                TrustGridRow row = trustGridMap.get(platform);
                system.debug(' *** ' + platform + ' - ' + row);
                for(TrustGridRow.TrustGridCell cell : row.cellList){
                    if(cell.dateString == eventStartDate || (c.EventStartDateTime__c < cell.today && c.EventEndDateTime__c >= cell.today)
                        || (c.EventStartDateTime__c < cell.today && c.EventEndDateTime__c == null) ){
                        TrustGridRow.EventInfo newEvent = new TrustGridRow.EventInfo(c);
                        cell.eventList.add(newEvent);
                    }
                }
            }
        }

        system.debug(' trustGridList - ' + trustGridList);
        return trustGridList;
    }
}