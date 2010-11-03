if (!R8.Model) {

	(function(R8) {
		R8.Model = function(options) {
			return {
				modelDefs : null,

				getFieldDefs : function(modelName) {
					if(this.modelDefs == null) this.initModelDefs();
					return this.modelDefs[modelName]['field_defs'];
/*
					var fieldList = R8.Model.defs[modelName]['field_defs'];
					var fieldDefs = {};
					for(index in fieldList) {
						var fieldDef = fieldList[index];
						for(fieldName in fieldDef) {
							fieldDefs[fieldName] = fieldDef[fieldName];
							fieldDefs[fieldName]['i18n'] = R8.Model.i18n[modelName][fieldName];
						}
					}
					return fieldDefs;
*/
				},

				getFieldDef : function(modelName,fieldName) {
					if(this.modelDefs == null) this.initModelDefs();

					return this.modelDefs[modelName]['field_defs'][fieldName];
/*
					var fieldList = R8.Model.defs[modelName]['field_defs'];
					for(index in fieldList) {
						var fieldDef = fieldList[index];
						for(fieldName in fieldDef) {
							fieldDefs[fieldName] = fieldDef[fieldName];
							fieldDefs[fieldName]['i18n'] = R8.Model.i18n[modelName][fieldName];
						}
					}

					var fieldDef = R8.Model.defs[modelName]['field_defs'][fieldName];
					fieldDef['i18n'] = R8.Model.i18n[modelName][fieldName];
					return fieldDef;
*/
				},
//TODO: maybe temp function,current fields are array based, not hash to maintain ordering,
//might not be necessary
				initModelDefs : function() {
					this.modelDefs = {};
					for(modelName in this.defs) {
						this.modelDefs[modelName] = {
							'field_defs':{}
						};
						var fieldList = this.defs[modelName]['field_defs'];
						for(index in fieldList) {
							var fieldDef = fieldList[index];
							for(fieldName in fieldDef) {
								fieldDef[fieldName] = fieldDef[fieldName];
								fieldDef[fieldName]['i18n'] = R8.Model.i18n[modelName][fieldName];
								this.modelDefs[modelName]['field_defs'][fieldName] = fieldDef[fieldName];
							}
						}
					}
				},

				getFieldOptions : function(modelName,fieldName) {
					return this.i18n[modelName]['options_list'][fieldName];
				},

				fieldDefs : {
					'node' : {
						'field_defs' :{
							'display_name': {
								'i18n': 'Display Name',
								'type' : 'text',
							},
							'operational_status': {
								'i18n':'Op Status',
								'type' : 'select',
							},
							'image_size' : {
								'i18n' : 'Image Size',
								'type' : 'text'
							}
						},
					}
				}
			}
		}();
	})(R8);
}
