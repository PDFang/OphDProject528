trigger UpdateArticleTitle on ServiceSiteArticleSearch__c (before insert, before Update) {

    new ArticleSearchTriggerHandler().run();
     
}