/**
 * Created by ravish.chawla on 6/9/2017.
 */

public class ReferenceProfileTriggerHandler extends TriggerHandler
{
    public override void afterInsert(){
        updateReferencable((list<refedge__Reference_Basic_Information__c>)trigger.new, new list<refedge__Reference_Basic_Information__c>());
    }

    public override void afterUpdate(){
        updateReferencable((list<refedge__Reference_Basic_Information__c>)trigger.new, (list<refedge__Reference_Basic_Information__c>)trigger.old);

    }



    private static void updateReferencable(list<refedge__Reference_Basic_Information__c> newReferenceProfileList, list<refedge__Reference_Basic_Information__c> oldReferenceProfileList)
    {
        Set<Id> acctAddRef = new Set<Id>();
        Set<Id> acctRemoveRef = new Set<Id>();

        if(oldReferenceProfileList.size() == 0)
        {
            //loop through contacts
            for(refedge__Reference_Basic_Information__c c:newReferenceProfileList)
            {
                //get referenceable contacts
                if(c.refedge__Is_Referenceable__c && c.refedge__Referenceability_Status__c == 'Active' )
                {
                    if(!acctAddRef.contains(c.refedge__Account__c))
                    {
                        acctAddRef.add(c.refedge__Account__c);
                    }
                }
            }
        }
        else
        {
            //loop through triggers
            for(integer i=0; i < newReferenceProfileList.size(); i++)
            {
                //get new and old contact record
                refedge__Reference_Basic_Information__c refProfNew = newReferenceProfileList[i];
                refedge__Reference_Basic_Information__c refProfOld = oldReferenceProfileList[i];

                //get newly referenceable contacts
                if((!refProfOld.refedge__Is_Referenceable__c  && refProfOld.refedge__Referenceability_Status__c != 'Active') &&
                        (refProfNew.refedge__Is_Referenceable__c && refProfNew.refedge__Referenceability_Status__c == 'Active'))
                {
                    if(!acctAddRef.contains(refProfNew.refedge__Account__c))
                    {
                        acctAddRef.add(refProfNew.refedge__Account__c);
                    }
                }
                else if((refProfOld.refedge__Is_Referenceable__c  && refProfOld.refedge__Referenceability_Status__c != 'Active') &&
                        (refProfNew.refedge__Is_Referenceable__c && refProfNew.refedge__Referenceability_Status__c == 'Active'))
                {
                    if(!acctAddRef.contains(refProfNew.refedge__Account__c))
                    {
                        acctAddRef.add(refProfNew.refedge__Account__c);
                    }
                }
                else if((refProfOld.refedge__Is_Referenceable__c && refProfOld.refedge__Referenceability_Status__c == 'Active')
                        && (!refProfNew.refedge__Is_Referenceable__c && refProfNew.refedge__Referenceability_Status__c != 'Active'))
                {
                    if(!acctRemoveRef.contains(refProfNew.refedge__Account__c))
                    {
                        acctRemoveRef.add(refProfNew.refedge__Account__c);
                    }
                }
                else if((refProfOld.refedge__Is_Referenceable__c && refProfOld.refedge__Referenceability_Status__c == 'Active')
                        && (refProfNew.refedge__Is_Referenceable__c && refProfNew.refedge__Referenceability_Status__c != 'Active'))
                {
                    if(!acctRemoveRef.contains(refProfNew.refedge__Account__c))
                    {
                        acctRemoveRef.add(refProfNew.refedge__Account__c);
                    }
                }

            }
        }

        if(acctAddRef.size() > 0)
            addAccountRef(acctAddRef);

        if(acctRemoveRef.size() > 0)
            removeAccountRef(acctRemoveRef);
    }

    private static void addAccountRef(set<id> acctAddRef)
    {
        //get accounts that need referenced
        Account[] accts = [SELECT Id, Referenceable__c FROM Account WHERE Id IN :acctAddRef AND Referenceable__c = false];

        //make sure accounts are returned
        if(accts.size()>0)
        {
            //loop through accounts and mark them as referenceable
            for(Account a:accts)
            {
                a.Referenceable__c = true;
            }

            //update accounts
            update accts;
        }
    }

    private static void removeAccountRef(set<id> acctRemoveRef)
    {
        //get accounts that need referenced
        Account[] accts = [SELECT Id, Referenceable__c, (select Id from refedge__Reference_Basic_Informations__r where refedge__Is_Referenceable__c = true AND refedge__Referenceability_Status__c = 'Active')
        FROM Account WHERE Id IN :acctRemoveRef];

        //make sure accounts are returned
        if(accts.size()>0)
        {
            //loop through accounts and mark them as referenceable
            for(Account a:accts)
            {
                if(a.refedge__Reference_Basic_Informations__r.size() <= 0)
                {
                    a.Referenceable__c = false;
                }
            }

            //update accounts
            update accts;
        }
    }

}