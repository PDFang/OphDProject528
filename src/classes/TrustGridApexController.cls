public without sharing class TrustGridApexController {

    public static List<TrustGridRow> initTrustGrid(Integer cadebillAccountNo){

        List<TrustGridRow> trustGridList = new List<TrustGridRow>();
        TrustGridHelper helper = new TrustGridHelper(cadebillAccountNo);
        Set<String> platformSet = helper.getPlatforms();
        system.debug(' initTrustGrid - ' + eventList);

        for(String platform : platformSet){
            TrustGridRow row = new TrustGridRow(platform);
            trustGridList.add(row);
        }

        Map<String, List<Case>> eventList = TrustGridHelper.getEvents(cadebillAccountNo, platformSet);
        system.debug(' eventList - ' + eventList);
        return trustGridList;
    }
}