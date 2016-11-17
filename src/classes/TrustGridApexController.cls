public without sharing class TrustGridApexController {

    static final Integer DAYS_BACK = 7;
    private static TrustGridHelper helper;

    @AuraEnabled
    public Account getCustomer(){
        return helper != null ? helper.customer : null;
    }


    @AuraEnabled
    public static List<TrustGridRow> initTrustGrid(Integer cadebillAccountNo, Integer daysBack){

        if(daysBack == null){
            daysBack = DAYS_BACK;
        }

        List<TrustGridRow> trustGridList = new List<TrustGridRow>();
        Map<String, TrustGridRow> trustGridMap = new Map<String, TrustGridRow>();

        try {
            helper = new TrustGridHelper(cadebillAccountNo);
            Set<String> platformSet = helper.getPlatforms();
            system.debug(' initTrustGrid - ' + platformSet);
            if(platformSet.isEmpty()){
                return trustGridList;
            }

            for (String platform : platformSet) {
                TrustGridRow row = new TrustGridRow(platform);
                trustGridMap.put(platform, row);
                for (Integer i = 0; i < DAYS_BACK; i++) {
                    TrustGridRow.TrustGridCell cell = new TrustGridRow.TrustGridCell(system.now().dateGMT().addDays(-i));
                    row.cellList.add(cell);
                }
                trustGridList.add(row);
            }
            system.debug(' trustGridMap - ' + trustGridMap);

            List<Case> eventList = helper.getEvents(system.today(), DAYS_BACK);
            system.debug(' eventList - ' + eventList);

            for (Case c : eventList) {
                List<String> platformList = c.PlatformsImpacted__c.split(';');
                String eventStartDate = c.EventStartDateTime__c.formatGMT('MMM d');
                system.debug('Time check' + c.EventStartDateTime__c + ' ' + eventStartDate + ' ' + datetime.now());
                for (String platform : platformList) {
                    if (!trustGridMap.containsKey(platform)) {
                        system.debug('Not found '+ platform);
                        continue;
                    }
                    TrustGridRow row = trustGridMap.get(platform);
                    if(c.EventStartDateTime__c != null && c.EventStartDateTime__c < datetime.now() && ( c.EventEndDateTime__c == null || c.EventEndDateTime__c > datetime.now()) ){
                        row.currentStatus = c.EventType__c;
                    }
                    system.debug(' *** ' + platform + ' - ' + row);
                    for (TrustGridRow.TrustGridCell cell : row.cellList) {
                        if (cell.dateString == eventStartDate || (c.EventStartDateTime__c < cell.today && c.EventEndDateTime__c >= cell.today)
                                || (c.EventStartDateTime__c < cell.today && c.EventEndDateTime__c == null)) {
                            //TrustGridRow.EventInfo newEvent = new TrustGridRow.EventInfo(c);
                            //cell.eventList.add(newEvent);
                            cell.addEvent(c);
                        }
                    }
                }
            }
        } catch(Exception ex){
            system.debug('**** DEBUG initTrustGrid(): ex - ' + ex);
            throw new TrustGridException(ex.getMessage());
        }

        system.debug(' trustGridList - ' + trustGridList);
        return trustGridList;

    } // end of initTrustGrid()
}