
if (!R8.File_asset) {

	R8.File_asset = function(fileAssetDef) {
		var _def = fileAssetDef.obj,
			_views = {},

			_events = {};

		return {
			init: function() {
				this.requireView('project');
			},
			get: function(key) {
				switch(key) {
					case "id":
						return _def.id;
						break;
					case "type":
						return "file_asset";
						break;
					case "name":
//						return _def.name;
						return _def.display_name;
						break;
				}
			},
//-----------------------------------------------
//VIEW RELATED METHODS-------------------
//-----------------------------------------------
			requireView: function(viewType) {
				if(typeof(_views[viewType]) == 'undefined') _views[viewType] = {};

				_views[viewType] = new R8.IDE.View[viewType].file_asset({'obj':this});

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