
if (!R8.Implementation) {

	R8.Implementation = function(implementationDef) {
		var _def = implementationDef,
			_components = {},

			_views = {},
			_initialized = false,
			_events = {};

		return {
			init: function() {
				this.setupEvents();

				for(var c in _def.components) {
					this.addComponent(_def.components[c]);
				}

				_initialized = true;
			},
			get: function(key) {
				switch(key) {
					case "id":
						return _def.id;
						break;
					case "type":
						return _def.type;
						break;
					case "name":
//						return _def.name;
						return _def.display_name;
						break;
					case "components":
						return _components;
						break;
					case "file_assets":
						return _def.file_assets;
						break;
				}
			},
			setupEvents: function() {
//				R8.IDE.on('node-'+this.get('id')+'-component-add',this.instantiateComponent,this);
			},
//-----------------------------------------------
//VIEW RELATED METHODS-------------------
//-----------------------------------------------
			requireView: function(viewType) {
				if(typeof(_views[viewType]) == 'undefined') _views[viewType] = {};

				_views[viewType] = new R8.IDE.View[viewType].implementation(this);
			},
			getView: function(viewType) {
				if(typeof(_views[viewType]) == 'undefined') this.requireView(viewType);

				return _views[viewType];
			},
			renderView: function(viewType) {
				if(typeof(_views[viewType]) == 'undefined') this.requireView(viewType);

				return _views[viewType].render();
			},
/*
			initView: function(viewType) {
				return _views[viewType].init();
			},
*/
			isInitialized: function() {
				return _initialized;
			},
//------------------------------------
//IMPLEMENTATION RELATED METHODS
//------------------------------------
			addComponent: function(componentDef,isNew) {

				_components[componentDef.id] = new R8.Component(componentDef);

				for(var v in _views) {
					_views[v].addComponent(_components[componentDef.id],isNew);
				}

				_components[componentDef.id].init();
			}
		}
	};
}