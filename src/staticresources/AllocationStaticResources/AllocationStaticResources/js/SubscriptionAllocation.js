function subscriptionAllocationData(projId, subscriptionId){

   console.log('subscriptionId =>' + subscriptionId);
       var subscriptionAllocationData =new kendo.data.DataSource({
            autosync:true,
            transport:{
              read: function(options){
                       AssetSubscriptionAllocationNewController.getSubscriptionAllocationData(projId, subscriptionId,
                          function(result,event)
                              {
                                  if (event.status) {
                                      if(result != null && result.length > 1){
                                           options.success(JSON.parse(result));
                                           console.log('results =>' + JSON.stringify(result));
                                           var records = JSON.parse(result);
                                           showHideAddButton(records[0]);
                                      }else{
                                           options.success('');
                                           showHideAddButton('');
                                      }
                                  } else if (event.type === 'exception') {

                                  } else {

                                  }
                              },
                              {escape: false}
                       );
              },
              update: function(options){
                   console.log('update options =>' + JSON.stringify(options.data));
                   AssetSubscriptionAllocationNewController.UpsertAssetSubscriptionAllocation(
                        'Subscription',
                        JSON.stringify(options.data),
                        function(result,event){
                               if (event.status) {
                                  var returnResult = JSON.parse(result);
                                  if(returnResult.result != 'Failed'){
                                     options.success();
                                      reloadDetails();
                                     hideError();
                                  }else{
                                      displayError(returnResult.message);
                                  }
                                }else{
                                  displayError(event.message);
                                }
                            },
                            {escape: false}
                    );
                },
                create: function(options){
                    $('#loading').modal({
                         backdrop: 'static',
                         keyboard: false
                    });
                    $('#loading').modal('show');
                    console.log('options =>' + JSON.stringify(options.data));
                    if(options.data.ProjectNumber == null || options.data.ProjectNumber == '' || options.data.Subscription == null || options.data.Subscription == ''){
                        $('#loading').modal('hide');
                         if(currentObjectType == 'Project')
                                displayError('Please select an subscription before saving.');
                         else if(currentObjectType == 'Subscription')
                                 displayError('Please select a project before saving.');
                    }else{
                          AssetSubscriptionAllocationNewController.UpsertAssetSubscriptionAllocation(
                                   'Subscription',
                                   JSON.stringify(options.data),
                                   function(result,event){
                                       if (event.status) {
                                          var returnResult = JSON.parse(result);
                                          if(returnResult.result != 'Failed'){
                                               options.success();
                                                $('#loading').modal('hide');
                                                 reloadDetails();
                                               hideError();
                                            }else{
                                                 $('#loading').modal('hide');
                                            displayError(returnResult.message);
                                          }
                                       }else{

                                           $('#loading').modal('hide');
                                           displayError(event.message);
                                       }
                                      },
                                      {escape: false}
                              );
                          }

                },
                destroy: function(options){
                     options.success();
                }
            },
            schema:{
                model: {
                    id: "Id",
                    fields: {
                        "Subscription": {from:"Subscription", type: "string", editable:false},
                        "Id": { from: "SubscriptionAllocationId", type: "string",editable:false },
                        "SubscriptionName" : {from:"SubscriptionName", type:"string",editable:false },
                        "SubscriptionAllocationName" : {from:"SubscriptionAllocationName", type:"string",editable:false},
                       "Product": { from: "Product", type: "string",editable:false },
                        "ProductName": { from: "ProductName", type: "string",editable:false },
                        "ProjectNumber":{from:"ProjectNumber",type:"string",editable:false},
                        "ProjectName":{from:"ProjectName",type:"string", editable:false},
                        "ProjectPhase" : {from:"ProjectPhase", type: "string", editable:false},
                        "AllocatedHours":{from: "AllocatedHours", type:"number", editable: true, nullable: true},
                        "BudgtedHours":{from: "BudgtedHours", type:"number", defaultValue:0},
                        "Quantity":{from: "Quantity", type:"number", defaultValue:0},
                        "Implemented" : {from:"Implemented", type:"boolean"},
                        "OnHold" : {from:"OnHold", type:"boolean"},
                        QuantityOnHold : {from:"QuantityOnHold", type:"number", defaultValue:0},
                        QuantityCancelled : {from:"QuantityCancelled", type:"number", defaultValue:0},
                        RemainingQuantity : {from:"RemainingQuantity", type:"number", defaultValue:0},
                        "AllocatedQuantity":{
                            from: "AllocatedQuantity",
                            type:"number",
                           nullable: true,
                            editable:true,
                            defaultValue:0,
                            validation : {
                                quantityValidation : function(input){

                                    var parentRow = $(input).parents("tr:first");
                                    var grid = $("#subscriptionAllocationList").data("kendoGrid");
                                    var rowData = grid.dataItem(parentRow),
                                        allocatedQuantityVal = rowData.SubscriptionAllocationName == '' ? 0 : rowData.AllocatedQuantity;

                                    if(!rowData){
                                      input.attr("data-quantityValidation-msg", "Please select an asset");
                                      return false;
                                    }
                                    if(input.val() == 0 && input.is("[name='AllocatedQuantity']")){
                                        input.attr("data-quantityValidation-msg", "Allocated Quantity cannot be zero");
                                        return false;
                                    }
                                      if(Number(input.val()) > (Number(rowData.RemainingQuantity) + Number(allocatedQuantityVal)) && input.is("[name='AllocatedQuantity']")){
                                        input.attr("data-quantityValidation-msg", 'Cannot allocate more than “Contract Quantity”');
                                        return false;
                                    }
                                     if(input.is("[name='AllocatedQuantity']") && Number(input.val()) % 1 != 0){
                                         input.attr("data-quantityValidation-msg", 'Decimal values are not allowed in Allocated Quantity field');
                                         return false;
                                    }
                                     if(Number(input.val()) > 1 && input.is("[name='AllocatedQuantity']") && rowData.Quantity == 1){
                                            input.attr("data-quantityValidation-msg", 'Allocated Quantity cannot be more than 1');
                                            return false;
                                    }
                                    return true;
                                }
                           }
                        },
                        AllocatedPercentage:{
                            from: "AllocatedPercentage",
                            type:"number",
                            nullable: true,
                            editable:true,
                            validation : {
                                percentageValidation : function(input){
                                      var parentRow = $(input).parents("tr:first");
                                      var grid = $("#subscriptionAllocationList").data("kendoGrid");
                                      var rowData = grid.dataItem(parentRow);
                                      if(!rowData){
                                        input.attr("data-quantityValidation-msg", "Please select an asset");
                                        return false;
                                      }
                                      if(input.val() > 100 && input.is("[name='AllocatedPercentage']")){
                                          input.attr("data-percentageValidation-msg", " Invalid Percentage");
                                          return false;
                                      }
                                       if(input.val() == 0 && input.is("[name='AllocatedPercentage']") && rowData.Quantity == 1){
                                          input.attr("data-percentageValidation-msg", " Allocated Hours % cannot be zero");
                                          return false;
                                      }
                                  return true;
                                }
                            }
                        }

                    }
                }
            },
            change : calculateSubscriptionBudgetedHours
       });

       var window = $("#window").kendoWindow({
           title: "Are you sure you want to delete this record?",
           visible: false, //the window will not appear before its .open method is called
          width: "400px",
           height: "200px",
       }).data("kendoWindow");



    $("#subscriptionAllocationList").kendoGrid({
          dataSource: subscriptionAllocationData,
          editable: "inline",
          scrollable: true,
          noRecords: true,
          height:600,
          edit:addDuplicateRowSubscription,
          detailInit: loadSubscriptionChildGrid,
          dataBound: gridDataboundSubscription,
          cancel : hideChildProjects,
          toolbar: [
              {
                  name: "create",
                  text: "Add New Subscription Allocation"
              }
              ],
          columns: [{
                        field:"Id",
                        hidden: true,
                        editable:false

                    },
                    {
                        field:"SubscriptionName",
                        title:"Subscription",
                        width:250,
                        editor:nonEditorSubscription,
                        hidden: true,
                        /*template: '#{ #<a href="/#: data.Subscription #" target="_blank" >#= data.SubscriptionName #</a># } #',*/
                    },
                    {
                        field:"ProductName",
                        title:"Subscription",
                        width:300,
                        editor:nonEditorSubscription,
                        template: '#{ #<a href="/#: data.Subscription #" target="_blank" >#= data.ProductName #</a># } #',
                    },
                    {
                        field:"SubscriptionAllocationName",
                        width:100,
                        title:"Allocation",
                        editor:nonEditorSubscription,
                        template: '#{ #<a href="/#: data.Id #" target="_blank" >#= data.SubscriptionAllocationName #</a># } #',
                    },
                    {
                        field:"ProjectName",
                        title:"Project",
                        hidden: true

                    },

                    {
                        field:"ProjectPhase",
                        title:"Project Phase",
                        width:300,
                         template: '#{ #<a href="/#: data.ProjectNumber #" target="_blank" >#= data.ProjectPhase #</a># } #',
                        editor:nonEditorSubscription,
                        filterable:true
                    },
                    {
                        field:"AllocatedQuantity",
                        title:"Allocated Quantity",
                        editable:true
                    },
                    {
                        field:"AllocatedPercentage",
                        title:"Allocated %",
                        editable:false
                    },
//                    {
//                        field:"AllocatedHours",
//                        title:"Allocated Hours",
//                        editable:true
//                    },

                    {
                        field:"Implemented",
                        title:"Imp",
                        template: '<input type="checkbox"  "# if (data.Implemented) { # checked="checked" # } #"  disabled "/>',
                        width:50

                    },
                    {
                        field:"OnHold",
                        title:"On Hold",
                        template: '<input type="checkbox"  "# if (data.OnHold) { # checked="checked" # } #"  disabled "/>',
                        width:50

                    },
                    {   title:"Action",
                       command: ["edit",
                        {name: "Delete",
                         click: function(e){  //add a click event listener on the delete button
                                 e.preventDefault(); //prevent page scroll reset
                                 var tr = $(e.target).closest("tr"); //get the row for deletion
                                 var data = this.dataItem(tr); //get the row data so it can be referred later
                                 window.content(windowTemplate(data)); //send the row data object to the template and render it
                                 window.center().open();
                                 $("#yesButton").click(function(){
                                       var grid = $("#subscriptionAllocationList").data("kendoGrid");
                                       window.close();
                                       $('#loading').modal({
                                            backdrop: 'static',
                                            keyboard: false
                                       });
                                       $('#loading').modal('show');
                                       AssetSubscriptionAllocationNewController.DeleteAllocation(
                                           data.Id,
                                           'Subscription',
                                           function(result,event){
                                               if (event.status) {
                                                  var returnResult = result;
                                                  if(result == 'success'){
                                                       grid.dataSource.remove(data);
                                                        reloadDetails();
                                                       $('#loading').modal('hide');
                                                    }else{
                                                    $('#loading').modal('hide');
                                                    displayError(result);

                                                  }
                                               }else{
                                                   displayError(event.message);
                                               }
                                           },
                                           {escape: false}
                                       );

                                 });
                                 $("#noButton").click(function(){
                                        window.close();
                                 });
                         }
                        }]
                    }
                ]
            });
       }

