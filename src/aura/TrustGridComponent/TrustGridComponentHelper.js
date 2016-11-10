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
            var pastDt;
            for(var i = 7; i > 0; i--){
                pastDt = new Date(d.getFullYear(), d.getMonth(), d.getDate() - i);
                var monthName = monthNames[pastDt.getMonth()];
                var date = monthName + ' ' + pastDt.getDate();
                dates.push(date);
                console.log(i);
            }
            if(today.getTime() == pastDt.getTime())
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
            component.set("v.lastDate", new Date(d.getFullYear(), d.getMonth(), d.getDate() + 7));

        },

        loadTableData: function(component, helper){
         console.log('came here');
         var myAction = component.get('c.getPlatformInfo');
         // Handle returned results...

         myAction.setCallback(component, function(response) {
                var state = response.getState();

                if(component.isValid() && state === "SUCCESS") {
                    var result = response.getReturnValue();
                    var platforms = [];
                    var tableData = [];

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

                       console.log('platforms =>' + platforms);



                      /**  // Pull out the field that's going to be my key
                       var myKey = myRecord.someField__c

                        // Keep track of whether our key already exists in myObjectMap
                        var found = false;
                        // Loop through our map and see if an entry for our key exists
                        for(var x=0; x<myObjectMap.length; x++) {
                            // Look to see if our object has a "key" value
                            // and whether that key is equal to the key we want
                            // to use to group everything
                            if("key" in myObjectMap[x] && myObjectMap[x]["key"] == myKey) {
                                myObjectMap[x]["list"].push(myRecord);
                                // We found our key and pushed the record into its
                                // list, no need to continue
                                found = true;
                                break;
                            }
                        }
                        // Need to make sure this record found a home; if it didn't
                        // then we need to initialize it in our "map"
                        if(!found) {
                            var temp = { "key": myKey, "list": [myRecord] };
                            myObjectMap.push(temp);
                        }
                    }

                    component.set('v.listOfMyCustomObject', myObjectMap);

                    /*
                    At the end of all this, myObjectMap should look something like...
                    [
                        {
                            "key": "value 1"
                            , "list": [
                                {
                                    ...json representation of myCustomObj__c...
                                }
                                , {
                                    ....another record...
                                }
                            ]
                        }
                        , {
                            "key": "value 2"
                            , "list": [
                                {
                                    ...another record...
                                }
                            ]
                        }
                    ];

                    */
                } else {
                    // error handling
                }

        });
         $A.enqueueAction(myAction);
    }
})