public without sharing class TrustGridApexController {

    public static List<TrustGridRow> initTrustGrid(Integer cadebillAccountNo){

        List<TrustGridRow> trustGridList = new List<TrustGridRow>();
        TrustGridHelper helper = new TrustGridHelper(cadebillAccountNo);
        Set<String> platformSet = helper.getPlatforms();
        system.debug(' initTrustGrid - ' + platformSet);

        for(String platform : platformSet){
            TrustGridRow row = new TrustGridRow(platform);
            trustGridList.add(row);
        }

        List<Case> eventList = helper.getEvents(system.today(), 120);
        system.debug(' eventList - ' + eventList);
        return trustGridList;
    }
}