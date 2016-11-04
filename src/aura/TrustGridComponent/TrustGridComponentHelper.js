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
            var lastDate  = component.get("v.lastDate");
            var d = new Date(lastDate.getFullYear(), lastDate.getMonth(), lastDate.getDate() + 7);

            var pastDt;
            var today = new Date();
            for(var i = 0; i < 7; i++){
                pastDt = new Date(d.getFullYear(), d.getMonth(), d.getDate() - i);
                var monthName = monthNames[pastDt.getMonth()];
                var date = monthName + ' ' + pastDt.getDate();
                dates.push(date);
            }
            if(today.getTime() == pastDt.getTime())
            {
             jQuery.noConflict();
             var obj = jQuery('li.previous');
             obj.addClass("disabled");
            }
            else if(lastDate != ''){

                jQuery.noConflict();
                var obj = jQuery('li.next');
                console.log(obj.length);
                obj.removeClass("disabled");
            }
            component.set("v.dates", dates);
            component.set("v.lastDate", pastDt);

        }

})