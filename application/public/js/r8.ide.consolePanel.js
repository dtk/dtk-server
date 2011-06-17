
if (!R8.IDE.consolePanel) {

	R8.IDE.consolePanel = function(panelDef) {
		var _def = panelDef,
			_id = _def.id,

			_defaultWidth = _def.defaultWidth,
			_defaultHeight = _def.defaultHeight,
			_minWidth = _def.minWidth,
			_minHeight = _def.minHeight,
			_relativePos = _def.relativePos,

			_node = null,
			_headerNode = null,
			_tabListNode = null,
			_contentNode = null,
			_viewContentNodes = {},
			_currentView = null,
			_lastView = null,

			_views = {},

			_contentList = {},

			_targetList = [],
			_nodeList = [],

			_panelTpl = '',

			_chefDebuggerLoaded = false;
/*
 					<ul id="l-panel-tab-list" class="l-panel-tab-list">\
						<li id="project-view-tab" class="active">Project</li>\
						<li id="component-view-tab">Components</li>\
					</ul>\

 */
			_emptyContentTpl = '',

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
				_tabListNode = R8.Utils.Y.one('#'+_def.id+'-tab-list');

				_contentNode = R8.Utils.Y.one('#'+_def.id+'-content');
				_contentNode.append(_emptyContentTpl);

				_events['ftabMouseEnter'] = R8.Utils.Y.delegate('mouseenter',function(e){
					e.currentTarget.addClass('show-close');
				},_tabListNode,'.view-tab');

				_events['ftabMouseLeave'] = R8.Utils.Y.delegate('mouseleave',function(e){
					e.currentTarget.removeClass('show-close');
				},_tabListNode,'.view-tab');

				_events['ftabClick'] = R8.Utils.Y.delegate('click',function(e){
					var tabNodeId = e.currentTarget.get('id');
					var viewId = tabNodeId.replace(_id+'-tab-','');

					this.setViewFocus(viewId);
//					R8.Editor.fileFocus(fileId);
				},_tabListNode,'.view-tab',this);

				_events['fCloseClick'] = R8.Utils.Y.delegate('click',function(e){
					var tabNodeId = e.currentTarget.get('id');
					var fileId = tabNodeId.replace('close-file-','');

					this.closeView(fileId);
				},_tabListNode,'.view-tab .close-view',this);


				R8.Topbar2.addViewItem({
					id: 'chef-debugger',
					i18n: 'Config Debugger',
					visible: false,
					clickCallback: this.toggleChefDebugger
				});

				this.initViews();
				_initialized = true;

				this.resize();
				this.loadViews();
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

				var contentHeight = _node.get('region').height - _headerNode.get('region').height;
				_contentNode.setStyles({'height':contentHeight-6,'width':_node.get('region').width-6,'backgroundColor':'#FFFFFF'});


				if (_currentView != null) {
//console.log('should be resizing debugger...');
					_views[_currentView].resize();
				}

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
				_panelTpl = R8.Rtpl['ide_panel_frame']({'panel': _def});

				return _panelTpl;
			},
			get: function(key) {
				switch(key) {
					case "id":
						return _id;
						break;
					case "node":
						return _contentNode;
						break;
					case "views":
						return _views;
						break;
					case "type":
						return "console";
						break;
					case "currentView":
						if(typeof(_views[_currentView]) == 'undefined') return null;
						else return _views[_currentView];
						break;
					case "configDebuggerView":
						if(typeof(_views['chef-debugger']) != 'undefined') return _views['chef-debugger'];
						else return null;
						break;
				}
			},
			setViewFocus: function(viewId) {
				if(viewId == _currentView) return;

				if (this.numViews() > 1) {
					for (var v in _views) {
						var tabNode = R8.Utils.Y.one('#'+_id+'-tab-' + v);
						tabNode.removeClass('active');
						
						_views[v].blur();
/*
						 if(_views[v].type == 'target') {
							 R8.Utils.Y.one('#target-viewspace-'+v).setStyle('display','none');
						 }
*/
					}
				}
				var tabNode = R8.Utils.Y.one('#'+_id+'-tab-'+viewId);
				tabNode.addClass('active');
				_views[viewId].focus();

				if(_currentView == null) {
					_lastView = viewId
				} else {
					_lastView = _currentView;
				}
				_currentView = viewId;
			},
			loadViews: function() {
				for(var v in _def.views) {
					var viewDef = _def.views[v];
					if(typeof(viewDef.method) == 'undefined') continue;
					R8.IDE.views[viewDef.method](_viewContentNodes[viewDef.id]);
				}
			},
			addTab: function(viewId) {
				var tabTpl = '<li id="'+_id+'-tab-'+viewId+'" class="view-tab">'+_views[viewId].get('name')+'<div id="close-file-'+viewId+'" class="close-view"></div></li>';

				_tabListNode.append(tabTpl);
			},
			numViews: function() {
				var viewCount = 0;
				for(var v in _views) viewCount++;

				return viewCount;				
			},
			viewIsLoaded: function(viewId) {
				if(typeof(_views[viewId]) == 'undefined') return false;
				else return true;
			},
			loadView: function(view) {
				if (this.viewIsLoaded(view.id)) {
					this.setViewFocus(view.id);
					return;
				}
				if(this.numViews() == 0) _contentNode.set('innerHTML','');

				view.panel = this;
				switch(view.type) {
					case "chef-debugger":
						if(typeof(_views[view.id]) != 'undefined') {
							return;
						}
						_views[view.id] = new R8.IDE.View.chefDebugger(view);
						break;
					case "target":
						_views[view.id] = new R8.IDE.View.target(view);
						break;
				}

				var viewContent = _views[view.id].render();
				if(viewContent != '') _contentNode.append(viewContent);
				_views[view.id].init();

				this.addTab(view.id);
				this.setViewFocus(view.id);
			},
			closeView: function(viewId) {
				switch(_views[viewId].get('type')) {
					case "file":
						var tempArray = [];
						var activeIndex = null;
						for(var i in _fileList) {
							if(_fileList[i] != viewId) tempArray.push(_fileList[i]);
							else activeIndex = i;
						}
						_fileList = tempArray;
						if(_fileList.length === 0) R8.Editor.closeEditor();
						break;
				}

				var tabNode = R8.Utils.Y.one('#'+_id+'-tab-'+viewId);
				tabNode.purge(true);
				tabNode.remove();
				_views[viewId].close();
				delete(_views[viewId]);

				if(viewId == _currentView) _currentView = null;
				if(this.numViews() == 0) {
					_contentNode.append(_emptyContentTpl);
					_lastView = null;
				} else {
					this.setViewFocus(_lastView);
				}
			},
/*
			viewFocus: function(viewId) {
				if(_currentViewFocus == viewId) return;

//				_editor.getSession().setValue(_files[fileId].get('content'));
//				var callback = function() {
//					_editor.gotoLine(1);
//				}
//				setTimeout(callback,150);

				for(var v in _views) {
					R8.Utils.Y.one('#view-tab-'+v).removeClass('focus');
				}
				R8.Utils.Y.one('#view-tab-'+viweId).addClass('focus');
				_currentViewFocus = viewId;

			},
*/
//----------------------------------------
//Editor Panel Specific Functions
//----------------------------------------
			toggleChefDebugger: function() {

				if (_chefDebuggerLoaded) {
					
				} else {
					var viewDef = {
						'id': 'chef-debugger',
						'name': 'Config Debugger',
						'type': 'chef-debugger'
					};
					R8.IDE.pushConsoleView(viewDef);
					_chefDebuggerLoaded = true;
				}
			}
		}
	};
}