function addDuplicateRowSubscription(e){
            var subscriptionGrid = $("#subscriptionAllocationList").data("kendoGrid");;
            var dataItems = subscriptionGrid.dataItems();
            if(e.model.isNew() && !e.model.dirty ){
                if(currentObjectType == 'Subscription'){
                    e.model.Subscription = Subscription.Id;
                    e.model.SubscriptionName = Subscription.Name;
                    var firstCell = e.container.contents()[3];
                    $('<a href="/' +  e.model.Subscription + '" target="_blank">' + e.model.ProductName +'</a>').appendTo(firstCell);
                    var projectCell = e.container.contents()[6];
                    $('<a style="color:blue;cursor:pointer;" class="projectSelectorSubs" onClick="loadSubscriptionDetail(this);">Select Projects </a>').appendTo(projectCell);
                    loadSubscriptionDetail($("a.projectSelectorSubs"));
                    e.model.Quantity = Subscription.Quantity;
                    e.model.BudgtedHours = Subscription.Budgeted_Hours__c == '' ? 0 : Subscription.Budgeted_Hours__c;
                    e.model.RemainingQuantity = Subscription.RemainingQuantity__c;
                    e.model.QuantityOnHold  = Subscription.QuantityonHold__c == '' ? 0 : Subscription.QuantityonHold__c;
                    e.model.QuantityCancelled  = Subscription.QuantityCancelled__c == '' ? 0 : Subscription.QuantityCancelled__c;
                    calculateRemainingSubscriptionAllocation(e.model, e.container);
                }else if(currentObjectType == 'Project'){
                    e.model.ProjectNumber = Project.Id;
                    e.model.ProjectName = Project.Name;
                    e.model.ProjectPhase = Project.Project_Phase_Allocation__c;
                    var phaseCell = e.container.contents()[6];
                    $('<a href="/' +  e.model.ProjectNumber + '" target="_blank">' + e.model.ProjectPhase +'</a>').appendTo(phaseCell);

                    //$('<span>' +  e.model.ProjectPhase + '</span>').appendTo(phaseCell);

                    var firstCell = e.container.contents()[3];
                    $('<a style="color:blue;cursor:pointer;" class="subscriptionSelector" onClick="loadSubscriptionDetail(this);">Select Subscriptions </a>').appendTo(firstCell);
                    loadSubscriptionDetail($("a.subscriptionSelector"));
                }



                 var buttonCell = e.container.contents()[11];
                 $(buttonCell).find("a.k-primary").html('<span class="k-icon k-i-update"></span> Add');
            }else{
                enableSubscriptionAllocation(e.model, e.container);
            }
             $("#subscriptionAllocationList").find(".k-hierarchy-cell, .k-hierarchy-col").hide();
}

