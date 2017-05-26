/**
 * Created by william.nelson on 5/26/2017.
 */
@isTest
public with sharing class XMGroupUtilityTest {

    static testMethod void CreateGroupTest(){
        XMGroupUtility xmUtility = new XMGroupUtility();
        xmUtility.GetGroupName('', 'IMAPRODUCT','');
    }
}