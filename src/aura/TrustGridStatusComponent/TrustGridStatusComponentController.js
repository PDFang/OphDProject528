/**
 * Created by mohandaas.rangaswamy on 11/16/2016.
 */
({

    loadDates: function(component, event, helper) {
        console.log("scripts loaded");
         helper.getPastSevenDates(component);
         jQuery(document).ready(function() {
             jQuery("body").tooltip({ selector: '[data-toggle=tooltip]' });
         });


    },

    loadPrevious : function(component, event, helper){
         helper.getFutureDates(component);
    },

    doInit:function(component, event, helper) {
        console.log("call do init");
       // helper.loadTrustGrid(component);
    },

    loadNext:function(component, event, helper){
        helper.getPastSevenDates(component);
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