function enableSubscriptionAllocation(rowData, row){
            var allocatedHoursCell =  $(row).children().eq(9);
            var allocatedQPercentageCell =  $(row).children().eq(8);
            $(allocatedQPercentageCell).find("input").prop('disabled', true).addClass("k-state-disabled");
            $(allocatedQPercentageCell).find("span.k-select").hide();
            var implementedCell =  $(row).children().eq(9);
            $(implementedCell).find("input").prop('disabled', true);
        }

function calculateRemainingSubscriptionAllocation(rowData, row){
            var subscriptionGrid = $("#subscriptionAllocationList").data("kendoGrid");;
            var dataItems = subscriptionGrid.dataItems();
            var totalQuantity = 0,
            totalPercentage = 0;
            var allocatedQuantityCell =  $(row).children().eq(7);
            var allocatedQPercentageCell =  $(row).children().eq(8);
            var allocatedHoursCell =  $(row).children().eq(9);
            var hours;

                $(allocatedQPercentageCell).find("span.k-numerictextbox").hide();
                rowData.AllocatedQuantity = rowData.AllocatedQuantity == null ? rowData.RemainingQuantity : rowData.AllocatedQuantity;
                $(allocatedQuantityCell).find("span.k-numerictextbox").show();
                $(allocatedQuantityCell).find("input").val(rowData.AllocatedQuantity);
                hours = rowData.BudgtedHours * (rowData.AllocatedQuantity / rowData.Quantity);
                $(allocatedHoursCell).find("input").prop('disabled', false).removeClass("k-state-disabled");
                $(allocatedHoursCell).find("span.k-select").show();
                rowData.AllocatedPercentage = rowData.AllocatedPercentage == null ? Subscription.Remaning_Percentage__c : rowData.AllocatedPercentage;
                $(allocatedQPercentageCell).find("input").prop('disabled', true).addClass("k-state-disabled");
                $(allocatedQPercentageCell).find("span.k-numerictextbox").show();
                $(allocatedQPercentageCell).find("input").val(rowData.AllocatedPercentage);
                $(allocatedQPercentageCell).find("span.k-select").hide();

            rowData.AllocatedHours = hours.toFixed(2);
            $(allocatedHoursCell).find("input").val(rowData.AllocatedHours);
             var implementedCell =  $(row).children().eq(9);
             $(implementedCell).find("input").prop('disabled', true);
        }

