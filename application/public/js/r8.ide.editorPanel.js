
if (!R8.IDE.editorPanel) {

	R8.IDE.editorPanel = function(panelDef) {
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

			_fileList = [],
			_fileAssets = {},

			_targetList = [],

			_panelTpl = '',
/*
 					<ul id="l-panel-tab-list" class="l-panel-tab-list">\
						<li id="project-view-tab" class="active">Project</li>\
						<li id="component-view-tab">Components</li>\
					</ul>\

 */
			_emptyContentTpl = '<div id="editor-empty-bg" class="editor-empty-bg"></div>\
			',

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
				},_tabListNode,'.panel-tab-body');

				_events['ftabMouseLeave'] = R8.Utils.Y.delegate('mouseleave',function(e){
					e.currentTarget.removeClass('show-close');
				},_tabListNode,'.panel-tab-body');

				_events['fCloseClick'] = R8.Utils.Y.delegate('click',function(e){
					var tabNodeId = e.currentTarget.get('id');
					var viewId = tabNodeId.replace('close-file-','');

					this.closeView(viewId);
					e.halt();
				},_tabListNode,'.close-view',this);

				_events['ftabClick'] = R8.Utils.Y.delegate('click',function(e){
					var tabNodeId = e.currentTarget.get('id');
					var viewId = tabNodeId.replace(_id+'-tab-','');

					this.setViewFocus(viewId);
//					R8.Editor.fileFocus(fileId);
				},_tabListNode,'.panel-tab',this);

				this.initViews();
				_initialized = true;
