if (!R8.Fields) {

	R8.Fields = function(){
		var _cfg = null,
			_fieldDefEditNode = null,
			_availFields = {},

			_events = {};

		return {
			init: function(fieldDefs) {
				if(document.getElementById('available-fields') == null) {
					var that = this;
					var initCallback = function() {
						R8.Fields.init(fieldDefs);
					}
					setTimeout(initCallback,25);
					return;
				}

				_fieldDefEditNode = R8.Utils.Y.one('#field-def-edit');
				for(var i in fieldDefs) {
					_availFields[fieldDefs[i].name] = fieldDefs[i];
					this.addAvailField(fieldDefs[i]);
				}

				_events['fieldClick'] = R8.Utils.Y.delegate('click',this.fieldFocus,'#available-fields','.field',this);
			},

			fieldFocus: function(e) {
				var fieldName = e.currentTarget.get('id');

				this.displayField(fieldName);
			},
			displayField: function(fieldName) {
				var fieldDef = _availFields[fieldName],
					templateVars = {};

				templateVars['fieldDef'] = fieldDef;
				_fieldDefEditNode.set('innerHTML',R8.Rtpl['component_display_field'](templateVars));
			},
			editField: function(fieldName) {
				var templateVars = {};
				templateVars['fieldDef'] = _availFields[fieldName];
				_fieldDefEditNode.set('innerHTML',R8.Rtpl['component_edit_field'](templateVars));
			},
			saveField: function(fieldName) {
				var fieldJsonStr = R8.Utils.Y.JSON.stringify(_availFields[fieldName]),
					componentId = _availFields[fieldName].component_id;
				var params = {
					'cfg': {
						data: 'field_def='+fieldJsonStr,
						form: {
							id : 'field-edit-form',
							upload : false
						}
					}
				}
				R8.Ctrl.call('component/save_field/'+componentId,params);
			},
			handleSavedField: function(fieldDef) {
				_availFields[fieldDef.name] = fieldDef;
				this.displayField(fieldDef.name);
			},
			addAvailField: function(fieldDef) {
				var availFieldsContainer = R8.Utils.Y.one('#available-fields');
				var fieldContent = this.getFieldMarkup(fieldDef);
				availFieldsContainer.append(fieldContent);
			},
			getFieldMarkup: function(fieldDef) {
				if(typeof(fieldDef.i18n) === 'undefined') fieldDef.i18n = fieldDef.name;

				var fieldTpl = '<li class="field" style="cursor: pointer; height: 20px; width: 140px; margin: 3px; padding: 3px; border: 1px solid rgb(153, 153, 153); opacity: 1; background-color: #FFFFFF;" id="'+fieldDef.name+'" class="yui3-dd-drop yui3-dd-draggable">\
					<span style="">'+fieldDef.i18n+'</span>\
				</li>';

				return fieldTpl;
			},

			renderFieldEdit: function(fieldDef) {
				var fieldTpl = this.getFieldEditTpl(fieldDef);
				_fieldDefEditNode.set('innerHTML',fieldTpl);
			},
			getFieldEditTpl: function(fieldDef) {
				var tpl = '<table cellspacing="0" cellpadding="0" border="0">\
								<tr><td>Field</td><td><input type="text" size="15" id="'+fieldDef.name+'" name="'+fieldDef.name+'" value="'+fieldDef.name+'"/></td></tr>\
								<tr><td>Label</td><td><input type="text" size="15" value="'+fieldDef.i18n+'"/></td></tr>\
								<tr><td>Type</td><td>\
									<select name="type"/>\
										<option value="text">Text</option>\
										<option value="select">Select</option>\
										<option value="radio">Radio</option>\
										<option value="multi-select">Multi-Select</option>\
									</select>\
									</td>\
								</tr>\
								<tr><td>Default Value</td><td><input type="text" size="15" id="'+fieldDef.name+'" name="'+fieldDef.name+'" value="'+fieldDef.name+'"/></td></tr>\
								<tr><td>Required</td><td><input type="checkbox" value="true"/></td></tr>\
								<tr><td>Description</td><td><textarea rows="4" cols="30">'+fieldDef.description+'</textarea></td></tr>\
						   </table>';

				return tpl;
			}
		}
	}();
}