function nonEditorSubscription(container, options) {
        container.text(options.model[options.field]);
}

function gridDataboundSubscription(e){
          // var grid = this;
          $("#subscriptionAllocationList").find(".k-hierarchy-cell, .k-hierarchy-col").hide();
           $("#subscriptionAllocationList tbody tr .k-grid-edit").each(function () {
              var currentDataItem = $("#subscriptionAllocationList").data("kendoGrid").dataItem($(this).closest("tr"));
              //Check in the current dataItem if the row is editable
              if (currentDataItem.Implemented == true && isManager == false) {
                  $(this).remove();
              }
              else if(projectPhaseStatus == 'Cancelled' || ((projectPhaseStatus == 'Closed' || projectPhaseStatus == 'Suspended') && isManager == false)){
                  $(this).remove();
              }
          });
           //Selects all delete buttons
           $("#subscriptionAllocationList tbody tr a.k-grid-Delete").each(function () {
                  var currentDataItem = $("#subscriptionAllocationList").data("kendoGrid").dataItem($(this).closest("tr"));
                  //Check in the current dataItem if the row is deletable
                  if (currentDataItem.Implemented == true && isManager == false) {
                      $(this).remove();
                  }
                  else if(projectPhaseStatus == 'Cancelled' || ((projectPhaseStatus == 'Closed' || projectPhaseStatus == 'Suspended') && isManager == false)){
                    $(this).remove();
                  }
              });

           $("#subscriptionAllocationList").find('div.k-grid-content').css("height", "520px");
      }

