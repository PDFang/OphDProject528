({
    searchEventFire: function(component, event, helper) {
/*        
        var inputText = component.find("thisText").get("v.value");
        var myEvent = $A.get("e.c:SearchEventHandler");		
        
        myEvent.setParams({"searchKey": inputText});
        myEvent.fire();
*/
console.log('fisrt event fired');

        var inputText = component.find("thisText").get("v.value");
        component.find("thisText").set("v.value", "");
        console.log('inputText - '+encodeURIComponent(inputText));
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": "/SearchResult?searchText="+encodeURIComponent(inputText)
            
        });
        urlEvent.fire();
    },
    
    gotoURL : function (component, event, helper) {
        var inputText = component.find("thisText").get("v.value");
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": "/canvastest?key="+inputText
            
        });
        urlEvent.fire();
	}
})