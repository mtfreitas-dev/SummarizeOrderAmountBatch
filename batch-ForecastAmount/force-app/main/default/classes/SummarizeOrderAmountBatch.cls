public with sharing class SummarizeOrderAmountBatch implements Database.Batchable<sObject>{


     //Retorna uma lista de objeto "Order" cujo o campo status possuam o valor "Closed"
    public Database.QueryLocator start(Database.BatchableContext context){
       
        String query = 'SELECT Id FROM Order WHERE Status = \'Closed\'';
        return Database.getQueryLocator(query);
    }


   public void execute(Database.BatchableContext context, List<Order> scope){

          //Utiliza sumaricação de dados para armezar o valor total de faturamento por conta
         List<AggregateResult> aggregateResultByAccountList = [
              SELECT AccountId, SUM(TotalAmount) TotalAmount
              FROM Order
              WHERE Id IN:scope
              GROUP BY AccountId
         ];

         //Utiliza sumaricação de dados para armezar o valor total de faturamento por conta e produto
         List<AggregateResult> aggregateResultByAccountProductList = [
              SELECT Order.AccountId, Product2Id, SUM(TotalPrice) TotalAmount
              FROM OrderItem
              WHERE OrderId IN (SELECT Id FROM Order WHERE Id IN:scope)
              GROUP BY Order.AccountId, Product2Id
         ];


         //Cria uma lista do objeto personalizado utilizado para armazenar os valores de previsões de vendas
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