function calculateSubscriptionBudgetedHours(e){
    if (e.action === "itemchange" && e.field == "AllocatedQuantity"){
            var model = e.items[0],
                budgtedHours = model.BudgtedHours,
                currentValue;
                allocatedHoursInput = $("#subscriptionAllocationList").find("tr[data-uid='" + model.uid + "'] td:eq(9)"),
                allocatedSubPercentageInput = $("#subscriptionAllocationList").find("tr[data-uid='" + model.uid + "'] td:eq(8)");
            var percentage = (100*(model.AllocatedQuantity / model.Quantity)).toFixed(2);
            currentValue = (budgtedHours * (model.AllocatedQuantity / model.Quantity)).toFixed(2);
            if( model.Quantity == 0)
               currentValue = 0;

              $(allocatedSubPercentageInput).find("input").val(percentage).prop('disabled', true).addClass("k-state-disabled");
              $(allocatedSubPercentageInput).find("span.k-select").hide();
            console.log('percentage ==>' + percentage);
            model.AllocatedHours = currentValue;
            model.AllocatedPercentage = percentage;
    }
}

function loadSubscriptionDetail(obj){
       var row = $(obj).parent().parent();
       var link = $(row).find("td.k-hierarchy-cell .k-icon");

       link.click();
       $(row).find("tr.k-detail-row").show();
       $(row).next().find(".k-hierarchy-cell").hide();
   }

function loadSubscriptionChildGrid(e){
        if(currentObjectType === 'Subscription'){
           detailSubscriptionProjects(e);
        } else if(currentObjectType === 'Project'){
            detailSubscription(e);
       }
    }

