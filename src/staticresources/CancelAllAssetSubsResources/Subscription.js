 function loadSubs(projId){
               var subsData = new kendo.data.DataSource({
                    autosync:true,
                    transport:{
                      read: function(options){
                               CancelAssetsSubsController.GetAllSubscriptions(
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
                                SubscriptionName : {from:"Name", type:"string"},
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

              $("#subsList").kendoGrid({
                  dataSource: subsData,
                  scrollable:  true,
                  noRecords: true,
                  height:400,
                  resizable: true,
                  sortable:true,
                  dataBound:function(e){
                     $("#subsList").find('div.k-grid-content').css("height", "312px");
                  },
                  toolbar: [
                     {
                            template : '<a class="k-button k-primary" onclick="return cancelSubs();">Cancel Selected</a>'
                     }
                  ],
                  columns: [{
                                field:"Id",
                                hidden: true,
                                editable:false

                            },
                            {
                                title: 'Select All',
                                headerTemplate: "<input type='checkbox' id='subs-header-chb' class='k-checkbox header-checkbox'><label class='k-checkbox-label' for='subs-header-chb' style='font-weight:100;'>Select All</label>",
                                template: function (dataItem) {
                                    return "<input type='checkbox' id='" + dataItem.Id + "' class='k-checkbox subs-row-checkbox'><label class='k-checkbox-label' for='" + dataItem.Id + "'></label>";
                                },
                                width: 80
                            },
                            {
                                field:"SubscriptionName",
                                title:"Subscription",
                                width:200,
                                template: '#{ #<a href="/#: data.Id #" target="_blank" name="SubscriptionName">#= data.SubscriptionName #</a># } #',
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
                                template: kendo.template($("#departmentTemplateSubs").html()),
                                width: 200
                            },
                            {
                                title: 'Root Cause',
                                template: kendo.template($("#rootCauseTemplateSubs").html()),
                                width: 200
                            },
                            {
                                title: 'Additional Details',
                                template: function (dataItem) {
                                    return "<input type='textArea' class='form-control additionalDetailsSub additonalDetail-" + dataItem.Id  + "' style='width:80%;'>";
                                },
                                width: 200
                            }
                  ]
              });
                  subsCheckIds = {};
              var subsGrid = $("#subsList").data("kendoGrid");
              //bind click event to the checkbox
              subsGrid.table.on("click", ".subs-row-checkbox", selectRowSubs);

              $('#subs-header-chb').change(function (ev) {
                  var checked = ev.target.checked;
                  $('.subs-row-checkbox').each(function (idx, item) {
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
        var subsCheckIds = {};
        function selectRowSubs(){
            var checked = this.checked,
                row = $(this).closest("tr"),
                grid = $("#subsList").data("kendoGrid"),
                dataItem = grid.dataItem(row),
                remainingQuantity = dataItem.RemainingQuantity + dataItem.CancelledQuantity;

            subsCheckIds[dataItem.id + '~' + remainingQuantity] = checked;

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
                $("#subs-header-chb")[0].checked = false;
            }
        }

         function cancelSubs(){
            $('#loading').modal({
                 backdrop: 'static',
                 keyboard: false
            });
            $('#loading').modal('show');
            var UpdateList = [];
            for(var i in subsCheckIds){
                if(subsCheckIds[i]){
                    var subsId = i.substring(0, i.indexOf('~')),
                        cancelQuantity = i.substring(i.indexOf('~') + 1, i.length),
                        department = $("select.department-" + subsId).val(),
                        rootCause = $("select.rootCause-" + subsId).val();
                    var additionalDetails = $("input.additonalDetail-" + subsId).val();
                    if(department == '' || rootCause == '' || additionalDetails == ''){
                       displayError('Department, Root Cause and Additional Details are required field while cancelling a subscription');
                       $('#loading').modal('hide');
                       return;
                    }else{
                        UpdateList.push({
                            Id : subsId,
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
                displayError('Please select atleast one subscription for Cancellation');
                 $('#loading').modal('hide');
            }else{
               CancelAssetsSubsController.CancelAllSubs(
                  JSON.stringify(UpdateList),
                  function(result,event){
                      if (event.status) {
                       if(result == 'Success'){
                            $('#loading').modal('hide');
                             $("#subsList").data("kendoGrid").destroy();
                              loadSubs("{!ParentProjectId}");
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
