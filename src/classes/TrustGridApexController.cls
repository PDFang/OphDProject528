/**
 * Created by mohandaas.rangaswamy on 11/9/2016.
 */

public without sharing class TrustGridApexController {

    public static List<TrustGridRow> initTrustGrid(Integer cadebillAccountNo){

        List<TrustGridRow> trustGridList = new List<TrustGridRow>();
        Set<String> platformSet = TrustGridHelper.getPlatformsByCustomer(cadebillAccountNo);
        for(String platform : platformSet){
            TrustGridRow row = new TrustGridRow(platform);
            trustGridList.add(row);
        }

        return trustGridList;
    }
}