function detailSubscriptionProjects(e) {
        $("<div id='detailSubscriptionTable'/>").appendTo(e.detailCell).kendoGrid({
        dataSource: {
            autosync:true,
            transport: {
                read: function(options){
                     AssetSubscriptionAllocationNewController.PhaseProjectDetails(
                        e.data.Subscription,
                        'Subscription',
                        function(result,event){
                          if (event.status) {
                              if(result != null && result.length > 1){
                                   options.success(JSON.parse(result));
                                   console.log('PhaseProjectDetails =>' + JSON.stringify(result));
                              }else{
                              options.success('');
                              }
                          }
                        },{escape: false}
                     );
                },
            },
            schema:{
                model: {
                    id: "ProjectId",
                    fields: {
                        ProjectId: { from: "Id"},
                        ProjectNumber: {from:"Name", type: "string"},
                        Summary : {from:"Summary__c", type:"string"},
                        Status : {from:"Phase_Status__c", type:"string"},
                        PhaseNumber : {from:"Phase__c", type:"string"}
                    }
                }
            }
        },
        scrollable: true,
        height: 400,
        sortable: true,
        dataBound:onProjSubDataBound,
        noRecords: true,
        columns: [
            { command: { text: "Select", click : selectSubscriptionProject}, title: "Action", width: "60px" },
            { field: "ProjectNumber", title:"Phase Project Number", width: "110px" },
            { field: "PhaseNumber", title:"Phase #", width: "110px" },
            { field: "Summary", title:"Phase Project Summary", width: "200px" },
            { field: "Status", title:"Project Status", width: "110px" }
        ]
    });
    }

    var wrapper, header, parentGrid;
        function onProjSubDataBound(){
                wrapper = this.wrapper,
                header = wrapper.find(".k-grid-header");
                parentGrid =  $("#subscriptionAllocationList").find('div.k-grid-content').first();
                resizeFixed();
                $(window).resize(resizeFixedSubscription);
                parentGrid.scroll(scrollFixedSubscription);
               $(window).scroll(function(){
                  if($(header).hasClass("fixed-header")){
                     var headerTop = $("#subscriptionAllocationList").find('div.k-grid-content').first().offset().top - $(window).scrollTop();
                      header.css("top", headerTop);
                  }
               });
        }

function selectSubscriptionProject(e){
    var dataItem = this.dataItem($(e.currentTarget).closest("tr"));

    var detailGrid = this.wrapper;
    var parentRow = detailGrid.closest("tr.k-detail-row").prev("tr");
    var grid = $("#subscriptionAllocationList").data("kendoGrid");
    var rowData = grid.dataItem(parentRow);
    if(rowData){
      rowData.ProjectNumber = dataItem.ProjectId;
      rowData.ProjectName = dataItem.ProjectNumber;
      rowData.ProjectPhase = dataItem.ProjectNumber + ' - ' + dataItem.Summary +  ' - ' + dataItem.PhaseNumber;
      //grid.dataSource.sync();

       var projectPhaseCell = $(parentRow).children().eq(6);
      var htmlContentProject = $('<a style="color:blue;cursor:pointer;" onClick="loadSubscriptionDetail(this);">' +  rowData.ProjectPhase +'</a>');
      $(projectPhaseCell).html(htmlContentProject);
    }
    grid.collapseRow(parentRow);

  }

