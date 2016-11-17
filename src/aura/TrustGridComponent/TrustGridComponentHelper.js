/**
 * Created by arnab.karsarkar on 11/4/2016.
 */
({
    getPastSevenDates: function(component, helper){
        var monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        var dates  = [];
        var lastDate  = component.get("v.lastDate");
        var d = lastDate == "" ? new Date() : lastDate;
        component.set("v.firstDate", d);
        var pastDt;
        var today = new Date();
        var priorDate =  new Date(today.getFullYear(), today.getMonth(), today.getDate() - 30);

        for(var i = 0; i < 7; i++){
            pastDt = new Date(d.getFullYear(), d.getMonth(), d.getDate() - i);
            var monthName = monthNames[pastDt.getMonth()];
            var date = monthName + ' ' + pastDt.getDate();
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

                pastDt = new Date(d.getFullYear(), d.getMonth(), d.getDate() + i);
                var monthName = monthNames[pastDt.getMonth()];
                var date = monthName + ' ' + pastDt.getDate();
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
    }

})