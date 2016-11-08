/**
 * Created by arnab.karsarkar on 11/8/2016.
 */

public with sharing class TrustGridController {

    @AuraEnabled
    public static map<string, map<string, list<string>> getPlatformInfo()
    {
        map<string, map<string, list<string>> mpPlatforms = new  map<string, map<string, list<string>>();
        map<string, list<string> mpDateEvents = new map<string, list<string>();
        list<string> lstplatforms = new list<string>();
        lstplatforms.add('C8 - Dialer');
        lstplatforms.add('C8 - inContact');
        lstplatforms.add('Intelligent Network');

        for(string pl : lstplatforms)
        {
            if(pl == 'C8 - Dialer')
            {
                mpDateEvents.put('Nov5', new list<string>{'M-2'});
            }
            if(pl == 'C8 - inContact')
            {
                mpDateEvents.put('Nov4', new list<string>{'D-1'});
            }
            if(pl == 'Intelligent Network')
            {
                mpDateEvents.put('Nov2', new list<string>{'SI-1'});
            }
            mpPlatforms.put(pl, mpDateEvents);

        }


        return mpDateEvents
    }

}