function detailSubscription(e) {
            $("<div id='detailSubscriptionTable'/>").appendTo(e.detailCell).kendoGrid({
            dataSource: {
                autosync:true,
                transport: {
                    read: function(options){
                         AssetSubscriptionAllocationNewController.AssetSubscriptionDetailsFromProjectPhase(
                            e.data.ProjectNumber,
                            'Subscription',
                            function(result,event){
                              if (event.status) {
                                  if(result){
                                       options.success(JSON.parse(result));
                                       console.log('Subscription Details =>' + JSON.stringify(result));
                                  }else{
                                      options.success('');
                                  }
                              }
                            },{escape: false}
                         );
                    },
                },
                schema:{
                    model: {
                        id: "SubscriptionId",
                        fields: {
                            SubscriptionId: { from: "Id"},
                            SubscriptionName: {from:"Name", type: "string"},
                           Product: {from:"Subscription_Name__c", type: "string"},
                            RemainingPercentage : {from:"Remaning_Percentage__c", type:"string"},
                            RemainingQuantity : {from:"RemainingQuantity__c", type:"string"},
                            RemainingHours : {from:"Remaining_Hours__c", type:"string"},
                            Quantity:{from:'Quantity__c', type:"number"},
                            BudgtedHours:{from:'Budgeted_Hours__c', type:"number"},
                            QuantityOnHold:{from:'QuantityonHold__c', type:"number"},
                            QuantityCancelled :{from:'QuantityCancelled__c', type:"number"}
                        }
                    }
                }
            },
            scrollable: true,
            height:400,
            sortable: true,
            noRecords: true,
            dataBound:onSubscriptionDataBound,

                toolbar:[
                    {
                       template : '<a class="k-button" href="\\#" onclick="return updateSubsAllocation();">Allocate Selected</a>'
                    }
                ],
                columns: [
                    {
                       title: 'Select All',
                       headerTemplate: "<input type='checkbox' id='subs-header-chb' class='k-checkbox header-checkbox'><label class='k-checkbox-label' for='subs-header-chb' style='top:-10px;'></label>",
                                                                             template: function (dataItem) {
                           return "<input type='checkbox' id='" + dataItem.SubscriptionId + "' class='k-checkbox row-checkbox'><label class='k-checkbox-label' for='" + dataItem.SubscriptionId + "'></label>";
                       },
                       width: 80
                    },
                    {command: { text: "Select", click : selectSubscription}, title: "Action", width: "60px" },
                    { field: "SubscriptionName", title:"Subscription", hidden:true },
                    { field: "Product", title:"Subscription", width: "110px" },
                    { field: "RemainingQuantity", title:"Remaining Quantity", width: "110px" },
                    { field: "RemainingPercentage", title:"Remaining Percentage", width: "200px" },
                    { field: "RemainingHours", title:"Remaining Hours", width: "110px" }
            ]
            });


             var subscriptionGrid = $("#detailSubscriptionTable").data("kendoGrid");
             //bind click event to the checkbox
             subscriptionGrid.table.on("click", ".row-checkbox", selectRowSubs);

             $('#subs-header-chb').change(function (ev) {
                    var checked = ev.target.checked;
                    $('.row-checkbox').each(function (idx, item) {
                        if (checked) {
                            if (!($(item).closest('tr').is('.k-state-selected'))) {
                                $(item).click();
                            }
                        } else {
                            if ($(item).closest('tr').is('.k-state-selected')) {
                                $(item).click();
                            }
                        }
                    });
             });
        }

        var subscheckedIds = {};
        //on click of the checkbox:
        function selectRowSubs() {
            var checked = this.checked,
            row = $(this).closest("tr"),
            grid = $("#detailSubscriptionTable").data("kendoGrid"),
            dataItem = grid.dataItem(row);
            subscheckedIds = {};

            subscheckedIds[dataItem.SubscriptionId] = checked;

            if (checked) {
                //-select the row
                row.addClass("k-state-selected");
                var checkHeader = true;
                $.each(grid.items(), function (index, item) {
                    if (!($(item).hasClass("k-state-selected"))) {
                        checkHeader = false;
                    }
                });

                $("#subs-header-chb")[0].checked = checkHeader;
            } else {
                //-remove selection
                row.removeClass("k-state-selected");
                $("#asset-header-chb")[0].checked = false;
            }
        }

        function updateSubsAllocation(){
            $('#loading').modal({
                 backdrop: 'static',
                 keyboard: false
            });
            $('#loading').modal('show');
            var checked = [];
            for (var i in subscheckedIds) {
                if (subscheckedIds[i]) {
                    checked.push(i);
                }
            }

            if(checked.length > 0){
                AssetSubscriptionAllocationNewController.SaveAllAllocation(
                      null,
                      JSON.stringify(checked) ,
                      Project.Id,
                      function(result,event){
                        if (event.status) {
                           //var returnResult = JSON.parse(result);
                           if(result == 'Success'){
                                $('#loading').modal('hide');
                                 $("#subscriptionAllocationList").data("kendoGrid").destroy();
                                 reloadDetails();
                                   hideError();
                                }else{
                                $('#loading').modal('hide');
                                displayError(result);
                              }
                           }else{

                               $('#loading').modal('hide');
                               displayError(event.message);
                           }
                          },
                          {escape: false}
                  );
            }else{
                 $('#loading').modal('hide');
                displayError('Please check at least one checkbox to add allocation');
            }

            console.log(checked);
        }

        function onSubscriptionDataBound(){
            wrapper = this.wrapper,
            header = wrapper.find(".k-grid-header");
            parentGrid =  $("#subscriptionAllocationList").find('div.k-grid-content').first();
            resizeFixed();
            $(window).resize(resizeFixedSubscription);
            parentGrid.scroll(scrollFixedSubscription);
            $(window).scroll(function(){
              if($(header).hasClass("fixed-header")){
                 var headerTop = $("#subscriptionAllocationList").find('div.k-grid-content').first().offset().top - $(window).scrollTop();
                  header.css("top", headerTop);
              }
           });

            var view = this.dataSource.view();
            for (var i = 0; i < view.length; i++) {
              if (subscheckedIds[view[i].SubscriptionId]) {
                  this.tbody.find("tr[data-uid='" + view[i].uid + "']")
                      .addClass("k-state-selected")
                      .find(".k-checkbox")
                      .attr("checked", "checked");
              }
            }

        }

        function resizeFixedSubscription() {
          var paddingRight = parseInt(header.css("padding-right"));
          header.css("width", wrapper.width() - paddingRight);
        }

            function scrollFixedSubscription() {
              var offset = $(parentGrid).scrollTop() +  $(parentGrid).offset().top,
                  tableOffsetTop = wrapper.offset().top,
                  tableOffsetBottom =  tableOffsetTop + wrapper.height() + 430,
                  headerTop = $(parentGrid).offset().top - $(window).scrollTop();
              if(offset < tableOffsetTop || offset >= tableOffsetBottom) {
                header.removeClass("fixed-header");
                header.css("top", '');
              } else if(offset >= tableOffsetTop && offset < tableOffsetBottom ) {
                 if(!header.hasClass("fixed"))
                    header.addClass("fixed-header");
                header.css("top", headerTop);
              }
            }

