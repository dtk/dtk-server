
if (!R8.Port) {

	R8.Port = function(portDef,node) {
//DEBUG
//console.log(portDef);
		var _def = portDef,
			_node = node,

			_views = {},
			_events = {};

		return {
			init: function() {
//				this.requireView('editor_target');
			},
			get: function(key,value) {
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
					case "node":
						return _node;
						break;
					case "view":
						if(typeof(_views[value]) == 'undefined') this.requireView(value);
		
						return _views[value];
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
			},

//------------------------------------
//PORT RELATED METHODS
//------------------------------------
			swapInNew: function(newPortDef) {
//TODO: decide if each view function should have a swapInNew and merge function
				this.getView('editor_target').get('node').set('id','port-'+newPortDef.id);
				_def = newPortDef;
			}
		}
	};
}