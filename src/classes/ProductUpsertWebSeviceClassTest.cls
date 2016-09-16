@istest
public class ProductUpsertWebSeviceClassTest {

   Private static  testmethod void testUpsert()
   {
		List<ProductUpsertWebSeviceClass.ProductFields> lstProducts = new List<ProductUpsertWebSeviceClass.ProductFields>();
		list<PriceBook2> lstPriceBooks = new list<PriceBook2>();
     	PriceBook2 newPB2 = new PriceBook2();  
        newPB2.IsActive = true;  
		newPB2.Name = 'Standard PriceBook';		
        lstPriceBooks.add(newPB2);

       
        PriceBook2 newPB1 = new PriceBook2();  
        newPB1.IsActive = true;  
		newPB1.Name = 'SaaS-Cadebill';
        lstPriceBooks.add(newPB1);

	
		insert lstPriceBooks;


		for(Integer i = 0; i < 10; i ++ )
		{
			ProductUpsertWebSeviceClass.ProductFields prod = new ProductUpsertWebSeviceClass.ProductFields();
			prod.ProdId = null;
			prod.CadebillFeatureDetailID = 1233456 + i;
			prod.CadebillFeatureKey = 123456789 + i;
			prod.CadebillProductID = 'P123456' + i;
			prod.Description = 'test description' + i;
			prod.isActive = true;
			prod.Name = 'Test Name' + i;
			prod.ProductCode = 'P123456' + i;
			prod.UnitPrice = 12.00;
			prod.CountryCode =  'US';			
			lstProducts.add(prod);
		}
		ProductUpsertWebSeviceClass.UpsertProduct(lstProducts);

		List<product2> lstProds = new List<Product2>([select Id, Name,ListPrice__c from Product2]);
		System.assertEquals(lstProds.size(), 10);
   }


 }