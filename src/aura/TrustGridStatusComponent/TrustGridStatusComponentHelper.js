/**
 * Created by mohandaas.rangaswamy on 11/16/2016.
 */
({
    getPastSevenDates: function(component, helper){
        var monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

        var dateLocal = new Date();
//        debugger;
//        var dateUTCString = $A.localizationService.formatDateTimeUTC(dateLocal);
//        var dateUTC = this.convertToUTC(dateLocal);
//        var parse1 = $A.localizationService.parseDateTime(dateLocal.toISOString());
//        var parse2 = $A.localizationService.parseDateTimeUTC(dateLocal.toISOString());
        var dates  = [];
        var lastDate  = component.get("v.lastDate");
        var d = lastDate == "" ? new Date() : lastDate;
        component.set("v.firstDate", d);
        var pastDt;
        var today = new Date();
        var priorDate =  new Date(today.getFullYear(), today.getMonth(), today.getDate() - 30);

        for(var i = 0; i < 7; i++){
            pastDt = new Date(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate() - i);
            var monthName = monthNames[pastDt.getUTCMonth()];
            var date = monthName + ' ' + pastDt.getUTCDate();
            dates.push(date);
        }

        if(priorDate.getTime() == pastDt.getTime())
        {
         jQuery.noConflict();
         var obj = jQuery('li.next');
         obj.addClass("disabled");
        }
        else if(lastDate != ''){

            jQuery.noConflict();
            var obj = jQuery('li.previous');
            console.log(obj.length);
            obj.removeClass("disabled");
        }
        component.set("v.dates", dates);
        component.set("v.lastDate", pastDt);

        this.loadTrustGrid(component);


    },

    getFutureDates: function(component, helper){
            var monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
            var dates  = [];
            var firstDate  = component.get("v.firstDate");
            var d = new Date(firstDate);
            console.log(d);
             var today = new Date();
             today.setHours(0, 0, 0, 0, 0);
            var pastDt;
            var curDt;
            for(var i = 6; i >= 0; i--){

                pastDt = new Date(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate() + i);
                var monthName = monthNames[pastDt.getUTCMonth()];
                var date = monthName + ' ' + pastDt.getUTCDate();
                dates.push(date);
                if(i == 6)
                    curDt = pastDt;
            }

            if(today.getTime() == curDt.getTime())
            {
             jQuery.noConflict();
             var obj = jQuery('li.previous');
             obj.addClass("disabled");
            }
            else {

                jQuery.noConflict();
                var obj = jQuery('li.next');
                console.log(obj.length);
                obj.removeClass("disabled");
            }
            component.set("v.dates", dates);
            component.set("v.lastDate", pastDt);
            component.set("v.firstDate", curDt);
            this.loadTrustGrid(component);
        },

        loadTableData: function(component, helper){

         var monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                            "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
         var myAction = component.get('c.getPlatformInfo');
         // Handle returned results...
         myAction.setParams({lastDate : component.get("v.lastDate")});
         myAction.setCallback(component, function(response) {
                var state = response.getState();

                if(component.isValid() && state === "SUCCESS") {
                    var result = response.getReturnValue();
                    var platforms = [];
                    var tableData = [];
                    var lastDate = '';
                   //console.log('result =>' + JSON.stringify(result));
                    // result = JSON.stringify(result);
                        console.log('result =>' + result);

                    // Loop through results; remember, this is a list of sObjects
                    for(var item in result) {
                        // Get the record
                         var temp =  result[item];
                         //temp = JSON.stringify(temp);
                         console.log('temp =>' + JSON.stringify(temp));
                         platforms.push(temp.platformName);
                         tableData.push(temp);
                       }

                       component.set('v.datalist', tableData);
                } else {
                    // error handling
                }

        });
         $A.enqueueAction(myAction);
    },

    loadTrustGrid: function(component, helper){
        var thisHelper = this;
        this.showSpinner(component, helper);
         var firstDate  = component.get("v.firstDate");
         var f = firstDate == "" ? new Date() : firstDate;
         var today = new Date();
         var day7 = today.setDate(today.getDate() - 7);
         day7 = new Date(day7);
         var lastDate  = component.get("v.lastDate");
         var l = lastDate == "" ? day7 : lastDate;

        console.log('firstDate =>' + f.toString());
        console.log('lastDate =>' + l.toString());
        component.set('v.gridRows',null);
         // Handle returned results...
         var myAction = component.get('c.initTrustGrid');
         myAction.setParams(
             {cadebillAccountNo : 4593141,
             firstDate : f,
             lastDate : l}
         );
         myAction.setCallback(component, function(response) {
                var state = response.getState();

                if(component.isValid() && state === "SUCCESS") {
                    var result = response.getReturnValue();
                    console.log('result =>' + result);
                    console.log('result =>' + JSON.stringify(result));
                    var trustGridRows = [];
                    // Loop through results; remember, this is a list of sObjects
                    for(var item in result) {
                        // Get the record
                        var temp =  result[item];
                        //console.log('temp =>' + JSON.stringify(temp));
                        //platforms.push(temp.platformName);
                        trustGridRows.push(temp);
                    }

                    component.set('v.gridRows', trustGridRows);
                     thisHelper.hideSpinner(component, helper);

                } else {
                    // error handling
                }

        });
         $A.enqueueAction(myAction);

    },


     showSpinner : function (component, helper) {
        var spinner = component.find('spinner');
        var evt = spinner.get("e.toggle");
        evt.setParams({ isVisible : true });
        evt.fire();
    },

    hideSpinner : function (component, helper) {
       var spinner = component.find('spinner');
       var evt = spinner.get("e.toggle");
       evt.setParams({ isVisible : false });
       evt.fire();
    },

    convertToUTC : function(dateLocal){
        var dateUTC = new Date(
            dateLocal.getUTCFullYear(),
            dateLocal.getUTCMonth(),
            dateLocal.getUTCDate(),
            dateLocal.getUTCHours(),
            dateLocal.getUTCMinutes(),
            dateLocal.getUTCSeconds(),
            dateLocal.getUTCMilliseconds()
        );
        return dateUTC;
    }

})