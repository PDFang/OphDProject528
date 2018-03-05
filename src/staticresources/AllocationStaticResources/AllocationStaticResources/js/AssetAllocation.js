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
                                                   var records = JSON.parse(result);
                                                   showHideAddButton(records[0]);
                                              }else{
                                                  options.success('');
                                                  showHideAddButton('');
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
                                    defaultValue:0,
                                     validation : {
                                        quantityValidation : function(input){
                                            var parentRow = $(input).parents("tr:first");
                                            var grid = $("#assetAllocationList").data("kendoGrid");
                                            var rowData = grid.dataItem(parentRow),
                                                allocatedQuantityVal = rowData.AssetAllocationName == '' ? 0 : rowData.AllocatedQuantity;

                                             if(!rowData){
                                                 input.attr("data-quantityValidation-msg", "Please select an asset");
                                                 return false;
                                             }
                                             if(input.val() == 0 && input.is("[name='AllocatedQuantity']") && rowData.Quantity > 1){
                                                input.attr("data-quantityValidation-msg", "Allocated Quantity cannot be zero");
                                                return false;
                                            }
                                             if(Number(input.val()) > (Number(rowData.RemainingQuantity) + Number(allocatedQuantityVal)) && input.is("[name='AllocatedQuantity']")){
                                                input.attr("data-quantityValidation-msg", 'Cannot allocate more than “Contract Quantity”');
                                                return false;
                                            }
                                             if(Number(input.val()) > 1 && input.is("[name='AllocatedQuantity']") && rowData.Quantity == 1){
                                                    input.attr("data-quantityValidation-msg", 'Allocated Quantity cannot be more than 1');
                                                    return false;
                                            }
                                            if(input.is("[name='AllocatedQuantity']") && rowData.Quantity > 1 && Number(input.val()) % 1 != 0){
                                                 input.attr("data-quantityValidation-msg", 'Decimal values are not allowed if the Asset Quantity is greater than 1');
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
                                    editable:true
                                },
                                AllocatedHours:{from: "AllocatedHours", type:"number",  nullable: true, editable:true, defaultValue:0},
                                Quantity :{from:"Quantity", type:"number",defaultValue:0},
                                BudgtedHours :{from:"BudgtedHours", type:"number", defaultValue:0},
                                Implemented : {from:"Implemented", type:"boolean"},
                                QuantityOnHold : {from:"QuantityOnHold", type:"number", defaultValue:0},
                                QuantityCancelled : {from:"QuantityCancelled", type:"number", defaultValue:0},
                                RemainingQuantity : {from:"RemainingQuantity", type:"number", defaultValue:0},
                                OnHold : {from:"OnHold", type:"boolean"}

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
          height:600,
          edit: addDuplicateRowAsset,
          dataBound : gridDataboundAsset,
          detailInit: loadChildGrid,
          cancel : hideChildProjects,
          resizable: true,
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
                        width:300,
                        editor:nonEditorAsset,
                        template: '#{ #<a href="/#: data.Asset #" target="_blank" name="AssetName">#= data.AssetName #</a># } #',
                    },
                    {
                        field:"AssetAllocationName",
                        title:"Allocation",
                        width:150,
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
                        title:"Allocated %",
                        editable:true
                    },
                    {
                        field:"AllocatedHours",
                        title:"Allocated Hours"
                    },
                    {
                        field:"Implemented",
                        title:"Impl",
                        template: '<input type="checkbox"  "# if (data.Implemented) { # checked="checked" # } #"  disabled "/>',
                        width:75

                    },
                    {
                        field:"OnHold",
                        title:"On Hold",
                        template: '<input type="checkbox"  "# if (data.OnHold) { # checked="checked" # } #" disabled="true" "/>',
                        width:75

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
                                                  if(result == 'success'){
                                                       grid.dataSource.remove(data);
                                                       reloadDetails();
                                                       //  getSObjType();
                                                       $('#loading').modal('hide');
                                                    }else{
                                                    displayError(result);
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
                   $('<a style="color:blue;cursor:pointer;" class="projectSelector" onclick="loadDetail(this);">Select Projects </a>').appendTo(projectCell);
                   loadDetail($("a.projectSelector"));
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
                   var implementedCell = e.container.contents()[9];
                   $(implementedCell).find("input").prop('disabled', true);

                   var firstCell = e.container.contents()[2];
                   $('<a style="color:blue;cursor:pointer;"  class="assetSelector" onclick="loadDetail(this);">Select Assets </a>').appendTo(firstCell);
                   loadDetail($("a.assetSelector"));
               }
                var buttonCell = e.container.contents()[11];
                $(buttonCell).find("a.k-primary").html('<span class="k-icon k-i-update"></span> Add');
           }else{
               enableAllocation(e.model, e.container);
           }
            $("#assetAllocationList").find(".k-hierarchy-cell, .k-hierarchy-col").hide();
    }

    function enableAllocation(rowData, row){
        var allocatedHoursCell =  $(row).children().eq(8);
        var allocatedQPercentageCell =  $(row).children().eq(7);
        $(allocatedQPercentageCell).find("input").prop('disabled', true).addClass("k-state-disabled");
        $(allocatedHoursCell).find("input").prop('disabled', true).addClass("k-state-disabled");
        $(allocatedHoursCell).find("span.k-select").hide();
        $(allocatedQPercentageCell).find("span.k-select").hide();
        var implementedCell =  $(row).children().eq(9);
        $(implementedCell).find("input").prop('disabled', true);

    }

     function calculateRemainingAllocation(rowData, row){
                var assetGrid = $("#assetAllocationList").data("kendoGrid");;
                var dataItems = assetGrid.dataItems();
                var totalQuantity = 0,
                    totalPercentage = 0,
                    allocatedQuantityCell =  $(row).children().eq(6),
                    allocatedQPercentageCell =  $(row).children().eq(7),
                    allocatedHoursCell =  $(row).children().eq(8),
                    hours;

                rowData.AllocatedQuantity = rowData.AllocatedQuantity == null ? rowData.RemainingQuantity : rowData.AllocatedQuantity;
                $(allocatedQuantityCell).find("span.k-numerictextbox").show();
                $(allocatedQuantityCell).find("input").val(rowData.AllocatedQuantity);
                hours = (rowData.BudgtedHours * (rowData.AllocatedQuantity / rowData.Quantity)).toFixed(2);
                $(allocatedHoursCell).find("input").prop('disabled', true).addClass("k-state-disabled");
                $(allocatedQPercentageCell).find("input").prop('disabled', true).addClass("k-state-disabled");
                $(allocatedHoursCell).find("span.k-select").hide();
                $(allocatedQPercentageCell).find("span.k-select").hide();
                rowData.AllocatedPercentage = (100 * (rowData.AllocatedQuantity / rowData.Quantity)).toFixed(2);
                  $(allocatedQPercentageCell).find("input").val(rowData.AllocatedPercentage);
                rowData.AllocatedHours = hours;
                $(allocatedHoursCell).find("input").val(rowData.AllocatedHours);
                var implementedCell =  $(row).children().eq(9);
                $(implementedCell).find("input").prop('disabled', true);
     }


     function nonEditorAsset(container, options) {
         container.text(options.model[options.field]);
     }

     function gridDataboundAsset(e){
        $("#assetAllocationList").find(".k-hierarchy-cell, .k-hierarchy-col").hide();
        var projStatus = '';
        if(Project)
            projStatus = Project.Status;
        $("#assetAllocationList tbody tr .k-grid-edit").each(function () {
            var currentDataItem = $("#assetAllocationList").data("kendoGrid").dataItem($(this).closest("tr"));
            //Check in the current dataItem if the row is editable || projStatus == 'Cancelled' || projStatus == 'Closed' || projStatus == 'Suspended'
            if ((currentDataItem.Implemented == true && isManager == false) ) {
                $(this).remove();
            }
            else if((projectPhaseStatus == 'Cancelled' || projectPhaseStatus == 'Closed' || projectPhaseStatus == 'Suspended') && isManager == false){
                                $(this).remove();
            }
        });
         //Selects all delete buttons
         $("#assetAllocationList tbody tr a.k-grid-Delete").each(function () {
                var currentDataItem = $("#assetAllocationList").data("kendoGrid").dataItem($(this).closest("tr"));
                //Check in the current dataItem if the row is deletable || projStatus == 'Cancelled' || projStatus == 'Closed' || projStatus == 'Suspended'
                if ((currentDataItem.Implemented == true && isManager == false) ) {
                    $(this).remove();
                }
                else if((projectPhaseStatus == 'Cancelled' || projectPhaseStatus == 'Closed' || projectPhaseStatus == 'Suspended') && isManager == false){
                    $(this).remove();
                }

            })

        $("#assetAllocationList").find('div.k-grid-content').css("height", "520px");
     }


    function calculateBudgetedHours(e){
            if (e.action === "itemchange" && e.field == "AllocatedQuantity"){
                  var model = e.items[0],
                       budgtedHours = model.BudgtedHours,
                       currentValue;
                       allocatedHoursInput = $("#assetAllocationList").find("tr[data-uid='" + model.uid + "'] td:eq(8)"),
                       allocatedQPercentageInput = $("#assetAllocationList").find("tr[data-uid='" + model.uid + "'] td:eq(7)");

                  currentValue = (budgtedHours * (model.AllocatedQuantity / model.Quantity)).toFixed(2);
                      var percentage = (100*(model.AllocatedQuantity / model.Quantity)).toFixed(2);
                  if( model.Quantity == 0)
                    currentValue = 0;
                  $(allocatedHoursInput).find("input").val(currentValue).prop('disabled', true).addClass("k-state-disabled");
                  $(allocatedQPercentageInput).find("input").val(percentage).prop('disabled', true).addClass("k-state-disabled");
                  $(allocatedHoursInput).find("span.k-select").hide();
                  $(allocatedQPercentageInput).find("span.k-select").hide();
                  model.AllocatedHours = currentValue;
                  model.AllocatedPercentage = percentage;
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
                    scrollable: true,
                    height:400,
                    sortable: true,
                    noRecords: true,
                    dataBound:onProjDataBound,
                    columns: [
                        { command: { text: "Select", click : selectProject}, title: "Action", width: "60px" },
                        { field: "ProjectNumber", title:"Phase Project Number", width: "110px" },
                        { field: "PhaseNumber", title:"Phase #", width: "110px" },
                        { field: "Summary", title:"Phase Project Summary", width: "200px" },
                        { field: "Status", title:"Project Status", width: "110px" }

                    ]
                });
    }

     var wrapper, header, parentGrid;
    function onProjDataBound(){
            wrapper = this.wrapper,
            header = wrapper.find(".k-grid-header");
            parentGrid =  $("#assetAllocationList").find('div.k-grid-content').first();
            resizeFixed();
            $(window).resize(resizeFixed);
            parentGrid.scroll(scrollFixed);
           $(window).scroll(function(){
              if($(header).hasClass("fixed-header")){
                 var headerTop = $("#assetAllocationList").find('div.k-grid-content').first().offset().top - $(window).scrollTop();
                  header.css("top", headerTop);
              }
           });
    }

     function resizeFixed() {
      var paddingRight = parseInt(header.css("padding-right"));
      header.css("width", wrapper.width() - paddingRight);
    }

    function scrollFixed() {
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
                    scrollable: true,
                    height:400,
                    sortable: true,
                    noRecords: true,
                    dataBound:onAssetDataBound,
                    toolbar:[
                        {
                            template : '<a class="k-button" href="\\#" onclick="return updateAllocation();">Allocate Selected</a>'
                        }
                    ],
                    columns: [
                         {
                            title: 'Select All',
                            headerTemplate: "<input type='checkbox' id='asset-header-chb' class='k-checkbox header-checkbox'><label class='k-checkbox-label' for='asset-header-chb' style='top:-10px;'></label>",
                            template: function (dataItem) {
                                return "<input type='checkbox' id='" + dataItem.AssetId + "' class='k-checkbox row-checkbox'><label class='k-checkbox-label' for='" + dataItem.AssetId + "'></label>";
                            },
                            width: 80
                        },
                         {command: { text: "Select", click : selectAsset}, title: "Action", width: "60px" },
                        { field: "AssetName", title:"Asset", width: "300px" },
                         { field: "RemainingQuantity", title:"Remaining Quantity", width: "110px" },
                        { field: "RemainingPercentage", title:"Remaining Percentage", width: "110px" },
                        { field: "RemainingHours", title:"Remaining Hours", width: "110px" }

                    ]
                });

        var assetGrid = $("#detailTable").data("kendoGrid");
        //bind click event to the checkbox
        assetGrid.table.on("click", ".row-checkbox", selectRow);

        $('#asset-header-chb').change(function (ev) {
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


    var checkedIds = {};

    //on click of the checkbox:
    function selectRow() {
        var checked = this.checked,
            row = $(this).closest("tr"),
            grid = $("#detailTable").data("kendoGrid"),
            dataItem = grid.dataItem(row);

        checkedIds[dataItem.id] = checked;

        if (checked) {
            //-select the row
            row.addClass("k-state-selected");

            var checkHeader = true;

            $.each(grid.items(), function (index, item) {
                if (!($(item).hasClass("k-state-selected"))) {
                    checkHeader = false;
                }
            });

            $("#asset-header-chb")[0].checked = checkHeader;
        } else {
            //-remove selection
            row.removeClass("k-state-selected");
            $("#asset-header-chb")[0].checked = false;
        }
    }

    function updateAllocation(){
        $('#loading').modal({
             backdrop: 'static',
             keyboard: false
        });
        $('#loading').modal('show');
        var checked = [];
        for (var i in checkedIds) {
            if (checkedIds[i]) {
                checked.push(i);
            }
        }

        if(checked.length > 0){
            AssetSubscriptionAllocationNewController.SaveAllAllocation(
                  JSON.stringify(checked),
                  null ,
                  Project.Id,
                  function(result,event){
                    if (event.status) {
                       //var returnResult = JSON.parse(result);
                       if(result == 'Success'){
                            $('#loading').modal('hide');
                             $("#assetAllocationList").data("kendoGrid").destroy();
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

     function onAssetDataBound(){
                wrapper = this.wrapper,
                header = wrapper.find(".k-grid-header");
                parentGrid =  $("#assetAllocationList").find('div.k-grid-content').first();
                resizeFixed();
                $(window).resize(resizeFixed);
                parentGrid.scroll(scrollFixed);
                $(window).scroll(function(){
                  if($(header).hasClass("fixed-header")){
                     var headerTop = $("#assetAllocationList").find('div.k-grid-content').first().offset().top - $(window).scrollTop();
                      header.css("top", headerTop);
                  }
               });

            var view = this.dataSource.view();
           for (var i = 0; i < view.length; i++) {
               if (checkedIds[view[i].id]) {
                   this.tbody.find("tr[data-uid='" + view[i].uid + "']")
                       .addClass("k-state-selected")
                       .find(".k-checkbox")
                       .attr("checked", "checked");
               }
           }
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
              rowData.AllocatedPercentage = dataItem.RemainingPercentage;
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




