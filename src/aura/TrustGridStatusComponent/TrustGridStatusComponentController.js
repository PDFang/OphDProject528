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
        var monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                          "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        var today = new Date();
        var monthName = monthNames[today.getUTCMonth()];
         var date = monthName + ' ' + today.getUTCDate();
         component.set("v.currentDate", date);
       // helper.loadTrustGrid(component);
    },

    loadNext:function(component, event, helper){

        helper.getPastSevenDates(component);

    },

    loadCurrentWeek:function(component, event, helper){
           component.set("v.lastDate", '');
            helper.getPastSevenDates(component);
                 jQuery.noConflict();
                  var obj = jQuery('li.previous');
                  obj.addClass("disabled");

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
    },
    showModal :  function(component, event, helper) {

      var cmpModal = component.find('myModal');
      $A.util.addClass(cmpModal, 'incontact-modal');
      $A.util.removeClass(cmpModal, 'modal-hide');

     },

     hideModal :  function(component, event, helper) {

           var cmpModal = component.find('myModal');
           $A.util.removeClass(cmpModal, 'incontact-modal');
           $A.util.addClass(cmpModal, 'modal-hide');

          }

})