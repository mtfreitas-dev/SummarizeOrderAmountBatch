public with sharing class SummarizeOrderAmountBatch implements Database.Batchable<sObject>{


    public Database.QueryLocator start(Database.BatchableContext context){
       
        String query = 'SELECT Id FROM Order WHERE Status = \'Closed\'';
        return Database.getQueryLocator(query);
    }

   public void execute(Database.BatchableContext context, List<Order> scope){

         List<AggregateResult> aggregateResultByAccountList = [
              SELECT AccountId, SUM(TotalAmount) TotalAmount
              FROM Order
              WHERE Id IN:scope
              GROUP BY AccountId
         ];

         List<AggregateResult> aggregateResultByAccountProductList = [
              SELECT Order.AccountId, Product2Id, SUM(TotalPrice) TotalAmount
              FROM OrderItem
              WHERE OrderId IN (SELECT Id FROM Order WHERE Id IN:scope)
              GROUP BY Order.AccountId, Product2Id
         ];

         List<ForecastSummary__c> forecastSummaryList = new List<ForecastSummary__c>();

         for(AggregateResult accountResult : aggregateResultByAccountList){
              Decimal totalAmount = (Decimal)accountResult.get('TotalAmount');
  
              forecastSummaryList.add(new ForecastSummary__c(
                  Key__c = (Id)accountResult.get('AccountId'),
                  RealizedValue__c = totalAmount
              ));
         }

         for(AggregateResult accountProductResult : aggregateResultByAccountProductList){
              forecastSummaryList.add(new ForecastSummary__c(
                  Key__c = (String)accountProductResult.get('AccountId') + '' + (String)accountProductResult.get('Product2Id'),
                  RealizedValue__c = (Decimal)accountProductResult.get('TotalAmount')
              ));
         
         }

         upsert forecastSummaryList Key__c;

   }

   public void finish(Database.BatchableContext info){ } 

}