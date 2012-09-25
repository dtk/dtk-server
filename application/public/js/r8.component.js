
if (!R8.Component) {

	R8.Component = function(componentDef) {
		var _def = componentDef,

			_views = {},
			_events = {};

		return {
			init: function() {
			},
			get: function(key) {
				switch(key) {
					case "id":
						return _def.id;
						break;
					case "def":
						return _def;
						break;
					case "type":
						return "component";
						break;
					case "name":
						return _def.name;
						break;
				}
			},
//-----------------------------------------------
//VIEW RELATED METHODS-------------------
//-----------------------------------------------
			requireView: function(viewType) {
				if(typeof(_views[viewType]) == 'undefined') _views[viewType] = {};

//				_views[viewType] = new R8.IDE.View[viewType].component(this);
//console.log(viewType);
				_views[viewType] = new R8.IDE.View.component[viewType](this);

			},
			getView: function(viewType) {
				if(typeof(_views[viewType]) == 'undefined') this.requireView(viewType);

				return _views[viewType];
			},
			renderView: function(viewType) {
				if(typeof(_views[viewType]) == 'undefined') this.requireView(viewType);

				return _views[viewType].render();
			},
			initView: function(viewType) {
				return _views[viewType].init();
			},

//------------------------------------
//COMPONENT RELATED METHODS
//------------------------------------
			refresh: function(newComponentDef) {
				_def = newComponentDef;
//DEBUG
//console.log('going to refresh component...,');
//console.log(newComponentDef);
				for(var v in _views) {
					_views[v].refresh();
				}
			},
			purge: function() {
//DEBUG
console.log('going to purge component:'+this.get('id'));

/*
				for(var l in _links) {
					delete(_links[l]);
				}
				for(var p in _ports) {
					delete(_ports[p]);
				}
*/
			}			
		}
	};
}