/**
 * Created by arnab.karsarkar on 11/2/2016.
 */
({

    loadDates: function(component, event, helper) {
        console.log("scripts loaded");
         //helper.getPastSevenDates(component);

    },

    loadPrevious : function(component, event, helper){
         helper.getFutureDates(component);
    },

    doIntit:function(component, event, helper) {
      console.log("call do init");
      helper.loadTableData(component);
    },
    doneRendering: function(component){
       /** jQuery.noConflict();
        var firstDate = '0_date';
        $j(document).ready(function(){
               console.log(firstDate);
               console.log($j('#' + firstDate).length);
               $j('#' + firstDate).popover({
                   container : 'body'
               });
          }); **/
    }

})