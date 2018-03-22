  function loadAssets(projId){
               var assetData = new kendo.data.DataSource({
                    autosync:true,
                    transport:{
                      read: function(options){
                               CancelAssetsSubsController.GetAllAssets(
                                   projId,
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
                            options.success();
                      }
                    },
                    schema:{
                        model: {
                            id: "Id",
                            fields: {
                                Id: { from: "RecordId"},
                                AssetName : {from:"Name", type:"string"},
                                Quantity :{from:"ContractQuantity", type:"number",defaultValue:0},
                                TotalAllocatedQuantity : {from:"TotalAllocatedQuantity", type:"number", defaultValue:0},
                                RemainingQuantity : {from:"RemainingQuantity", type:"number", defaultValue:0},
                                SalesPrice : {from:"SalesPrice", type:"number", defaultValue:0},
                                RemainingHours : {from:"RemainingHours", type:"number", defaultValue:0},
                                CancelledQuantity : {from:"CancelledQuantity", type:"number", defaultValue:0},
                                Department:{type:"string"},
                                RootCause:{type:"string"},
                                AdditonalDetails:{type:"string"}
                            }
                        }
                    }
               });

              $("#assetList").kendoGrid({
                  dataSource: assetData,
                  scrollable:  true,
                  noRecords: true,
                  height:400,
                  resizable: true,
                  sortable:true,
                 toolbar: [
                     {
                            template : '<a class="k-button k-primary" onclick="return cancelAssets();">Cancel Selected</a>'
                     }
                  ],
                  columns: [{
                                field:"Id",
                                hidden: true,
                                editable:false

                            },
                            {
                                title: 'Select All',
                                headerTemplate: "<input type='checkbox' id='asset-header-chb' class='k-checkbox header-checkbox'><label class='k-checkbox-label' for='asset-header-chb' style='font-weight:100;'>Select All</label>",
                                template: function (dataItem) {
                                    return "<input type='checkbox' id='" + dataItem.Id + "' class='k-checkbox row-checkbox'><label class='k-checkbox-label' for='" + dataItem.Id + "'></label>";
                                },
                                width: 80
                            },
                            {
                                field:"AssetName",
                                title:"Asset",
                                width:200,
                                template: '#{ #<a href="/#: data.Id #" target="_blank" name="AssetName">#= data.AssetName #</a># } #',
                            },
                            {
                                field:"Quantity",
                                title:"Contract Qtty.",
                                width:90
                            },
                            {
                                field:"RemainingQuantity",
                                title:"Remaining Qtty.",
                                width:90
                            },
                            {
                                field:"SalesPrice",
                                title:"Sales Price",
                                format:"{0:c}",
                                width:75
                            },
                            {
                                field:"RemainingHours",
                                title:"Remaining Hrs.",
                                width:90

                            },
                            {
                                title: 'Department',
                                template: kendo.template($("#departmentTemplate").html()),
                                width: 200
                            },
                            {
                                title: 'Root Cause',
                                template: kendo.template($("#rootCauseTemplate").html()),
                                width: 200
                            },
                            {
                                title: 'Additional Details',
                                template: function (dataItem) {
                                    return "<input type='textArea' class='form-control additionalDetails additonalDetail-" + dataItem.Id  + "' style='width:80%;'>";
                                },
                                width: 200
                            }
                  ]
              });
              checkedIds = {};
              var assetGrid = $("#assetList").data("kendoGrid");
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
                grid = $("#assetList").data("kendoGrid"),
                dataItem = grid.dataItem(row),
                remainingQuantity = dataItem.RemainingQuantity + dataItem.CancelledQuantity;

            checkedIds[dataItem.id + '~' + remainingQuantity] = checked;

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

        function cancelAssets(){
                    $('#loading').modal({
                         backdrop: 'static',
                         keyboard: false
                    });
                    $('#loading').modal('show');
                    var UpdateList = [];
                    for(var i in checkedIds){
                        if(checkedIds[i]){
                            var assetId = i.substring(0, i.indexOf('~')),
                                cancelQuantity = i.substring(i.indexOf('~') + 1, i.length),
                                department = $("select.department-" + assetId).val(),
                                rootCause = $("select.rootCause-" + assetId).val();
                            var additionalDetails = $("input.additonalDetail-" + assetId).val();
                            if(department == '' || rootCause == '' || additionalDetails == ''){
                               displayError('Department, Root Cause and Additional Details are required field while cancelling an asset');
                               $('#loading').modal('hide');
                              return;
                            }else{
                                UpdateList.push({
                                    Id : assetId,
                                    QuantityCancelled__c : cancelQuantity,
                                    Department_Responsible__c : department,
                                    Root_Cause__c : rootCause,
                                    Additional_Detail__c : additionalDetails
                                });
                            }


                        }
                    }
                    console.log(JSON.stringify(UpdateList));

                    if(UpdateList.length < 1){
                        displayError('Please select atleast one Asset for Cancellation');
                         $('#loading').modal('hide');
                    }else{
                        CancelAssetsSubsController.CancelAllAssets(
                          JSON.stringify(UpdateList),
                          function(result,event){
                              if (event.status) {
                               if(result == 'Success'){
                                    $('#loading').modal('hide');
                                     $("#assetList").data("kendoGrid").destroy();
                                      loadAssets("{!ParentProjectId}");
                                      showSuccess('Cancelled successfully.')

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
                    }
        }