//DEBUG
//				this.resize();
				this.loadViews();
			},
			initViews: function() {
				for(var v in _def.views) {
					var viewDef = _def.views[v];
					if(typeof(viewDef.method) == 'undefined') continue;
					_viewContentNodes[viewDef.id] = R8.Utils.Y.one('#view-content-'+viewDef.id);
				}
			},
			resize: function(resizeType) {
				if(!_initialized) return;

				var contentHeight = this.get('panelNode').get('region').height - _headerNode.get('region').height - 4;
				if (typeof(resizeType) == 'undefined') {
//					_contentNode.setStyles({'height': contentHeight - 6,'width': _node.get('region').width - 6,'backgroundColor': '#FFFFFF'});
					_contentNode.setStyles({'height': contentHeight,'width': this.get('panelNode').get('region').width});
				} else if(resizeType == 'width') {
//					_contentNode.setStyles({'width': _node.get('region').width - 6,'backgroundColor': '#FFFFFF'});
					_contentNode.setStyles({'width': this.get('panelNode').get('region').width});
				} else if(resizeType == 'height') {
//					_contentNode.setStyles({'height': contentHeight - 6,'backgroundColor': '#FFFFFF'});
					_contentNode.setStyles({'height': contentHeight});
				}

				if(_fileList.length > 0) R8.Editor.resize();

//				if(_currentView != null) _views[_currentView].resize();


				var numViews = _def.views.length;
				for(var i=0; i < numViews; i++) {
					if(_def.views[i].id == _currentView && typeof(_def.views[i].resizeMethod) != 'undefined') {
						_viewContentNodes[_def.views[i].id].setStyles({'height':contentHeight,'width':_node.get('region').width,'backgroundColor':'#FFFFFF'});
						R8.IDE.views[_def.views[i].resizeMethod]();
						i = numViews + 1;
					}
				}

			},
			render: function() {
//				this.setViewFocus();
				_panelTpl = R8.Rtpl[_def.tplName]({'panel': _def});

				return _panelTpl;
			},
			get: function(key) {
				switch(key) {
					case "id":
						return _id;
						break;
					case "panelNode":
						return _node.get('parentNode');
						break;
					case "node":
						return _contentNode;
						break;
					case "views":
						return _views;
					case "type":
						return "editor";
						break;
					case "currentView":
						if(typeof(_views[_currentView]) == 'undefined') return null;
						else return _views[_currentView];
						break;
					case "firstView":
						for(var v in _views) {
							return v;
						}
						break;
				}
			},
			setViewFocus: function(viewId) {
				if(viewId == _currentView) return;

				if (this.numViews() > 1) {
					for (var v in _views) {
						if(_views[v].get('id') == viewId || !_views[v].inFocus()) continue;

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

				if(tabNode != null) tabNode.addClass('active');

				_views[viewId].focus();
/*
				if(_views[viewId].get('type') == 'file' && _fileList.length == 1) {
					R8.Utils.Y.one('#editor-wrapper').setStyle('display','block');
				} else if(_views[viewId].get('type') == 'file' && _fileList.length > 1) {
					R8.Utils.Y.one('#editor-wrapper').setStyle('display','block');
					if(typeof(_views[viewId].content) != 'undefined')
						R8.Editor.setEditorContent(_views[viewId].content);
				} else if(_views[viewId].get('type') == 'target') {
//TODO: cleanup this hack
					if(_fileList.length > 0) R8.Utils.Y.one('#editor-wrapper').setStyle('display','none');
					R8.Utils.Y.one('#target-viewspace-'+viewId).setStyle('display','block');
				}
*/
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
//				var tabTpl = '<li id="'+_id+'-tab-'+viewId+'" class="view-tab">'+_views[viewId].get('name')+'<div id="close-file-'+viewId+'" class="close-view"></div></li>';

				var tabTpl = '<li id="'+_id+'-tab-'+viewId+'" class="active panel-tab">\
								<div class="panel-tab-body" style="margin: 7px 3px 0 3px;">'+_views[viewId].get('name')+'<div id="close-file-'+viewId+'" class="close-view"></div></div>\
							</li>';

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
				var viewId = view.get('id');
				if (this.viewIsLoaded(viewId)) {
					this.setViewFocus(viewId);
					return;
				}
				if(this.numViews() == 0) _contentNode.set('innerHTML','');

				view.set('panel',this);
				_views[view.get('id')] = view;
/*
				switch(view.type) {
					case "file":
						if(_fileList.length == 0) this.renderEditor();
						if(!R8.Utils.inArray(_fileList,view.id)) _fileList.push(view.id);

//						view.contentId = _id+'-'+view.id;
						_views[view.id] = new R8.IDE.View.file(view);
						break;
					case "target":
						_views[view.id] = new R8.IDE.View.target(view);
						break;
					case "component":
						_views[view.id] = new R8.IDE.View.component(view);
						break;
				}
*/

				var viewContent = _views[view.get('id')].render();
				if(viewContent != '') _contentNode.append(viewContent);
				_views[view.get('id')].init();

				this.addTab(view.get('id'));
				this.setViewFocus(view.get('id'));
			},
			loadFileView: function(view) {
				if (this.viewIsLoaded(view.id)) {
					this.setViewFocus(view.id);
					return;
				}
				if(this.numViews() == 0) _contentNode.set('innerHTML','');

				view.panel = this;
				switch(view.type) {
					case "file":
						if(_fileList.length == 0) this.renderEditor();
						if(!R8.Utils.inArray(_fileList,view.id)) _fileList.push(view.id);

//						view.contentId = _id+'-'+view.id;
						_views[view.id] = new R8.IDE.View.file(view);
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
//TODO: revisit to implement purge functionality
				delete(_views[viewId]);

/*				if(viewId == _currentView) _currentView = null;
				if(this.numViews() == 0) {
					_contentNode.append(_emptyContentTpl);
					_lastView = null;
				} else {
					this.setViewFocus(_lastView);
				}
*/
				if(viewId == _currentView) {
					_currentView = null;
					if(this.numViews() == 0) {
						_contentNode.append(_emptyContentTpl);
						_lastView = null;
					} else if(typeof(_views[_lastView]) == 'undefined') {
						this.setViewFocus(this.get('firstView'));
					} else {
						this.setViewFocus(_lastView);
					}
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
			renderEditor: function() {
					var editorTpl = '<div id="'+_id+'-editor-wrapper" class="editor-wrapper"></div>';
					_contentNode.append(editorTpl);

					var cfg = {'editorWrapperNodeId': _id+'-editor-wrapper','containerNodeId': _contentNode.get('id')};
					R8.Editor.init(cfg);
			},
			setFileContent: function(fileId,fileContent) {
				_views[fileId]['content'] = fileContent;
			}
		}
	};
}