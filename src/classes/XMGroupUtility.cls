/**
 * Created by william.nelson on 5/26/2017.
 */

public with sharing  class XMGroupUtility {


    public string GetGroupName(string partnerPrefix, string product, string cluster){

        string XmattersGroupName;
        if (cluster == null || cluster == ''){
            //default cluster description
            cluster = 'NONE';
        }
        if (partnerPrefix == null || partnerPrefix == '')
        {
            //default partner designation
            partnerPrefix = 'INC';
        }
        XmattersGroupName = 'IP_'+ partnerPrefix + '_' + product + '_'  + cluster;
        return XmattersGroupName;
    }
}