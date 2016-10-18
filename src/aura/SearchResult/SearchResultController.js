({
	doInit : function(component) {
		console.log(window.location.href);
        var params = {};
        window.location.href.replace( location.hash, '' ).replace( 
            /[?&]+([^=&]+)=?([^&]*)?/gi, // regexp
            function( m, key, value ) { // callback
                params[key] = value !== undefined ? value : '';
            }
        );
    	var searchText = params['searchText'] ? params['searchText'] : '';	
		console.log(searchText);
        searchText = decodeURIComponent(searchText);
        console.log('search text after decode == >' + searchText);
        component.set("v.searchText", searchText);
		
		var action = component.get("c.findCases");
        action.setParams({
            "key": searchText
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS'){
                component.set("v.cases", response.getReturnValue());                    
            }
        });
        $A.enqueueAction(action);        
	},
    
    search : function(component, event, helper) {
        var inputText = event.getParam("searchKey");
        console.log("inputText ==>" + inputText); 
        var action = component.get("c.findCases");
        action.setParams({
            "key": inputText
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS'){
                component.set("v.cases", response.getReturnValue());                    
            }
        });
        $A.enqueueAction(action);
        
    }
})