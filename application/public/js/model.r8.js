if (!R8.Model) {

	(function(R8) {
		R8.Model = function(options) {
			return {
				getFieldDefs : function(modelName) {
					return this.fieldDefs[modelName]['field_defs'];
				},

				getFieldDef : function(modelName,fieldName) {
					return this.fieldDefs[modelName]['field_defs'][fieldName];
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
