jq.getScript( "/support/api/38.0/interaction.js", function( data, textStatus, jqxhr ) {
//  console.log( textStatus ); // Success
//  console.log( jqxhr.status ); // 200
//  console.log( "Load was performed. ");
});

var phoneFields = {};

for (key in gridInfoMap) {
	var thisGridInfo = gridInfoMap[key];
	var objId = thisGridInfo.objId;
	
	if (thisGridInfo.metaColumns) {
		for (var i=0; i<thisGridInfo.metaColumns.length; i++) {
			var thisCol = thisGridInfo.metaColumns[i];

			if (thisCol.isTypePhone()) {

				if (!phoneFields[objId]) {
					phoneFields[objId] = {};
				}

				phoneFields[objId][thisCol.fieldId] = { objId: thisGridInfo.objId,
														fieldId: thisCol.fieldId,
														readOnly: thisCol.readOnly,
														objectApiName : thisGridInfo.gridApiName,
														fieldName: thisCol.fieldName };
			}
		}
	}
}

function makeCTICall(phone, id, entityName, objectName, displayName) {
    sendCTIMessage('/CLICK_TO_DIAL?DN=' + phone +
                   '&ID=' + id + 
                   '&ENTITY_NAME=' + entityName + 
                   '&OBJECT_NAME=' + objectName +
                   '&DISPLAY_NAME=' + displayName);
}

jq(document).ready(function() {
	var clickToDialAfter = '<img src="/img/btn_dial_inline.gif" alt="Click to dial" width="16" height="10" title="Click to dial"/>' +
							'<img src="/img/btn_nodial_inline.gif" alt="Click to dial disabled" width="16" height="10" style="display:none;" title="Click to dial disabled"/>';

	for (key in phoneFields) {

		var gridRows = jq('table[name="' + key + '"] tbody > tr.dr');

		for (subkey in phoneFields[key]) {
	    
			var phoneField = phoneFields[key][subkey];

//			console.log('Phone field found in Object ' + phoneField.objectApiName + ' objId ' + phoneField.objId +
//						' field ' + phoneField.fieldName + ' field id ' + phoneField.fieldId);

			// add click to dial to the cells
			gridRows.find('td[name="' + subkey + '"]').each(function() {

				var thisCell = jq(this);
				var phone;
				if (phoneField.readOnly) {
					phone = thisCell.text();			
				}
				else {
					phone = thisCell.find('input').val();
				}

				var id = thisCell.parent('tr').attr('id');
				var objectApiName = phoneField.objectApiName;

				thisCell.append(clickToDialAfter);

				thisCell.on('click', 'img', function(event) {
					console.log('Calling ' + phone + ' for ' + id);
					makeCTICall(phone, id, '', objectApiName, '');
				});
			
			});
			
		}
	}
});
