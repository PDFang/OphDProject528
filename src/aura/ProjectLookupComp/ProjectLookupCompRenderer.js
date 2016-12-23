/**
 * Created by arnab.karsarkar on 12/16/2016.
 */

({
    /*
     * When the v.value field changes its value, the lookup is loaded again
     */
    rerender : function(component, helper){
        this.superRerender();
        //console.log(helper.typeaheadOldValue[component.getGlobalId()], component.get('v.value'));
		//if value changes, triggers the loading method
        if(helper.typeaheadOldValue[component.getGlobalId()] !== component.get('v.value')){
            helper.loadValue(component,true);
        }
    }
})