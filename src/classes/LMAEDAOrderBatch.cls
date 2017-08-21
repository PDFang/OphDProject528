/**
 * Created by william.nelson on 8/21/2017.
 */

global class LMAEDAOrderBatch implements Database.Batchable<Sobject>, Database.Stateful, Database.AllowsCallouts  {

    public string queryString;
    //public List<> groupChangeRequestList;

    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        //get list of llcenses and service orders look for reduction
        //Get total pre-eda licenses
        //based on EDA license count determine if COA reduction order is neede

        //calculation example
        //[Add ons + Initials]    +       [(Cancel +Reductions) – (Initial + Add-on)] < 7575

        //Cancel +Reductions) + (Initial + Add on)] > 7575

        //build pending transactions

        queryString = '';
        System.debug('queryString =>' + queryString);
        return null;

    }

    global void execute(Database.BatchableContext BC, List<Account> scope)
    {


    }

    global void finish(Database.BatchableContext BC)
    {

    }


}