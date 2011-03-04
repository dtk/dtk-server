if (!R8.Fields) {

	R8.Fields = function(){
		var _cfg = null,
			_availFields = {};

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

				for(var i in fieldDefs) {
					_availFields[fieldDefs[i].name] = fieldDefs[i];
					this.addAvailField(fieldDefs[i]);
				}

			},

			addAvailField: function(fieldDef) {
				var availFieldsContainer = R8.Utils.Y.one('#available-fields');
				var fieldContent = this.getFieldMarkup(fieldDef);
				availFieldsContainer.append(fieldContent);
			},
			getFieldMarkup: function(fieldDef) {
				if(typeof(fieldDef.i18n) === 'undefined') fieldDef.i18n = fieldDef.name;

				var fieldTpl = '<li style="height: 20px; width: 140px; margin: 3px; padding: 3px; border: 1px solid rgb(153, 153, 153); opacity: 1;" id="'+fieldDef.name+'" class="yui3-dd-drop yui3-dd-draggable">\
					<span style="">'+fieldDef.i18n+'</span>\
				</li>';

				return fieldTpl;
			}
		}
	}();
}