
if (!R8.Port) {

	R8.Port = function(portDef) {
		var _def = portDef,

			_views = {},
			_events = {};

		return {
			init: function() {
//				this.requireView('editor_target');
			},
			get: function(key) {
				switch(key) {
					case "id":
						return _def.id;
						break;
					case "type":
						return "port";
						break;
					case "location":
						return _def.location;
						break;
					case "direction":
						return _def.direction;
						break;
					case "name":
						return _def.name;
						break;
					case "def":
						return _def;
						break;
				}
			},
//-----------------------------------------------
//VIEW RELATED METHODS-------------------
//-----------------------------------------------
			requireView: function(viewType) {
				if(typeof(_views[viewType]) == 'undefined') _views[viewType] = {};

				_views[viewType] = new R8.IDE.View[viewType].port(this);

			},
			getView: function(viewType) {
				if(typeof(_views[viewType]) == 'undefined') this.requireView('editor_target');

				return _views[viewType];
			},
			renderView: function(viewType) {
				return _views[viewType].render();
			},
			initView: function(viewType) {
				return _views[viewType].init();
			}

//------------------------------------
//PORT RELATED METHODS
//------------------------------------

		}
	};
}