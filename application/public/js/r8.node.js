
if (!R8.Node) {

	R8.Node = function(nodeDef) {
		var _def = nodeDef.obj,
			_applications = {},
			_views = {},

			_events = {};

		return {
			init: function() {
//				this.requireView('editor_target');
				this.requireView('project');
/*
				for(var i in _treeObj.nodes) {
					_nodes[_treeObj.nodes[i].id] = _treeObj.nodes[i];
				}
*/
			},
			get: function(key) {
				switch(key) {
					case "id":
						return _def.id;
						break;
					case "type":
						return "node";
						break;
					case "os_type":
						return _def.os_type;
						break;
					case "name":
//						return _def.name;
						return _def.display_name;
						break;
					case "applications":
						return _applications;
						break;
				}
			},
//-----------------------------------------------
//VIEW RELATED METHODS-------------------
//-----------------------------------------------
			requireView: function(viewType) {
				if(typeof(_views[viewType]) == 'undefined') _views[viewType] = {};

				_views[viewType] = new R8.IDE.View[viewType].node({'obj':this});

			},
			getView: function(viewType) {
				return _views[viewType];
			},
			renderView: function(viewType) {
				return _views[viewType].render();
			},
			initView: function(viewType) {
				return _views[viewType].init();
			}
		}
	};
}