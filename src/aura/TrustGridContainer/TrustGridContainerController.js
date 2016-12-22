/**
 * Created by mohandaas.rangaswamy on 12/19/2016.
 */
({
    clickTab : function(component, event, helper){
        var currentTab = document.getElementsByClassName("slds-active")[0];
        $A.util.removeClass(currentTab, "slds-active");
        var selectedTab = event.currentTarget.parentElement;
        $A.util.toggleClass(selectedTab, "slds-active");
        var tabContentArray = document.getElementsByClassName("slds-tabs--scoped__content");
        for(i=0; i < tabContentArray.length; i++){
            var tabContent = tabContentArray[i];
            if(tabContent.id == event.currentTarget.getAttribute("aria-controls")
            || tabContent.id == currentTab.firstChild.getAttribute("aria-controls")){
                $A.util.toggleClass(tabContent, "slds-show");
                $A.util.toggleClass(tabContent, "slds-hide");
            }
        }
    }
})