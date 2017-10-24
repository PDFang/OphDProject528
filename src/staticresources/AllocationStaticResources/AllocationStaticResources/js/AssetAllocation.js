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
                                        displayError('Please Select an Asset before save.');
                                 else if(currentObjectType == 'Asset')
                                         displayError('Please Select a Project before save.');
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
                                                        var grid = $("#assetAllocationList").data("kendoGrid");
                                                       grid.destroy();
                                                        getSObjType();
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
                            id: "AssetAllocationId",
                            fields: {
                                AssetAllocationId: { from: "AssetAllocationId"},
                                Asset: {from:"Asset", type: "string"},
                                AssetName : {from:"AssetName", type:"string"},
                                AssetAllocationName : {from:"AssetAllocationName", type:"string"},
                                ProjectNumber:{from:"ProjectNumber",type:"string"},
                                ProjectName:{from:"ProjectName",type:"string"},
                                ProjectPhase : {from:"ProjectPhase", type: "string"},
                                AllocatedQuantity:{from: "AllocatedQuantity", type:"number", nullable: true, editable:true},
                                AllocatedPercentage:{
                                    from: "AllocatedPercentage",
                                    type:"number",
                                    nullable: true,
                                    editable:true,
                                    validation : {
                                        percentageValidation : function(input){
                                            if(input.val() > 100 && input.is("[name='AllocatedPercentage']")){
                                                input.attr("data-percentageValidation-msg", " Invalid Percentage");
                                                return false;
                                            }
                                        return true;
                                        }
                                    }
                                },
                                AllocatedHours:{from: "AllocatedHours", type:"number",  nullable: true, editable:true},
                                Quantity :{from:"Quantity", type:"number"},
                                BudgtedHours :{from:"BudgtedHours", type:"number"}
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
          scrollable: true,
          noRecords: true,
          height: 350,
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
                        field:"AssetAllocationId",
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
                        template: '#{ #<a href="/#: data.AssetAllocationId #" target="_blank" >#= data.AssetAllocationName #</a># } #',
                    },
                    {
                        field:"ProjectName",
                        title:"Project",
                        editor:nonEditorAsset,
                        template: '#{ #<a href="/#: data.ProjectNumber #" target="_blank" >#= data.ProjectName #</a># } #',
                    },
                    {
                        field:"ProjectPhase",
                        title:"Project Phase",
                        editor:nonEditorAsset,
                        filterable:true
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
                                       AssetSubscriptionAllocationNewController.DeleteAllocation(
                                           data.AssetAllocationId,
                                           'Asset',
                                           function(result,event){
                                               if (event.status) {
                                                  var returnResult = result;
                                                  if(result != 'Failed'){
                                                       grid.dataSource.remove(data);
                                                    }else{
                                                    displayError('Delete Unsuccessful.');
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
                   var projectCell = e.container.contents()[4];
                   $('<a style="color:blue;cursor:pointer;" onClick="loadDetail(this);">Select Projects </a>').appendTo(projectCell);
                   e.model.Quantity = Asset.Quantity;
                   e.model.BudgtedHours = Asset.Budgeted_Hours__c;
                   calculateRemainingAllocation(e.model, e.container);

               }else if(currentObjectType == 'Project'){
                   e.model.ProjectNumber = Project.Id;
                   e.model.ProjectName = Project.Name;
                   e.model.ProjectPhase = Project.Project_Phase_Allocation__c;
                   var projectCell = e.container.contents()[4];
                   $('<a href="/' +  e.model.ProjectNumber + '" target="_blank">' + e.model.ProjectName +'</a>').appendTo(projectCell);
                   var phaseCell = e.container.contents()[5];
                   $('<span>' +  e.model.ProjectPhase + '</span>').appendTo(phaseCell);

                   var firstCell = e.container.contents()[2];
                   $('<a style="color:blue;cursor:pointer;" onClick="loadDetail(this);">Select Assets </a>').appendTo(firstCell);
               }
                var buttonCell = e.container.contents()[9];
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

                for(var i = 0; i < dataItems.length; i++){
                    if(rowData.Quantity > 1 && dataItems[i].get("AllocatedQuantity") != null && dataItems[i].get("Asset") ==  rowData.Asset){
                         totalQuantity += Number(dataItems[i].get("AllocatedQuantity"));

                    }else if(rowData.Quantity == 1 && dataItems[i].get("AllocatedPercentage") != null && dataItems[i].get("Asset") ==  rowData.Asset){
                        totalPercentage += Number(dataItems[i].get("AllocatedPercentage"));
                    }
                }


                if( rowData.Quantity > 1){
                    var remainingQuantity = rowData.Quantity -  totalQuantity;
                    $(allocatedQPercentageCell).find("span.k-numerictextbox").hide();
                    rowData.AllocatedQuantity = remainingQuantity;
                    $(allocatedQuantityCell).find("span.k-numerictextbox").show();
                    $(allocatedQuantityCell).find("input").val(remainingQuantity);
                    hours = rowData.BudgtedHours * (remainingQuantity / rowData.Quantity);
                    $(allocatedHoursCell).find("input").prop('disabled', false).removeClass("k-state-disabled");
                    $(allocatedHoursCell).find("span.k-select").show();

                }else if( rowData.Quantity == 1 ){
                    var remainingPercentage = 100 -  totalPercentage;
                    rowData.AllocatedPercentage = remainingPercentage;
                    $(allocatedQuantityCell).find("span.k-numerictextbox").hide();
                    $(allocatedQPercentageCell).find("span.k-numerictextbox").show();
                    $(allocatedQPercentageCell).find("input").val(remainingPercentage);
                    var hours = rowData.BudgtedHours * (remainingPercentage / 100);
                    $(allocatedHoursCell).find("input").prop('disabled', true).addClass("k-state-disabled");
                    $(allocatedHoursCell).find("span.k-select").hide();
                }
                rowData.AllocatedHours = hours.toFixed(2);
                $(allocatedHoursCell).find("input").val(rowData.AllocatedHours);
     }


     function nonEditorAsset(container, options) {
         container.text(options.model[options.field]);
     }

     function gridDataboundAsset(e){
        $("#assetAllocationList").find(".k-hierarchy-cell, .k-hierarchy-col").hide();
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
                                    function(result,event){
                                      if (event.status) {
                                          if(result){
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
                                    Status : {from:"ProjectStatus__c", type:"string"}
                                }
                            }
                        }
                    },
                    scrollable: false,
                    sortable: true,
                    noRecords: true,
                    columns: [
                        { command: { text: "Select", click : selectProject}, title: "Action", width: "60px" },
                        { field: "ProjectNumber", width: "110px" },
                        { field: "Summary", title:"Project Summary", width: "200px" },
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
              rowData.ProjectPhase = dataItem.ProjectNumber + ' - ' + dataItem.Summary;
              //grid.dataSource.sync();

              var projectCell = $(parentRow).children().eq(4);
              var htmlContentProject = $('<a style="color:blue;cursor:pointer;" onClick="loadDetail(this);">' + dataItem.ProjectNumber +'</a>');
              $(projectCell).html(htmlContentProject);
              var projectPhaseCell = $(parentRow).children().eq(5);
              var htmlProjectPhase = $('<span> ' + rowData.ProjectPhase +'</span>');
              $(projectPhaseCell).html(htmlProjectPhase);
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
                                    BudgtedHours:{from:'Budgeted_Hours__c', type:"number"}
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
              rowData.AllocatedQuantity = null;
              rowData.AllocatedHours = 0;
              rowData.Quantity = dataItem.Quantity;
              rowData.BudgtedHours = dataItem.BudgtedHours;
              var assetCell = $(parentRow).children().eq(2);
              var htmlContentProject = $('<a style="color:blue;cursor:pointer;" onClick="loadDetail(this);">' + dataItem.AssetName +'</a>');
              $(assetCell).html(htmlContentProject);
              calculateRemainingAllocation(rowData, parentRow);
          }
          grid.collapseRow(parentRow);
    }


