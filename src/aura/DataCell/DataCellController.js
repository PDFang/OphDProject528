/**
 * Created by arnab.karsarkar on 12/21/2016.
 */
({
	handleClick : function(component, event, helper) {
		var click = component.getEvent("dateCellClick");
    console.log('Datecell controller click' + click);
    click.fire();
	}
})