
if (!R8.IDE.region) {

	R8.IDE.region = function(regionDef) {
		var _def = regionDef,
			_id = _def.id,
			_defaultWidth = _def.defaultWidth,
			_defaultHeight = _def.defaultHeight,
			_minWidth = _def.minWidth,
			_minHeight = _def.minHeight,

			_realtiveRegion = _def.relativeRegion,
			_realtivePos = _def.relativePos,

			_node = null,
			_headerNode = null,
			_contentNode = null,

			_contentList = {},

			_regionTpl = '',
/*
 					<ul id="l-panel-tab-list" class="l-panel-tab-list">\
						<li id="project-view-tab" class="active">Project</li>\
						<li id="component-view-tab">Components</li>\
					</ul>\

 */
			_events = {};

			if(typeof(_def.pClass == 'undefined')) _def.pClass = '';
			if(typeof(_def.headerClass == 'undefined')) _def.headerClass = '';
			if(typeof(_def.contentClass == 'undefined')) _def.contentClass = '';

		return {
			init: function() {
			},
			render: function() {
				_panelTpl = R8.Rtpl['ide_panel_frame']({'panel': _def});

				return _panelTpl;
			},
			get: function(key) {
				switch(key) {
					case "foo":
						return "foo";
						break;
				}
			},
		}
	};
}