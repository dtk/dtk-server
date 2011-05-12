
if (!R8.IDE.panel) {

	R8.IDE.panel = function(panelDef) {
		var _def = panelDef,
			_id = _def.id,

			_defaultWidth = _def.defaultWidth,
			_defaultHeight = _def.defaultHeight,
			_minWidth = _def.minWidth,
			_minHeight = _def.minHeight,
			_relativePos = _def.relativePos,

			_node = null,
			_headerNode = null,
			_contentNode = null,

			_contentList = {},

			_panelTpl = '',
/*
 					<ul id="l-panel-tab-list" class="l-panel-tab-list">\
						<li id="project-view-tab" class="active">Project</li>\
						<li id="component-view-tab">Components</li>\
					</ul>\

 */
			_initialized = false,
			_events = {};

			if(typeof(_def.pClass) == 'undefined') _def.pClass = '';
			if(typeof(_def.headerClass) == 'undefined') _def.headerClass = '';
			if(typeof(_def.contentClass) == 'undefined') _def.contentClass = '';

			if(typeof(_def.views) != 'undefined') {
				for(var v in _def.views) {
					if(typeof(_def.views[v].tClass) == 'undefined') _def.views[v].tClass = '';
					if(typeof(_def.views[v].cClass) == 'undefined') _def.views[v].cClass = '';
				}
			} else {
				_def.views = [];
			}

		return {
			init: function() {
				_node = R8.Utils.Y.one('#'+_def.id);
				_headerNode = R8.Utils.Y.one('#'+_def.id+'-header');
				_contentNode = R8.Utils.Y.one('#'+_def.id+'-content');

				_initialized = true;

				this.resize();
				this.loadViews();
			},
			resize: function() {
				if(!_initialized) return;

				var contentHeight = _node.get('region').height - _headerNode.get('region').height;
				_contentNode.setStyles({'height':contentHeight,'width':_node.get('region').width,'backgroundColor':'#FFFFFF'});
			},
			render: function() {
				this.setViewFocus();
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
			setViewFocus: function() {
				var numViews = _def.views.length;
				if(typeof(_def.views) == 'undefined' || numViews == 0) return;

				if(typeof(_def.viewFocus) == 'undefined') {
					_def.views[0]['tClass'] = _def.views[0]['tClass'] + ' active';
				}

				for(var i=0; i < numViews; i++) {
					if(_def.views[i].id == _def.viewFocus) {
						_def.views[i]['tClass'] = _def.views[i]['tClass'] + ' active';
						i = numViews + 1;
					}
				}
			},
			loadViews: function() {
				for(var v in _def.views) {
					var viewDef = _def.views[v];
					if(typeof(viewDef.method) == 'undefined') continue;
					R8.IDE.views[viewDef.method](_contentNode);
				}
			}
		}
	};
}