    function assetAllocationData(projId, assetId){
               var assetAllocationData = new kendo.data.DataSource({
                    autosync:true,
                    transport:{
                      read: function(options){
                               AssetSubscriptionAllocationNewController.getAssetAllocationData(
                                   projId,
                                   assetId,
                                  function(result,event)
                                      {
                                          if (event.status) {
                                              if(result != null && result.length > 1){
                                                   options.success(JSON.parse(result));
                                                   console.log('results =>' + JSON.stringify(result));
                                              }else{
                                                  options.success('');
                                              }
                                          }
                                      },
                                      {escape: false}
                               );
                      },
                      update: function(options){
                         console.log('update options =>' + JSON.stringify(options.data));
                         AssetSubscriptionAllocationNewController.UpsertAssetSubscriptionAllocation(
                              'Asset',
                              JSON.stringify(options.data),
                              function(result,event){
                                     if (event.status) {
                                        var returnResult = JSON.parse(result);
                                        if(returnResult.result != 'Failed'){
                                           options.success();
                                            reloadDetails();
                                            //getSObjType();
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
                            if(options.data.ProjectNumber == null || options.data.ProjectNumber == '' || options.data.Asset == null || options.data.Asset == ''){
                                $('#loading').modal('hide');
                                 if(currentObjectType == 'Project')
                                        displayError('Please select an asset before saving.');
                                 else if(currentObjectType == 'Asset')
                                         displayError('Please select a project before saving.');
                            }else{
                                  AssetSubscriptionAllocationNewController.UpsertAssetSubscriptionAllocation(
                                           'Asset',
                                           JSON.stringify(options.data),
                                           function(result,event){
                                               if (event.status) {
                                                  var returnResult = JSON.parse(result);
                                                  if(returnResult.result != 'Failed'){
                                                       options.success();
                                                        $('#loading').modal('hide');
                                                        reloadDetails();
                                                       //getSObjType();
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
                      }
                    },
                    schema:{
                        model: {
                            id: "Id",
                            fields: {
                                Id: { from: "AssetAllocationId"},
                                Asset: {from:"Asset", type: "string"},
                                AssetName : {from:"AssetName", type:"string"},
                                AssetAllocationName : {from:"AssetAllocationName", type:"string"},
                                ProjectNumber:{from:"ProjectNumber",type:"string"},
                                ProjectName:{from:"ProjectName",type:"string"},
                                ProjectPhase : {from:"ProjectPhase", type: "string"},
                                AllocatedQuantity:{
                                    from: "AllocatedQuantity",
                                    type:"number",
                                    nullable: true,
                                    editable:true,
                                    defaultValue:1,
                                     validation : {
                                        quantityValidation : function(input){
                                            var parentRow = $(input).parents("tr:first");
                                            var grid = $("#assetAllocationList").data("kendoGrid");
                                            var rowData = grid.dataItem(parentRow);

                                             if(!rowData){
                                                 input.attr("data-quantityValidation-msg", "Please select an asset");
                                                 return false;
                                             }
                                             if(input.val() == 0 && input.is("[name='AllocatedQuantity']") && rowData.Quantity > 1){
                                                input.attr("data-quantityValidation-msg", "Allocated Quantity cannot be zero");
                                                return false;
                                            }
                                             if(Number(input.val()) > Number(rowData.RemainingQuantity) && input.is("[name='AllocatedQuantity']") && rowData.Quantity > 1 && (rowData.QuantityOnHold > 0 || rowData.QuantityCancelled > 0)){
                                                input.attr("data-quantityValidation-msg", 'Cannot allocate more than “Contract Quantity” if there is any quantity on hold or cancelled');
                                                return false;
                                            }
                                            if(input.is("[name='AllocatedQuantity']") && rowData.Quantity > 1 && Number(input.val()) % 1 != 0){
                                                 input.attr("data-quantityValidation-msg", 'Decimal values are not allowed in Allocated Quantity field');
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
                                            var grid = $("#assetAllocationList").data("kendoGrid");
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
                                                input.attr("data-percentageValidation-msg", " Allocated Percentage cannot be zero");
                                                return false;
                                            }

                                        return true;
                                        }
                                    }
                                },
                                AllocatedHours:{from: "AllocatedHours", type:"number",  nullable: true, editable:true, defaultValue:0},
                                Quantity :{from:"Quantity", type:"number",defaultValue:0},
                                BudgtedHours :{from:"BudgtedHours", type:"number", defaultValue:0},
                                Implemented : {from:"Implemented", type:"boolean"},
                                QuantityOnHold : {from:"QuantityOnHold", type:"number", defaultValue:0},
                                QuantityCancelled : {from:"QuantityCancelled", type:"number", defaultValue:0},
                                RemainingQuantity : {from:"RemainingQuantity", type:"number", defaultValue:0}

                            }
                        }
                    },
                    change : calculateBudgetedHours
               });


        var window = $("#window").kendoWindow({
            title: "Are you sure you want to delete this record?",
            visible: false, //the window will not appear before its .open method is called
            width: "400px",
            height: "200px",
        }).data("kendoWindow");

      $("#assetAllocationList").kendoGrid({
          dataSource: assetAllocationData,
          editable: "inline",
          scrollable:  true,
          noRecords: true,
          height:300,
          edit: addDuplicateRowAsset,
          dataBound : gridDataboundAsset,
          detailInit: loadChildGrid,
          cancel : hideChildProjects,

          toolbar: [
              {
                  name: "create",
                  text: "Add New Asset Allocation"

              }
              ],
          columns: [{
                        field:"Id",
                        hidden: true,
                        editable:false

                    },
                    {
                        field:"AssetName",
                        title:"Asset",
                        editor:nonEditorAsset,
                        template: '#{ #<a href="/#: data.Asset #" target="_blank" name="AssetName">#= data.AssetName #</a># } #',
                    },
                    {
                        field:"AssetAllocationName",
                        title:"Allocation",
                        editor:nonEditorAsset,
                        template: '#{ #<a href="/#: data.Id #" target="_blank" >#= data.AssetAllocationName #</a># } #',
                    },
                    {
                        field:"ProjectName",
                        title:"Project",
                        editor:nonEditorAsset,
                        hidden:true
                    },
                    {
                        field:"ProjectPhase",
                        title:"Project Phase",
                        template: '#{ #<a href="/#: data.ProjectNumber #" target="_blank" >#= data.ProjectPhase #</a># } #',
                         width:300,
                        editor:nonEditorAsset
                    },
                    {
                        field:"AllocatedQuantity",
                        title:"Allocated Quantity",
                        editable:true
                    },
                    {
                        field:"AllocatedPercentage",
                        title:"Allocated Percentage",
                        editable:true
                    },
                    {
                        field:"AllocatedHours",
                        title:"Allocated Hours"
                    },
                    {
                        field:"Implemented",
                        title:"Implemented",
                        template: '<input type="checkbox"  "# if (data.Implemented) { # checked="checked" # } #"  disabled "/>',
                        width:150

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
                                       var grid = $("#assetAllocationList").data("kendoGrid");
                                       window.close();
                                       $('#loading').modal({
                                           backdrop: 'static',
                                           keyboard: false
                                      });
                                      $('#loading').modal('show');
                                       AssetSubscriptionAllocationNewController.DeleteAllocation(
                                           data.Id,
                                           'Asset',
                                           function(result,event){
                                               if (event.status) {
                                                  var returnResult = result;
                                                  if(result != 'Failed'){
                                                       grid.dataSource.remove(data);
                                                       reloadDetails();
                                                       //  getSObjType();
                                                       $('#loading').modal('hide');
                                                    }else{
                                                    displayError('Delete Unsuccessful.');
                                                     $('#loading').modal('hide');
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

    function addDuplicateRowAsset(e){
           var assetGrid = $("#assetAllocationList").data("kendoGrid");
           var dataItems = assetGrid.dataItems();
           if(e.model.isNew() && !e.model.dirty ){
               if(currentObjectType == 'Asset'){
                   e.model.Asset = Asset.Id;
                   e.model.AssetName =Asset.Name;
                   var firstCell = e.container.contents()[2];
                   $('<a href="/' +  e.model.Asset + '" target="_blank">' + e.model.AssetName +'</a>').appendTo(firstCell);
                   var projectCell = e.container.contents()[5];
                   $('<a style="color:blue;cursor:pointer;" onClick="loadDetail(this);">Select Projects </a>').appendTo(projectCell);
                   e.model.Quantity = Asset.Quantity;
                   e.model.RemainingQuantity = Asset.RemainingQuantity__c;
                   e.model.QuantityOnHold  = Asset.QuantityonHold__c == '' ? 0 : Asset.QuantityonHold__c;
                   e.model.QuantityCancelled  = Asset.QuantityCancelled__c == '' ? 0 : Asset.QuantityCancelled__c;
                   e.model.BudgtedHours = Asset.Budgeted_Hours__c == '' ? 0 : Asset.Budgeted_Hours__c;
                   calculateRemainingAllocation(e.model, e.container);

               }else if(currentObjectType == 'Project'){
                   e.model.ProjectNumber = Project.Id;
                   e.model.ProjectName = Project.Name;
                   e.model.ProjectPhase = Project.Project_Phase_Allocation__c;
                   var projectCell = e.container.contents()[5];
                   $('<a href="/' +  e.model.ProjectNumber + '" target="_blank">' + e.model.ProjectPhase +'</a>').appendTo(projectCell);

                   var firstCell = e.container.contents()[2];
                   $('<a style="color:blue;cursor:pointer;" onClick="loadDetail(this);">Select Assets </a>').appendTo(firstCell);
               }
                var buttonCell = e.container.contents()[10];
                $(buttonCell).find("a.k-primary").html('<span class="k-icon k-i-update"></span> Add');
           }else{
               enableAllocation(e.model, e.container);
           }
            $("#assetAllocationList").find(".k-hierarchy-cell, .k-hierarchy-col").hide();
    }

    function enableAllocation(rowData, row){
         var allocatedHoursCell =  $(row).children().eq(8);
        if(rowData.Quantity > 1){
            var allocatedQPercentageCell =  $(row).children().eq(7);
            $(allocatedQPercentageCell).find("span.k-numerictextbox").hide();
            $(allocatedHoursCell).find("input").prop('disabled', false).removeClass("k-state-disabled");
            $(allocatedHoursCell).find("span.k-select").show();
        }else if(rowData.Quantity == 1){
            var allocatedQuantityCell =  $(row).children().eq(6);
            $(allocatedQuantityCell).find("span.k-numerictextbox").hide();
             $(allocatedHoursCell).find("input").prop('disabled', true).addClass("k-state-disabled");
             $(allocatedHoursCell).find("span.k-select").hide();
        }
         var implementedCell =  $(row).children().eq(9);
          $(implementedCell).find("input").prop('disabled', true);

    }

     function calculateRemainingAllocation(rowData, row){
                var assetGrid = $("#assetAllocationList").data("kendoGrid");;
                var dataItems = assetGrid.dataItems();
                var totalQuantity = 0,
                    totalPercentage = 0;
                    allocatedQuantityCell =  $(row).children().eq(6),
                    allocatedQPercentageCell =  $(row).children().eq(7),
                    allocatedHoursCell =  $(row).children().eq(8),
                    hours;
                if( rowData.Quantity > 1){
                    //var remainingQuantity = rowData.AllocatedQuantity;
                    //remainingQuantity = remainingQuantity < 0 ? 0 : remainingQuantity;
                    $(allocatedQPercentageCell).find("span.k-numerictextbox").hide();
                    rowData.AllocatedQuantity = rowData.AllocatedQuantity == null ? rowData.RemainingQuantity : rowData.AllocatedQuantity;
                    $(allocatedQuantityCell).find("span.k-numerictextbox").show();
                    $(allocatedQuantityCell).find("input").val(rowData.AllocatedQuantity);
                    hours = rowData.BudgtedHours * (rowData.AllocatedQuantity / rowData.Quantity);
                    $(allocatedHoursCell).find("input").prop('disabled', false).removeClass("k-state-disabled");
                    $(allocatedHoursCell).find("span.k-select").show();

                }else if( rowData.Quantity == 1 ){
                   // var remainingPercentage = 100 -  totalPercentage;
                    rowData.AllocatedPercentage = rowData.AllocatedPercentage == null ? Asset.Remaning_Percentage__c : rowData.AllocatedPercentage;
                    $(allocatedQuantityCell).find("span.k-numerictextbox").hide();
                    $(allocatedQPercentageCell).find("span.k-numerictextbox").show();
                    $(allocatedQPercentageCell).find("input").val(rowData.AllocatedPercentage);
                    var hours = rowData.BudgtedHours * (rowData.AllocatedPercentage / 100);
                    $(allocatedHoursCell).find("input").prop('disabled', true).addClass("k-state-disabled");
                    $(allocatedHoursCell).find("span.k-select").hide();
                }
                rowData.AllocatedHours = hours.toFixed(2);
                $(allocatedHoursCell).find("input").val(rowData.AllocatedHours);
                var implementedCell =  $(row).children().eq(9);
                $(implementedCell).find("input").prop('disabled', true);
     }


     function nonEditorAsset(container, options) {
         container.text(options.model[options.field]);
     }

     function gridDataboundAsset(e){
        $("#assetAllocationList").find(".k-hierarchy-cell, .k-hierarchy-col").hide();
        $("#assetAllocationList tbody tr .k-grid-edit").each(function () {
            var currentDataItem = $("#assetAllocationList").data("kendoGrid").dataItem($(this).closest("tr"));
            //Check in the current dataItem if the row is editable
            if (currentDataItem.Implemented == true && isManager == false) {
                $(this).remove();
            }
        });
         //Selects all delete buttons
         $("#assetAllocationList tbody tr a.k-grid-Delete").each(function () {
                var currentDataItem = $("#assetAllocationList").data("kendoGrid").dataItem($(this).closest("tr"));
                //Check in the current dataItem if the row is deletable
                if (currentDataItem.Implemented == true && isManager == false) {
                    $(this).remove();
                }
            })

     }


    function calculateBudgetedHours(e){
            if (e.action === "itemchange" && (e.field == "AllocatedPercentage" || e.field == "AllocatedQuantity")){
                    var model = e.items[0],
                        budgtedHours = model.BudgtedHours,
                        currentValue;
                        allocatedHoursInput = $("#assetAllocationList").find("tr[data-uid='" + model.uid + "'] td:eq(8)");
                  if(model.AllocatedPercentage > 0 ){
                      currentValue = (budgtedHours * (model.AllocatedPercentage / 100)).toFixed(2);
                      $(allocatedHoursInput).find("input").val(currentValue).prop('disabled', true).addClass("k-state-disabled");
                       $(allocatedHoursInput).find("span.k-select").hide();
                  }else if(model.AllocatedQuantity > 0 ){
                      currentValue = (budgtedHours * (model.AllocatedQuantity / model.Quantity)).toFixed(2);
                      if( model.Quantity == 0)
                        currentValue = 0;
                      $(allocatedHoursInput).find("input").val(currentValue).prop('disabled', false).removeClass("k-state-disabled");
                      $(allocatedHoursInput).find("span.k-select").show();
                  }
                  model.AllocatedHours = currentValue;
            }
     }

    function loadDetail(obj){
        var row = $(obj).parent().parent();
        var link = $(row).find("td.k-hierarchy-cell .k-icon");
        link.click();
        $(row).find("tr.k-detail-row").show();
        $(row).next().find(".k-hierarchy-cell").hide();
    }

    function loadChildGrid(e){
           if(currentObjectType === 'Asset'){
               detailProjects(e);
           } else if(currentObjectType === 'Project'){
                detailAssets(e);
           }
    }

    function detailProjects(e) {
         $("<div id='detailTable'/>").appendTo(e.detailCell).kendoGrid({
                    dataSource: {
                        autosync:true,
                        transport: {
                            read: function(options){
                                 AssetSubscriptionAllocationNewController.PhaseProjectDetails(
                                    e.data.Asset,
                                    'Asset',
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
                                    PhaseNumber : {from:"Phase__c", type:"string"},
                                }
                            }
                        }
                    },
                    scrollable: false,
                    sortable: true,
                    noRecords: true,
                    columns: [
                        { command: { text: "Select", click : selectProject}, title: "Action", width: "60px" },
                        { field: "ProjectNumber", title:"Phase Project Number", width: "110px" },
                        { field: "PhaseNumber", title:"Phase #", width: "110px" },
                        { field: "Summary", title:"Phase Project Summary", width: "200px" },
                        { field: "Status", title:"Project Status", width: "110px" }

                    ]
                });
    }

    function selectProject(e){
          var dataItem = this.dataItem($(e.currentTarget).closest("tr"));
          var detailGrid = this.wrapper;
          var parentRow = detailGrid.closest("tr.k-detail-row").prev("tr");
          var grid = $("#assetAllocationList").data("kendoGrid");
          var rowData = grid.dataItem(parentRow);
          if(rowData){
              rowData.ProjectNumber = dataItem.ProjectId;
              rowData.ProjectName = dataItem.ProjectNumber;
              rowData.ProjectPhase = dataItem.ProjectNumber + ' - ' + dataItem.Summary +  ' - ' + dataItem.PhaseNumber;
              //grid.dataSource.sync();

              var projectCell = $(parentRow).children().eq(5);
              var htmlContentProject = $('<a style="color:blue;cursor:pointer;" onClick="loadDetail(this);">' + rowData.ProjectPhase +'</a>');
              $(projectCell).html(htmlContentProject);
          }
          grid.collapseRow(parentRow);

    }

    function detailAssets(e) {
         $("<div id='detailTable'/>").appendTo(e.detailCell).kendoGrid({
                    dataSource: {
                        autosync:true,
                        transport: {
                            read: function(options){
                                 AssetSubscriptionAllocationNewController.AssetSubscriptionDetailsFromProjectPhase(
                                    e.data.ProjectNumber,
                                    'Asset',
                                    function(result,event){
                                      if (event.status) {
                                          if(result){
                                               options.success(JSON.parse(result));
                                               console.log('Asset Details =>' + JSON.stringify(result));
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
                                id: "AssetId",
                                fields: {
                                    AssetId: { from: "Id"},
                                    AssetName: {from:"Name", type: "string"},
                                    RemainingPercentage : {from:"Remaning_Percentage__c", type:"string"},
                                    RemainingQuantity : {from:"RemainingQuantity__c", type:"string"},
                                    RemainingHours : {from:"Remaining_Hours__c", type:"string"},
                                    Quantity:{from:'Quantity', type:"number"},
                                    BudgtedHours:{from:'Budgeted_Hours__c', type:"number"},
                                    QuantityOnHold:{from:'QuantityonHold__c', type:"number"},
                                    QuantityCancelled :{from:'QuantityCancelled__c', type:"number"}
                                }
                            }
                        }
                    },
                    scrollable: false,
                    sortable: true,
                    noRecords: true,
                    columns: [
                         {command: { text: "Select", click : selectAsset}, title: "Action", width: "60px" },
                        { field: "AssetName", title:"Asset", width: "110px" },
                        { field: "RemainingPercentage", title:"Remaining Percentage", width: "200px" },
                        { field: "RemainingQuantity", title:"Remaining Quantity", width: "110px" },
                        { field: "RemainingHours", title:"Remaining Hours", width: "110px" }

                    ]
                });
    }

    function selectAsset(e){
          var dataItem = this.dataItem($(e.currentTarget).closest("tr"));
          var detailGrid = this.wrapper;
          var parentRow = detailGrid.closest("tr.k-detail-row").prev("tr");
          var grid = $("#assetAllocationList").data("kendoGrid");
          var rowData = grid.dataItem(parentRow);
          if(rowData){
              rowData.Asset = dataItem.AssetId;
              rowData.AssetName = dataItem.AssetName;
              rowData.AllocatedPercentage = null;
              rowData.AllocatedQuantity = dataItem.RemainingQuantity;
              rowData.AllocatedHours = 0;
              rowData.Quantity = dataItem.Quantity;
              rowData.BudgtedHours = dataItem.BudgtedHours  == '' ? 0 : dataItem.BudgtedHours;
              rowData.QuantityOnHold = dataItem.QuantityOnHold  == '' ? 0 : dataItem.QuantityOnHold;
              rowData.QuantityCancelled = dataItem.QuantityCancelled  == '' ? 0 : dataItem.QuantityCancelled;
              rowData.RemainingQuantity = dataItem.RemainingQuantity  == '' ? 0 : dataItem.RemainingQuantity;
              var assetCell = $(parentRow).children().eq(2);
              var htmlContentProject = $('<a style="color:blue;cursor:pointer;" onClick="loadDetail(this);">' + dataItem.AssetName +'</a>');
              $(assetCell).html(htmlContentProject);
              calculateRemainingAllocation(rowData, parentRow);
          }
          grid.collapseRow(parentRow);
    }


