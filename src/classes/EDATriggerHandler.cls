/**
 * Created by arnab.karsarkar on 9/14/2017.
 */

public class EDATriggerHandler extends TriggerHandler  {

	protected override void afterInsert(){
		callOrderSubmitDetermination((list<EDA__c>) Trigger.new);
	}


	private void callOrderSubmitDetermination(list<EDA__c> edaInsertList){
		set<id> edaIds = new set<Id>();
		for(EDA__c eda : edaInsertList){
			if(!eda.AutoSubmit__c){
				edaIds.add(eda.Id);
			}
		}

		if(edaIds.size() > 0){
			LMAHelperClass.orderSubmitDetermination(edaIds);
		}

	}
}