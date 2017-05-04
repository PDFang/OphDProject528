


public with sharing class XMRestGroupHelper {
  public List <ImplementedProduct__c> getImplementedProducts(Account account ) {
      list <ImplementedProduct__c> implementedProducts = Database.query('SELECT Account__c, Name, Opportunity__c, Product__c,Status__c FROM ImplementedProduct__c where Status__c = \'Implemented\' and Account__c = \'' +  account.Id + '\'');
      return implementedProducts;
  }

  public Account getAccount(Account account){

    Account AccountData =  Database.query ('SELECT inContact_Cluster__c FROM Account where id = \'' + account.Id + '\'');
    return AccountData;
  }
}