// GanttProjectListJS
//Global variables
    var program = 'Foundation',
        teams = [],
        changedProjects = [],
        sortableGrid1,
        sortableGrid2,
        editMode,
        dataItem,
        initial,
        historyId,
        timeoutvar,
        noActionTimeoutvar;

    // to search the Un-prioritized list
    function FilterUnprioritized (val) {
          var grid = $("#listView").data("kendoGrid");
          grid.dataSource.query({
            filter:{
              logic:"or",
              filters:[
                {field:"title", operator:"contains",value:val}
                ]
             }
          });


      }

    //draw the un-prioritized list
    function DrawUnprioritized(projName) {

        var columnsRequested = [];
        if(projName == 'Global')
              $("p#nonprioritized").text(projectType + ' Projects not Globally Prioritized');
        else
             $("p#nonprioritized").text(projectType + ' Projects not Channel Prioritized');
        var projects = new kendo.data.DataSource({
                         transport: {
                             read: function(options){
                                 GanttProjectPriotizationListController.GetUnpriortizedProjects(
                                     projName,
									 projectType,
                                     function(result,event){
                                       options.success(JSON.parse(result));
                                     },
                                     {escape: false}
                                 );
                            },
                            update: function(options){
                                console.log('update');
                                options.success();
                            }
                         },
                         schema: {
                             model: {
                              fields: {
                                id: { from: "ProjectId", type: "string" },
                                orderId: { from: "Priority", type: "number" },
                                title: { from: "ProjectName", defaultValue: "", type: "string" },
                                status: { from: "ProjectStatus", defaultValue: "", type: "string" },
                                requestedDeliveryDt: { from: "RequestedDeliveryDate", defaultValue: "", type: "string" },
                                expecteddDeliveryDt: { from: "ExpectedDeliveryDate", defaultValue: "", type: "string" },
                                owner: { from: "Owner", type: "string" },
								projectOwner: { from: "ProjectOwner", type: "string" },
								businessAnalyst: { from: "BusinessAnalyst", type: "string" },
								tshirtSize: { from: "TshirtSize", type: "string" },
								requestType: { from: "RequestType", type: "string" },
                                projectType: { from: "ProjectType", type: "string" },
                                channel: { from: "ProductChannel", type: "string" },
                                otherPriority: { from: "OtherPriority", type: "number" },
								DeliveryChannel: {from: "DeliveryChannel",defaultValue: "",nullable: "false", type:"string"},
                                RequestChannel: {from: "RequestChannel",defaultValue: "",nullable: "false", type:"string"},
                                CreatedDate:{from:"CreatedDate", type:"date"}
                              }
                             }
                         }
                     });
        /* if(projName == 'Global') {
              columnsRequested.push({ field: "otherPriority", title: "Channel Governance Priority",  editable: false, sortable: true,width: "30px"});
              columnsRequested.push({ field: "channel", title: "Primary Channel",  editable: false, sortable: true, width: "auto"});
		}
		else{
            columnsRequested.push({ field: "otherPriority", title: "Global Governance Priority",  editable: false, sortable: true,width: "30px"});
        }*/
        columnsRequested.push({ field: "title", title: "Project", editable: false, sortable: true, width: "400px"});
		var titleIndex = columnsRequested.length;
		
        columnsRequested.push({ field: "status", title: "Status",  editable: false, sortable: true, width: "auto"});
		
		if(projectType == 'IT'){
			columnsRequested.push({ field: "channel", title: "Primary Program",  editable: false, sortable: true, width: "auto"});
            columnsRequested.push({ field: "expecteddDeliveryDt", title: "Expected Delivery Date", template: '#= kendo.toString(expecteddDeliveryDt, "MM/dd/yyyy") #', sortable: true, width: "auto"});
		}			
			
        columnsRequested.push({ field: "CreatedDate", title: "Created Date", template: '#= kendo.toString(CreatedDate, "MM/dd/yyyy") #', sortable: true, width: "auto"});


        var grid = $("#listView").kendoGrid({
            dataSource: projects,
            scrollable: false,
            resizable: true,
            sortable:true,
            dataBound : insertNoRecordsRow,
            columns: columnsRequested,
            selectable: true,
            change : onChange
          }).data("kendoGrid");

          // Kendo tooltip
        $("#listView").kendoTooltip({
              filter: "td:nth-child("+ titleIndex +")", //this filter selects the Project Title column's cells
              position: "right",
              width: 320,
              content: function(e){
                var proj =  e.target[0].parentNode.cells[0].innerHTML;
                if (proj != undefined)
                {
                    //var dataItem = grid.dataSource.getByUid(e.item.data("uid"));

                    var dataItem = $("#listView").data("kendoGrid").dataItem(e.target.closest("tr"));
                    if(dataItem){
                        var template = $('#ToolTipTemplate').clone().html();
                        var replace;
                        var replaceText;
                        var content = '';
                        replace =  template.replace("#ReplaceTitle#", "Owner");
						replace =  replace.replace("#ReplaceValue#", dataItem.owner == null ? '' : dataItem.owner );
						content = content + replace;
						replace =  template.replace("#ReplaceTitle#", "Project Owner");
						replace =  replace.replace("#ReplaceValue#", dataItem.projectOwner == null ? '' : dataItem.projectOwner);
						content = content + replace;
						replace =  template.replace("#ReplaceTitle#", "Business Analyst");
						replace =  replace.replace("#ReplaceValue#", dataItem.businessAnalyst == null ? '' : dataItem.businessAnalyst);
						content = content + replace;
						if(projectType == 'PMO'){
							replace =  template.replace("#ReplaceTitle#", "Requested Delivery Date");
							replace =  replace.replace("#ReplaceValue#", dataItem.requestedDeliveryDt == null ? '' : dataItem.requestedDeliveryDt);
							content = content + replace;
							replace =  template.replace("#ReplaceTitle#", "Primary Program");
							replace =  replace.replace("#ReplaceValue#", dataItem.channel == null ? '': dataItem.channel );
							content = content + replace;
							replace =  template.replace("#ReplaceTitle#", "Requested By");
							replace =  replace.replace("#ReplaceValue#", dataItem.RequestChannel == null ? '' : dataItem.RequestChannel);
							content = content + replace;
						}else{
							replace =  template.replace("#ReplaceTitle#", "T-Shirt Size");
							replace =  replace.replace("#ReplaceValue#", dataItem.tshirtSize == null ? '' : dataItem.tshirtSize);
							content = content + replace;
							replace =  template.replace("#ReplaceTitle#", "Primary Program");
							replace =  replace.replace("#ReplaceValue#", dataItem.channel == null ? '': dataItem.channel );
							content = content + replace;
							replace =  template.replace("#ReplaceTitle#", "Created Date");
                            replace =  replace.replace("#ReplaceValue#", dataItem.CreatedDate == null ? '' : kendo.toString(dataItem.CreatedDate, "MM/dd/yyyy"));
                            content = content + replace;
						}
						return content;
                    }

                  return null;
                 }

              }
            }).data("kendoTooltip");
        sortableGrid1 = grid;
    }

    //draw the prioritized list
    function DrawPrioritized(projName) {
        var columnsRequested = [];
        if(projName == 'Global')
    	      $("p#prioritized").text('Globally Prioritized ' + projectType + ' Projects');
    	else
    	      $("p#prioritized").text('Channel Prioritized ' + projectType + ' Projects');
        var projects = new kendo.data.DataSource({
                           transport: {
                               read: function(options){
                                     GanttProjectPriotizationListController.GetPriortizedProjects(
                                         projName,
										 projectType,
                                         function(result,event){
                                            options.success(JSON.parse(result));
                                         },{escape: false}
                                     );
                               },
                               update: function(options){
                                    options.success();
                               }
                           },
                           schema: {
                               model: {
                                 fields: {
                                    id: { from: "ProjectId", type: "string" },
                                    orderId: { from: "Priority", type: "number" },
                                    title: { from: "ProjectName", defaultValue: "", type: "string" },
                                    status: { from: "ProjectStatus", defaultValue: "", type: "string" },
                                    requestedDeliveryDt: { from: "RequestedDeliveryDate", defaultValue: "", type: "string" },
                                    expecteddDeliveryDt: { from: "ExpectedDeliveryDate", defaultValue: "", type: "string" },
                                    owner: { from: "Owner", type: "string" },
									projectOwner: { from: "ProjectOwner", type: "string" },
									businessAnalyst: { from: "BusinessAnalyst", type: "string" },
									tshirtSize: { from: "TshirtSize", type: "string" },
									requestType: { from: "RequestType", type: "string" },
                                    projectType: { from: "ProjectType", type: "string" },
                                    channel: { from: "ProductChannel", type: "string" },
                                    percentComplete: { from: "PercentComplete", type: "number" },
                                    otherPriority: { from: "OtherPriority", type: "number" },
                                    DeliveryChannel: {from: "DeliveryChannel",defaultValue: "", type:"string"},
                                	RequestChannel: {from: "RequestChannel",defaultValue: "",  type:"string"},
                                	PriorityMisMatch :{from: "isPriorityMismatch", type:"boolean"},
                                    CreatedDate:{from:"CreatedDate", type:"date"}
                                 }
                               }
                           }
                        });
        if(projName == 'Foundation'){
               columnsRequested.push({ field: "orderId", title: "Global Governance Priority",  editable: false, sortable: false,width: "30px"});
               //columnsRequested.push({ field: "otherPriority", title: "Channel Governance Priority",  editable: false, sortable: true,width: "30px"});
             }
        else{
               columnsRequested.push({ field: "orderId", title: "Channel Governance Priority",  editable: false, sortable: false,width: "30px"});
               //columnsRequested.push({ field: "otherPriority", title: "Global Governance Priority",  editable: false, sortable: false,width: "30px"});
            }
        columnsRequested.push({ field: "title", title: "Project", editable: false, sortable: true, width: "400px"});
		var titleIndex = columnsRequested.length;
		
        columnsRequested.push({ field: "status", title: "Status",  editable: false, sortable: true, width: "auto"});
		
		if(projectType == 'IT'){
			columnsRequested.push({ field: "channel", title: "Primary Program",  editable: false, sortable: true, width: "auto"});
            columnsRequested.push({ field: "expecteddDeliveryDt", title: "Expected Delivery Date", template: '#= kendo.toString(expecteddDeliveryDt, "MM/dd/yyyy") #', sortable: true, width: "auto"});
		}
        /*if(projName == 'Global'){
              columnsRequested.push({ field: "channel", title: "Primary Channel",  editable: false, sortable: false, width: "auto"});
        }*/
        var grid = $("#listView2").kendoGrid({
            dataSource: projects,
            scrollable: false,
            resizable: true,
            dataBound : insertNoRecordsRow,
            columns: columnsRequested,
            selectable: true,
            change : onChange
        }).data("kendoGrid");
        $("#listView2").kendoTooltip({
              filter: "td:nth-child("+ titleIndex +")", //this filter selects the Project Title column's cells
              position: "right",
              width: 320,
              content: function(e){
                var proj =  e.target[0].parentNode.cells[0].innerHTML;
                if (proj != undefined)
                {
                    //var dataItem = grid.dataSource.getByUid(e.item.data("uid"));

                    var dataItem = $("#listView2").data("kendoGrid").dataItem(e.target.closest("tr"));

                    var template = $('#ToolTipTemplate').clone().html();
                    var replace;
                    var replaceText;
                    var content = '';
                    replace =  template.replace("#ReplaceTitle#", "Owner");
                    replace =  replace.replace("#ReplaceValue#", dataItem.owner == null ? '' : dataItem.owner );
                    content = content + replace;
                    replace =  template.replace("#ReplaceTitle#", "Project Owner");
                    replace =  replace.replace("#ReplaceValue#", dataItem.projectOwner == null ? '' : dataItem.projectOwner);
                    content = content + replace;
					replace =  template.replace("#ReplaceTitle#", "Business Analyst");
                    replace =  replace.replace("#ReplaceValue#", dataItem.businessAnalyst == null ? '' : dataItem.businessAnalyst);
                    content = content + replace;
					if(projectType == 'PMO'){
						replace =  template.replace("#ReplaceTitle#", "Requested Delivery Date");
						replace =  replace.replace("#ReplaceValue#", dataItem.requestedDeliveryDt == null ? '' : dataItem.requestedDeliveryDt);
						content = content + replace;
						replace =  template.replace("#ReplaceTitle#", "Primary Program");
						replace =  replace.replace("#ReplaceValue#", dataItem.channel == null ? '': dataItem.channel );
						content = content + replace;
						replace =  template.replace("#ReplaceTitle#", "Requested By");
						replace =  replace.replace("#ReplaceValue#", dataItem.RequestChannel == null ? '' : dataItem.RequestChannel);
						content = content + replace;
					}else{
						replace =  template.replace("#ReplaceTitle#", "T-Shirt Size");
						replace =  replace.replace("#ReplaceValue#", dataItem.tshirtSize == null ? '' : dataItem.tshirtSize);
						content = content + replace;
						replace =  template.replace("#ReplaceTitle#", "Primary Program");
						replace =  replace.replace("#ReplaceValue#", dataItem.channel == null ? '': dataItem.channel );
						content = content + replace;
                        replace =  template.replace("#ReplaceTitle#", "Created Date");
                        replace =  replace.replace("#ReplaceValue#", dataItem.CreatedDate == null ? '' : kendo.toString(dataItem.CreatedDate, "MM/dd/yyyy"));
                        content = content + replace;
					}
                    return content;
                 }
              }
            }).data("kendoTooltip");
        sortableGrid2 = grid;



    }

    // Sortable - All fun is done here
    function callSortable(grid){
        grid.table.kendoSortable({
            filter: ">tbody >tr",
            connectWith: ".k-grid table",
            disabled: ".no-drag",
            autoScroll: true,
            hint: function(element) { //customize the hint
              var table = $('<table style="width: 600px;" class="k-grid k-widget"></table>'),
                          hint;
              table.append(element.clone()); //append the dragged element
              table.css("opacity", 0.7);
              return table; //return the hint element
            },
            cursor: "move",
            placeholder: function(element) {
              return $('<tr colspan="4" class="placeholder"></tr>');
            },
            change: function(e) {
                  var skip = grid.dataSource.skip(),
                      oldIndex = e.oldIndex,
                      newIndex = e.newIndex,
                      data = grid.dataSource.data();
                  if (e.action == "remove") {
                        dataItem = grid.dataSource.getByUid(e.item.data("uid"));
                        grid.dataSource.remove(dataItem);
                        var newData = grid.dataSource.data();
                        if(dataItem.orderId != null){
                            for(var i = oldIndex; i < newData.length; i++){
                                  var priority = newData[i].orderId;
                                  newData[i].orderId = priority - 1;
                                  changedProjects.push(newData[i].id);
                            }
                            grid.dataSource.data(newData);
                        }
                  } else if (e.action == "receive" && dataItem != null) {
                        var newData = grid.dataSource.data();
                        if(!newData.length){
                             dataItem.orderId = 1;
                             changedProjects.push(dataItem.id);
                             grid.dataSource.insert(newIndex, dataItem);
                        }else if( newData[0].orderId == null){
                             dataItem.orderId = null;
                             changedProjects.push(dataItem.id);
                             grid.dataSource.insert(newIndex, dataItem);
                        }else{
                             grid.dataSource.insert(newIndex, dataItem);
                             newData = grid.dataSource.data();
                             for(var i = newIndex; i < newData.length; i++){
                                  //console.log('newIndex =>' + newIndex);
                                  if(i == newIndex && i  < newData.length - 1){
                                       priority = newData[newIndex + 1].orderId;
                                       newData[i].orderId = priority;
                                       changedProjects.push(newData[i].id);
                                  }else{
                                      var priority = newData[i - 1].orderId;
                                      newData[i].orderId = priority + 1;
                                      changedProjects.push(newData[i].id);
                                  }
                             }
                            grid.dataSource.data(newData);
                            dataItem = null;
                        }
                  }else if (e.action == "sort") {
                        dataItem = grid.dataSource.getByUid(e.item.data("uid"));
                        if(dataItem.orderId != null){
                            grid.dataSource.remove(dataItem);
                            grid.dataSource.insert(newIndex, dataItem);
                            var newData = grid.dataSource.data();
                            if(oldIndex < newIndex){
                                  for(var i = oldIndex; i <= newIndex; i++){
                                    var priority = newData[i].orderId;
                                    if(i == newIndex){
                                        var diff = (newIndex - oldIndex);
                                        newData[i].orderId = priority + diff;
                                        changedProjects.push(newData[i].id);
                                    }
                                    else{
                                        newData[i].orderId = priority - 1;
                                        changedProjects.push(newData[i].id);
                                    }
                                  }
                            }else if(oldIndex > newIndex){
                              for(var i = newIndex; i <= oldIndex; i++){
                                 var priority = newData[i].orderId;
                                 if(i == newIndex){
                                    var diff = (oldIndex - newIndex);
                                    newData[i].orderId = priority - diff;
                                    changedProjects.push(newData[i].id);
                                }else{
                                    newData[i].orderId = priority + 1;
                                    changedProjects.push(newData[i].id);
                                }
                              }
                            }
                            grid.dataSource.data(newData);
                        }
                  }
            }
        });
    }

    //Onchange event for the grid
    function onChange(e) {
        var grid = e.sender;
        var selection = grid.select();
        if (selection.length) {
            var dataItem = grid.dataItem(selection);
            console.log("Gantt selection change :: " + dataItem.id);
            grid.clearSelection();
            window.open('/' + dataItem.id, '_blank');
        }

    }

    // on click edit button
    function enableEdit(obj){
       historyId = '';
	   var channel = (projectType == 'PMO') ? program : projectType;
       GanttProjectPriotizationListController.ValidateEdit(
         channel,
         function(result,event){
           if(event.status){
              // console.log('resut from cache session =>' + result);
              if(result.length != 18){
                  $('div#infoModal').text(result);
                  $('#info').modal('show');
              }else{
                  buildGridData(program)
                  historyId = result;
                  editMode = true;
                  callSortable(sortableGrid1);
                  callSortable(sortableGrid2);
                  $(obj).parent().css("display", "none");
                  $("a.unlockEditLink").addClass("hideDisplay");
                  $("div#save").removeClass("hideDisplay");
                  $("div#modalbackdrop").removeClass("hideDisplay");
                  $("div.k-grid").css("cursor", "move");
                  startTimeout();
              }
           }
         },{escape: false}
       );

    }
	function setTimeOutVar(obj){
		interval = obj;
	}
    // Start timeoutcount
    function startTimeout(){
         timeoutvar = window.setTimeout(
                        function(){
                                $('div#timeoutModal').text("Your session is about to expire. Do you want to continue?");
                                $('#timeout').modal({
                                      backdrop: 'static',
                                      keyboard: false
                                    });
                                $('#timeout').modal('show');
                                noActionTimeoutvar = window.setTimeout(function(){ $('#timeout').modal('hide'); cancelEdit(); console.log('clearing session');}, 60000);
                        }, interval
                    );
    }

    // Stop timeoutcount
    function stopTimeout(){
        if(timeoutvar)
            window.clearTimeout(timeoutvar);
        if(noActionTimeoutvar)
            window.clearTimeout(noActionTimeoutvar);
    }

    //coninue another timeout
    function ContinueSession(){
       stopTimeout();
       startTimeout();
       GanttProjectPriotizationListController.ContinueSession(
          historyId,
          function(result,event){
             if(event.status){
                   console.log('successfully updated record');
             }
          },{escape: false}
       );
    }

    // on click cancel button
    function cancelEdit(obj){
        GanttProjectPriotizationListController.CancelEdit(
            historyId,
            function(result,event){
                if(event.status){
                    showViewMode();
                    stopTimeout();
                }
            },{escape: false}
        );
    }

    // buildGridData
    function buildGridData(program){
       var grid1 = $("#listView").data("kendoGrid");
       var grid2 = $("#listView2").data("kendoGrid");
       grid1.destroy();
       grid2.destroy();
       $("#listView").empty();
       $("#listView2").empty()
       DrawPrioritized(program);
       DrawUnprioritized(program);
       $("input#SearchText").val('');

       var header = $("#listView2").find("thead.k-grid-header");
       if(program == 'Foundation'){
            header.find("[data-field='orderId']").html("<span class='glyphicon glyphicon glyphicon-globe' aria-hidden='true' title ='Global Governance Priority'  style='font-size: 1.4em;'></span>");
            header.find("[data-field='otherPriority']").html("<span class='glyphicon glyphicon-copyright-mark' aria-hidden='true' title ='Channel Governance Priority' style='font-size: 1.4em;'> </span>");
       }
       else{
           header.find("[data-field='otherPriority']").html("<span class='glyphicon glyphicon glyphicon-globe' aria-hidden='true' title ='Global Governance Priority'  style='font-size: 1.4em;'></span>");
           header.find("[data-field='orderId']").html("<span class='glyphicon glyphicon-copyright-mark' aria-hidden='true' title ='Channel Governance Priority'  style='font-size: 1.4em;'></span>");
       }
        header = $("#listView").find("thead.k-grid-header");
          if(program == 'Foundation'){
               header.find("[data-field='orderId']").html("<span class='glyphicon glyphicon glyphicon-globe' aria-hidden='true' title ='Global Governance Priority'  style='font-size: 1.4em;'></span>");
               header.find("[data-field='otherPriority']").html("<span class='glyphicon glyphicon-copyright-mark' aria-hidden='true' title ='Channel Governance Priority' style='font-size: 1.4em;'> </span>");
          }
          else{
              header.find("[data-field='otherPriority']").html("<span class='glyphicon glyphicon glyphicon-globe' aria-hidden='true' title ='Global Governance Priority'  style='font-size: 1.4em;'></span>");
              header.find("[data-field='orderId']").html("<span class='glyphicon glyphicon-copyright-mark' aria-hidden='true' title ='Channel Governance Priority'  style='font-size: 1.4em;'></span>");
        }
    }

    // Change channel list
    function FilterLists (obj){
        program = obj.value;
        buildGridData(program);
        checkAccess(program);
    }

 //If the list is empty please use a no record show
    function insertNoRecordsRow() {

       if (!this.dataSource.data().length) {
         this.tbody.append($("<tr class='no-drag' colspan='2'><td/><td/><td>No records to display</td></tr>"));
       }
       else{
           var showEditMode = false;
           $("div.mismatchErroClass").empty();
           var grid = $("#listView2").data("kendoGrid");
           var sortData = grid.dataSource.data();
           for(var j = 0; j < sortData.length; j++){
             if(sortData[j].PriorityMisMatch){
                changedProjects.push(sortData[j].id);
                showEditMode = true;
             }
           }
           if(showEditMode){
               $("div.mismatchErroClass").html("<p>Projects on the priority list have been closed. Please click on <b>Enable Sorting</b> and then <b>Save</b> to confirm the projects with correct priorities. You may change the sort order as you deem appropriate.</p>")
           }

       }
    }

    //Utility Method
    function noDupe(a) {
       var temp = {};
       for (var i = 0; i < a.length; i++)
            temp[a[i]] = true;
       return Object.keys(temp);
    }

    //on Click unlock
    function deleteHistory(obj){
        GanttProjectPriotizationListController.UnlockEdit(
            program,
            function(result,event){
               if(event.status){
                    $(obj).addClass('hideDisplay');
               }
            },{escape: false}
        );
    }

    //Call server to save
    function saveTODB(obj){
        var projects = [];
        $(obj).html('Saving..');
        $("#cancelbtn").css('display', 'none');
        if(changedProjects.length > 0){
            var grid = $("#listView2").data("kendoGrid"),
                unSortedGrid = $("#listView").data("kendoGrid");
                sortdata = grid.dataSource.data();
                Unsortdata = unSortedGrid.dataSource.data();
            stopTimeout();
            $('#loading').modal({
                 backdrop: 'static',
                 keyboard: false
            });
            $('#loading').modal('show');
            var uniqueProj = noDupe(changedProjects);
            for(var i = 0; i < uniqueProj.length; i++){
                var tempId =  uniqueProj[i];
                for(var j = 0; j < sortdata.length; j++){
                    if(tempId == sortdata[j].id){
                        projects.push({"ProjectId" :sortdata[j].id, "Priority" :  sortdata[j].orderId, "RecordTypeName" : sortdata[j].RecordTypeName});
                    }
                }
                for(var j = 0; j < Unsortdata.length; j++){
                     if(tempId == Unsortdata[j].id){
                        projects.push({"ProjectId" :Unsortdata[j].id, "Priority" :  0, "RecordTypeName" : Unsortdata[j].RecordTypeName});
                     }
                }
            }
            console.log('result +>' +  JSON.stringify(projects));
			var channel = (projectType == 'PMO') ? program : projectType;
            GanttProjectPriotizationListController.Save(
                JSON.stringify(projects),
                channel,
                historyId,
                function(result,event){
                    if(event.status){
                        if(result == null){
                            console.log('successful +>' + result);
                            $(obj).html('Save');
                            $("#cancelbtn").css('display', '');
                            $(obj).css({"pointer-events" : "", "background-color":"#0275d8"});
                            changedProjects = [];
                            projects = [];
                            uniqueProj = [];
                            $("div.mismatchErroClass").empty();
                            showViewMode();
                            $('#loading').modal('hide');
                        }else{
                             $('div#infoModal').text(result);
                             $('#loading').modal('hide');
                             $('#info').modal('show');
                             $(obj).html('Save');
                             $("#cancelbtn").css('display', '');
                             $(obj).css({"pointer-events" : "", "background-color":""});
                        }
                    }else{
                        $('div#infoModal').text('Exception Occured : ' + event.message + ' Please try again.');
                        handleExceptionFromSave(obj);
                    }
                },{escape: false}
            );
        }else{
              $('div#infoModal').text("There was no change in Priority. Nothing was saved.");
              handleExceptionFromSave(obj);
        }

    }

    function showViewMode(){
        editMode = false;
        var grid1 = $("#listView").data("kendoGrid");
        var grid2 = $("#listView2").data("kendoGrid");

        grid1.destroy();
        grid2.destroy();
        DrawPrioritized(program);
        DrawUnprioritized(program);
        $("div#save").addClass("hideDisplay");
        $("div#edit").css("display", "");
        $("div#modalbackdrop").addClass("hideDisplay");
        $("div.k-grid").css("cursor", "pointer");
    }

    function handleExceptionFromSave(obj){
       $('#loading').modal('hide');
       $('#info').modal('show');
       $(obj).html('Save');
       $("#cancelbtn").css('display', '');
       $(obj).css({"pointer-events" : "", "background-color":""});
    }

