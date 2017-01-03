/**
 * Created by arnab.karsarkar on 12/21/2016.
 */
({
  doInit: function(component, event, helper) {

    for (var i = 0; i < 41; i++) {
      var cellCmp = component.find(i);
      if (cellCmp) {
        cellCmp.addHandler("dateCellClick", component, "c.handleClick");
      }
    }
    var format = component.get("v.formatSpecifier");
    var datestr = component.get("v.value");
    var langLocale = $A.get("$Locale.langLocale");

    var momentDate = moment(datestr, 'MM/DD/YYYY');
    var currentDate;

    if(currentDate == null || !currentDate.isValid()){
      currentDate = moment().toDate();
    }
    else {
      currentDate = momentDate.toDate();
    }
    helper.setDateValues(component, currentDate, currentDate.getDate());

    // Set the first day of week
    helper.updateNameOfWeekDays(component);
    helper.generateYearOptions(component,currentDate);

    var setFocus = component.get("v.setFocus");
    if (!setFocus) {
      component.set("v._setFocus", false);
    }
    helper.renderGrid(component);
  },


  handleYearChange : function (component, event, helper){

    var newYear = component.find("yearSelect").get("v.value");
    var date = component.get("v.date");
    helper.changeYear(component,newYear,date);
  },

  handleClick: function(component, event, helper) {
    console.log('Date picker controller click' + event);
    helper.selectDate(component, event);
  },

  goToToday: function(component, event, helper) {
    event.stopPropagation();
    helper.goToToday(component, event);
    return false;
  },

  goToPreviousMonth: function(component,event,helper) {
    event.stopPropagation();
    helper.changeMonth(component, -1 );
    return false;
  },

  goToNextMonth: function(component,event,helper) {
    event.stopPropagation();
    helper.changeMonth(component, 1);
    return false;
  }


});