function selectSubscription(e){
        var dataItem = this.dataItem($(e.currentTarget).closest("tr"));
        var detailGrid = this.wrapper;
        var parentRow = detailGrid.closest("tr.k-detail-row").prev("tr");
       var grid = $("#subscriptionAllocationList").data("kendoGrid");
        var rowData = grid.dataItem(parentRow);
        if(rowData){
            rowData.Subscription = dataItem.SubscriptionId;
            rowData.SubscriptionName = dataItem.SubscriptionName;
            rowData.AllocatedPercentage = dataItem.RemainingPercentage;
            rowData.AllocatedHours = 0;
            rowData.Quantity = dataItem.Quantity;
            rowData.BudgtedHours = dataItem.BudgtedHours  == '' ? 0 : dataItem.BudgtedHours;
            rowData.QuantityOnHold = dataItem.QuantityOnHold  == '' ? 0 : dataItem.QuantityOnHold;
            rowData.QuantityCancelled = dataItem.QuantityCancelled  == '' ? 0 : dataItem.QuantityCancelled;
            rowData.RemainingQuantity = dataItem.RemainingQuantity  == '' ? 0 : dataItem.RemainingQuantity;
            console.log('rowData.RemainingQuantity1 ==>' + rowData.RemainingQuantity);
            rowData.AllocatedQuantity = rowData.RemainingQuantity;
            console.log('rowData.AllocatedQuantity ==>' + rowData.AllocatedQuantity);
            rowData.ProductName = dataItem.Product;
            var subscriptionCell = $(parentRow).children().eq(3);
            var htmlContentProject = $('<a style="color:blue;cursor:pointer;" onClick="loadSubscriptionDetail(this);">' + dataItem.Product +'</a>');
            $(subscriptionCell).html(htmlContentProject);
            var ProductCell = $(parentRow).children().eq(6);
            $(ProductCell).html('<a href="#" target="_blank">' + rowData.ProjectPhase +'</a>');
            calculateRemainingSubscriptionAllocation(rowData, parentRow);
        }
        grid.collapseRow(parentRow);
    }

