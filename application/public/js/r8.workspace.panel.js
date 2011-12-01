
if (!R8.Workspace) {
	R8.Workspace = {};
}
if (!R8.Workspace.panel) {

	R8.Workspace.panel = function(panelDef) {
		var _def = panelDef,
			_id = _def.id,

			_defaultWidth = _def.defaultWidth,
			_defaultHeight = _def.defaultHeight,
			_minWidth = _def.minWidth,
			_minHeight = _def.minHeight,
			_relativePos = _def.relativePos,

			_node = null,
//			_headerNode = null,
			_contentNode = null,
			_mainBodyWrapperNode = null,
			_viewContentNodes = {},
			_currentView = '',

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
//				_headerNode = R8.Utils.Y.one('#'+_def.id+'-header');
				_contentNode = R8.Utils.Y.one('#'+_def.id+'-content');

				_mainBodyWrapperNode = R8.Utils.Y.one('#main-body-wrapper');
//				this.initViews();
				_initialized = true;

				this.resize();
//				this.loadViews();
			},
			initViews: function() {
				for(var v in _def.views) {
					var viewDef = _def.views[v];
					if(typeof(viewDef.method) == 'undefined') continue;
					_viewContentNodes[viewDef.id] = R8.Utils.Y.one('#view-content-'+viewDef.id);
				}
			},
			resize: function() {
				if(!_initialized) return;

				var contentHeight = _mainBodyWrapperNode.get('region').height;

				_node.setStyles({
					'height': contentHeight - (_def.heightMargin * 2),
					'width': _mainBodyWrapperNode.get('region').width - (_def.widthMargin * 2),
					'marginLeft': _def.widthMargin,
					'marginTop': _def.heightMargin
				});
/*
				var numViews = _def.views.length;
				for(var i=0; i < numViews; i++) {
					if(_def.views[i].id == _currentView && typeof(_def.views[i].resizeMethod) != 'undefined') {
						_viewContentNodes[_def.views[i].id].setStyles({'height':contentHeight,'width':_node.get('region').width,'backgroundColor':'#FFFFFF'});
						R8.IDE.views[_def.views[i].resizeMethod]();
						i = numViews + 1;
					}
				}
*/
			},
			render: function() {
//				this.setViewFocus();
				_panelTpl = R8.Rtpl[_def.tplName]({'panel': _def});
				return _panelTpl;
			},
			get: function(key) {
				switch(key) {
					case "node":
						return _node;
						break;
					case "contentNode":
						return _contentNode;
						break;
				}
			},
			setViewFocus: function() {
				var numViews = _def.views.length;
				if(typeof(_def.views) == 'undefined' || numViews == 0) return;

				if(typeof(_def.viewFocus) == 'undefined') {
					_def.views[0]['tClass'] = _def.views[0]['tClass'] + ' active';
					_currentView = _def.views[0].id;
				}

				for(var i=0; i < numViews; i++) {
					if(_def.views[i].id == _def.viewFocus) {
						_def.views[i]['tClass'] = _def.views[i]['tClass'] + ' active';
						_currentView = _def.views[i].id;
						i = numViews + 1;
					}
				}
			},
			loadViews: function() {
				for(var v in _def.views) {
					var viewDef = _def.views[v];
					if(typeof(viewDef.method) == 'undefined') continue;
					R8.IDE.views[viewDef.method](_viewContentNodes[viewDef.id]);
				}
			}
		}
	};
}