
if (!R8.IDE) {

	R8.IDE = function() {
		var _pageContainerNode = null,
			_topbarNode = null,
			_mainBodyWrapperNode = null,
			_viewportRegion = null,

			_modalNode = null,
			_modalNodeId = 'ide-modal',
			_shimNodeId = null,
			_shimNode = null,

			_alertNode = null,
			_alertNodeId = null,

			_lRegionMinWidth = 150,
			_lRegionMinHeight = 200,
			_lRegionNode = null,
//			_lRegionHeaderNode = null,
//			_lPanelContentNode = null,
			_lRegionPanels = {},

			_lResizerNode = null,
			_panelsResizerDD = null,

			_mainRegionMinWidth = 300,
			_mainRegionMinHeight = 100,
			_mainRegionNode = null,
//			_mainPanelHeaderNode = null,
//			_mainPanelContentNode = null,
			_mainRegionPanels = {},

			_editorRegionNode = null,

			_bottomPaneMinWidth = 300,
			_bottomPaneMinHeight = 100,
			_bottomPanelNode = null,
			_bottomPanelHeaderNode = null,
			_bottomPanelContentNode = null,
			_bottomViewList = {},

			_resizerWidth = 3,

//			_projects = [],
			_projects = {},
			_loadedProjects = {},

			_panels = {},

			_openItems =  {},
//panel content specific.., should be moved out of here after flushing out details
			_projectViewNode = null,

			_editorPanelActive = false,
			_consolePanelActive = false,

			_regions = {
				'top_full': {
					'numPanels':0,
					'panelsRendered':0,
					'heightRemaining': 1
				},
				'top': {
					'numPanels':0,
					'panelsRendered':0,
					'heightRemaining': 1
				},
				'bottom': {
					'numPanels':0,
					'panelsRendered':0,
					'heightRemaining': 1
				},
				'bottom_full': {
					'numPanels':0,
					'panelsRendered':0,
					'heightRemaining': 1
				},
				'left': {
					'numPanels':0,
					'panelsRendered':0,
					'heightRemaining': 1
				},
				'right': {
					'numPanels':0,
					'panelsRendered':0,
					'heightRemaining': 1
				},
				'main': {
					'numPanels':0,
					'panelsRendered':0,
					'heightRemaining': 1
				}
			},
/*
			_ide_events = {
				'node-add':'1',
				'node-edit':'1',
				'component-add':'1',
				'component-edit':'1'
			},
*/
//EVENT HANDLING
			_eventCallbacks = {},

//END EVENT HANDLING
			_events = {};

			var layoutDef = {
				'panels': [
				{
//					'id': 'l-panel',
					'id': 'l-panel-content',
					'tplName': 'l_panel',
					'minHeight': 200,
					'minWidth': 150,
					'relativePos': 'left',
					'views': [{
						'id': 'projects',
						'label': 'Projects',
						'view': 'projectsView',
						'method': 'renderProjectTree'
					}
					],
					'viewFocus': 'projects'
				},
				{
					'id': 'editor-panel',
					'type': 'editor',
					'pClass': '',
					'minHeight': 100,
					'minWidth': 300,
					'relativePos': 'main',
//					'defaultHeight': .80,
					'views': [
/*
					{
						'id': 'editor',
						'label': 'Editor',
						'view': 'editorView',
						'method': 'renderEditor',
						'resizeMethod': 'resizeEditor'
					}
*/
					],
					'viewFocus': 'editor'
				}
/*				 {
					'id': 'console-panel',
//					'pClass': 'tempclass',
					'pClass': '',
					'type': 'console',
					'minHeight': 100,
					'minWidth': 300,
					'defaultHeight': .20,
					'relativePos': 'main',
					'views': [
					{
						'id': 'chef_debugger',
						'label': 'Chef Debugger',
						'view': 'chefDebuggerView',
						'method': 'renderChefDebugger'
					}

					],
//					'viewFocus': 'chef_debugger'
				}
*/				]
			};

/*
			_lPanelMinWidth = 150,
			_lPanelMinHeight = 200,
			_lPanelNode = null,
			_lPanelHeaderNode = null,
			_lPanelContentNode = null,
			_lPanelList = {},

			_mainPanelMinWidth = 300,
			_mainPanelMinHeight = 100,
			_mainPanelNode = null,
			_mainPanelHeaderNode = null,
			_mainPanelContentNode = null,
			_mainPanelList = {},

			_consolePaneMinWidth = 300,
			_consolePaneMinHeight = 100,
			_consolePanelNode = null,
			_consolePanelHeaderNode = null,
			_consolePanelContentNode = null,
			_consolePanelList = {},
*/
		return {
			init: function(projects) {
				R8.UI.init();


				var toolbarDef = {
					'toolbarNodeId': 'menu-bar-body'
				};
				R8.Topbar2.init(toolbarDef);

				for(var i in projects) {
					_projects[projects[i].id] = new R8.Project(projects[i]);
					_projects[projects[i].id].init();
				}
//				var _lPanelContentNode = R8.Utils.Y.one('#l-panel-content');
//				this.views.renderProjectTree(_lPanelContentNode);

				_pageContainerNode = R8.Utils.Y.one('#page-container');
				_mainBodyWrapperNode = R8.Utils.Y.one('#main-body-wrapper');
				_topbarNode = R8.Utils.Y.one('#page-topbar');

/*
				this.preProcessPanels();
				for(var i in layoutDef.panels) {
					var pDef = layoutDef.panels[i],
						pId = pDef.id;

					_panels[pId] = new R8.Panel(pDef);
					_mainBodyWrapperNode.append(_panels[pId].render());
				}
*/


//Init Panel Nodes, should probalby be objectified in near future
//				_lRegionNode = R8.Utils.Y.one('#l-region');
//				_lRegionNode = R8.Utils.Y.one('#l-panel-content');

//				_mainRegionNode = R8.Utils.Y.one('#main-region');

//				_consolePanelNode = R8.Utils.Y.one('#console-panel');

				var lPanelDef = {
					'id': 'l-panel',
					'tplName': 'l_panel',
					'minHeight': 200,
					'minWidth': 150,
					'relativePos': 'left',
					'views': [{
						'id': 'projects',
						'label': 'Projects',
						'view': 'projectsView',
						'method': 'renderProjectTree'
					}
					],
					'viewFocus': 'projects'
				};
				_panels['left'] = new R8.IDE.leftPanel(lPanelDef);
				_mainBodyWrapperNode.append(_panels['left'].render());
				_panels['left'].init();

				var resizeTpl = '\
					<div id="l-resizer" class="v-region-resizer">\
						<div class="lines"></div>\
					</div>';

				_mainBodyWrapperNode.append(resizeTpl);
				_lResizerNode = R8.Utils.Y.one('#l-resizer');
				_resizerWidth = _lResizerNode.get('region').width;


				var ePanelDef = {
					'id': 'editor-panel',
					'tplName': 'editor_panel',
					'type': 'editor',
					'pClass': '',
					'minHeight': 100,
					'minWidth': 300,
					'relativePos': 'main',
//					'defaultHeight': .80,
					'views': [
/*
					{
						'id': 'editor',
						'label': 'Editor',
						'view': 'editorView',
						'method': 'renderEditor',
						'resizeMethod': 'resizeEditor'
					}
*/
					],
					'viewFocus': 'editor'
				};
				_panels['editor'] = new R8.IDE.editorPanel(ePanelDef);
				_mainBodyWrapperNode.append(_panels['editor'].render());
				_panels['editor'].init();

				_lRegionNode = R8.Utils.Y.one('#l-panel-wrapper');
				_editorRegionNode = R8.Utils.Y.one('#editor-panel-wrapper');

				this.setupEvents();
				this.resizePage();

				R8.Utils.Y.one(window).on('resize',function(e){
					this.resizePage();
				},this);

//				this.setPanelSizings();


//TODO: revisit to have pluggable clean setup after more fully implementing IDE
//				this.initPanelContents();
//-------END INIT OF PANEL CONTENTS----------------------

//				this.setupPanels();

//				this.initPanels();
/*

				var that = this;
				R8.Utils.Y.one(window).on('resize',function(e){
					that.resizePage();
				});
				this.resizePage();

				this.initPanels();
				this.panelResizeInit();
*/
//				R8.Editor.init();
			},
			setupEvents: function() {
				var _this = this;
				YUI(YUI_config).use('dd',function(Y){
					_panelsResizerDD = new Y.DD.Drag({
						node: '#l-resizer'
					});
					_panelsResizerDD.plug(Y.Plugin.DDProxy, {
						moveOnEnd: false,
						borderStyle: false,
						cloneNode: true
					});
					_panelsResizerDD.on('drag:start',function(e){
						var drag = this.get('dragNode');
						drag.setStyle('border',0);
						drag.set('innerHTML','');
					});

					_panelsResizerDD.on('drag:drag',function(e){
						var lPanelNode = _panels['left'].get('panelNode'),
							ePanelNode = _panels['editor'].get('panelNode'),
							viewportRegion = _pageContainerNode.get('viewportRegion');

						var x1 = e.pageX;
						var x2 = lPanelNode.get('region').left;
						var newWidth = x1-x2-10;
						var newEditorWidth = viewportRegion.width-(30+lPanelNode.get('region').width+_lResizerNode.get('region').width);

//DEBUG
//console.log('editorNodeId:'+lPanelNode.get('id'));
//console.log('new editor width:'+newEditorWidth);
						lPanelNode.setStyle('width',newWidth+'px');
						ePanelNode.setStyle('width',newEditorWidth+'px');

						_panels['left'].resize();
						_panels['editor'].resize();

//						_this.resizePage();
/*
						Y.all('#'+_panelNodeId+' .width-resizer').each(function(){
							var widthOffset = this.getAttribute('data-resize-offset-width');
							widthOffset = (widthOffset == '') ? 8 : widthOffset;
							var innerWidth = newWidth - widthOffset;
							this.setStyle('width',innerWidth+'px');
						});
*/
					});
				});
			},
			get: function(key) {
				switch(key) {
					case "topbarNodeId":
						return 'page-topbar';
						break;
					case "consolePanel":
						if(!_consolePanelActive) return null;
						for(var p in _mainRegionPanels) {
							if(_mainRegionPanels[p].get('type') == 'console') {
								return _mainRegionPanels[p];
//								var currentView = _mainRegionPanels[p].get('currentView');
//								if(currentView != null) return currentView;
//								else return null;
							}
						}
						return null;
						break;
					case "editorRegionNode":
						return _editorRegionNode;
						break;
					case "currentEditorView":
/*						if(!_editorPanelActive) return null;

						for(var p in _mainRegionPanels) {
							if(_mainRegionPanels[p].get('type') == 'editor') {
								var currentView = _mainRegionPanels[p].get('currentView');
								if(currentView != null) return currentView;
								else return null;
							}
						}
*/
						var currentView = _panels['editor'].get('currentView');
						if(currentView != null) return currentView;

						return null;
						break;
					case "nodesInEditor":
						var nodeList = [];
						if(!_editorPanelActive) return nodeList;

						for(var p in _mainRegionPanels) {
							if(_mainRegionPanels[p].get('type') == 'editor') {
								var views = _mainRegionPanels[p].get('views');

								for(var v in views) {
									if(views[v].get('type') != 'target') continue;
									var items = views[v].get('items');

									for(var i in items) {
										if(items[i].get('type') == 'node') {
											nodeList.push(items[i].get('object'));
										}
									}
								}
							}
						}
						return nodeList;
						break;
				}
			},
			purgeEvent: function(eventName,id) {
				if(typeof(_eventCallbacks[eventName]) == 'undefined') return;

				for(var i in _eventCallbacks[eventName]) {
					var eventObj = _eventCallbacks[eventName][i];
					if(eventObj.id == id) {
						R8.Utils.arrayRemove(_eventCallbacks[eventName],i);
					}
				}
			},
			clearEvent: function(eventName) {
				delete(_eventCallbacks[eventName]);
			},
			on: function(eventName,callback,scope) {
				if(typeof(_eventCallbacks[eventName]) == 'undefined') _eventCallbacks[eventName] = [];

				var eventObj = {
					'id': R8.Utils.Y.guid(),
					'callback': callback,
					'scope': scope
				}
				_eventCallbacks[eventName].push(eventObj);

				var _this = this;
				var retObj = {
					'id': eventObj.id,
					'eventName': eventName,
					'detach': function() {
						_this.purgeEvent(this.eventName,this.id)
					}
				}
			},
			fire: function(eventName,eventObj) {
//DEBUG
//console.log('going to fire  event:'+eventName+' with params:');
//console.log(eventObj);
//console.log('-------------------');
				for(var i in _eventCallbacks[eventName]) {
					var callbackObj = _eventCallbacks[eventName][i];
					if(typeof(callbackObj.scope) != 'undefined') {
						callbackObj.callback.call(callbackObj.scope,eventObj);
					}
				}
			},
			setupPanels: function() {
//				this.setPanelCounts();
				this.setPanelSizings();
				this.renderPanels();
//				this.initPanels();
//				this.sizeRegions();
			},
			sizeRegions: function() {
				
			},
			initPanels: function() {
				for (var i in layoutDef.panels) {
					var pDef = layoutDef.panels[i];

					switch (pDef.relativePos) {
						case "left":
							_lRegionPanels[pDef.id].init();
							break;
						case "main":
							_mainRegionPanels[pDef.id].init();
							break;
					}
				}
			},
			resizePanels: function(resizeType) {
				this.setPanelSizings();

				for (var i in layoutDef.panels) {
					var pDef = layoutDef.panels[i];

					var tempNode = R8.Utils.Y.one('#'+pDef.id);
//TODO: revisit, should push resizing function down to actual object to update
					if(typeof(resizeType) == 'undefined') {
						tempNode.setStyles({'height':pDef.height,'width':pDef.width});
					} else if(resizeType == 'width') {						
						tempNode.setStyles({'width':pDef.width});
					} else if(resizeType == 'height') {
						tempNode.setStyles({'height':pDef.height});
					}
					_panels[pDef.id].resize(resizeType);
				}
			},
			setPanelCounts: function() {
				for(var i in layoutDef.panels) {
					var pDef = layoutDef.panels[i];

					switch(pDef.relativePos) {
						case "top":
							_regions.top.numPanels++;
							break;
						case "top_full":
							_regions.top_full.numPanels++;
							break;
						case "bottom":
							_regions.bottom.numPanels++;
							break;
						case "bottom_full":
							_regions.bottom_full.numPanels++;
							break;
						case "left":
							_regions.left.numPanels++;
							break;
						case "right":
							_regions.right.numPanels++;
							break;
						case "main":
							_regions.main.numPanels++;
							break;
					}
				}
			},
			setPanelSizings: function() {
				var containerRegion = _mainBodyWrapperNode.get('region');

				for(var i in layoutDef.panels) {
					var pDef = layoutDef.panels[i];

					switch(pDef.relativePos) {
						case "top":
							var resizerOffset = (_numBtmPanels > 0) ? (_numBtmPanels*_resizerWidth) : _resizerWidth;
							pDef.height = Math.floor(containerRegion.height*.75)-resizerOffset;

							var numResizers = 0, widthOffset = 0;
							if (_numLeftPanels > 0) {
								numResizers++;
								widthOffset = widthOffset + 0.25;
							}
/*
							if (_numLeftPanels > 0) {
								numResizers++;
								widthOffset = widthOffset + 0.25;
							}
*/
							resizerOffset = numResizers*_resizerWidth;
							pDef.width = Math.floor(containerRegion.width*widthOffset)-resizerOffset;
							break;
						case "right":
							var resizerOffset = (_numRightPanels-1)*_resizerWidth;
							pDef.height = Math.floor(containerRegion.height/_numRightPanels)-resizerOffset;

							resizerOffset = (_numLeftPanels > 0) ? (2*_resizerWidth) : _resizerWidth;
							pDef.width = Math.floor(containerRegion.width*0.25)-resizerOffset;
							break;
						case "bottom":
							var resizerOffset = (_numTopPanels > 0) ? (_numTopPanels*_resizerWidth) : _resizerWidth;
							pDef.height = Math.floor(containerRegion.height*.75)-resizerOffset;

							var numResizers = 0, widthOffset = 0;
							if (_numLeftPanels > 0) {
								numResizers++;
								widthOffset = widthOffset + 0.25;
							}
							if (_numLeftPanels > 0) {
								numResizers++;
								widthOffset = widthOffset + 0.25;
							}

							resizerOffset = numResizers*_resizerWidth;
							pDef.width = Math.floor(containerRegion.width*widthOffset)-resizerOffset;
							break;
						case "left":
							var containerRegion = _lRegionNode.get('region');
							var resizerOffset = (_regions.left.numPanels-1)*_resizerWidth;
							pDef.height = Math.floor((containerRegion.height-resizerOffset)/_regions.left.numPanels);

//							resizerOffset = (_regions.right.numPanels > 0) ? (2*_resizerWidth) : _resizerWidth;
//							pDef.width = Math.floor(containerRegion.width*0.25)-resizerOffset;
							pDef.width = containerRegion.width;
							break;
						case "main":
							var containerRegion = _mainRegionNode.get('region');
							var resizerOffset = (_regions.main.numPanels-1)*_resizerWidth;

//							pDef.height = Math.floor((containerRegion.height-resizerOffset)*pDef.defaultHeight);
							pDef.height = Math.floor((containerRegion.height-resizerOffset)/_regions.main.numPanels);

							pDef.width = containerRegion.width;
							break;
					}
					layoutDef.panels[i] = pDef;
				}
			},
			renderPanels: function() {
				for (var i in layoutDef.panels) {
					var pDef = layoutDef.panels[i];
					switch(pDef.type) {
						case "editor":
//DEBUG
//							_editorPanelActive = true;
							_panels[pDef.id] = new R8.IDE.editorPanel(pDef);
							break;
						case "console":
							_consolePanelActive = true;
							_panels[pDef.id] = new R8.IDE.consolePanel(pDef);
							break;
						default:
							_panels[pDef.id] = new R8.IDE.panel(pDef);
							break;
					}

					switch (pDef.relativePos) {
						case "left":
//							if(_regions.left.panelsRendered > 0) {
//								_lRegionNode.append('<div id="lr-resizer-'+_regions.left.panelsRendered+'" class="h-region-resizer"></div>');
//							}
//							_panels[pDef.id] = new R8.IDE.panel(pDef);
							_lRegionPanels[pDef.id] = _panels[pDef.id];
//							_lRegionPanels[pDef.id] = new R8.IDE.panel(pDef);
//DEBUG
//console.log(pDef);

//							_lRegionNode.append(_lRegionPanels[pDef.id].render());
							_regions.left.panelsRendered++;
							break;
						case "main":
//							if(_regions.main.panelsRendered > 0) {
//								_mainRegionNode.append('<div id="mr-resizer-'+_regions.main.panelsRendered+'" class="h-region-resizer"></div>');
//							}
//							_panels[pDef.id] = new R8.IDE.panel(pDef);
							_mainRegionPanels[pDef.id] = _panels[pDef.id];
//							_mainRegionPanels[pDef.id] = new R8.IDE.panel(pDef);

//DEBUG - porting over new UI
//							_mainRegionNode.append(_mainRegionPanels[pDef.id].render());
							_regions.main.panelsRendered++;
							break;
					}
				}
			},

			initPanelContents: function() {
				_projectViewNode = R8.Utils.Y.one('#project-view-content');
//				this.renderProjects();

//				this.renderEditor();
			},
			testTree: function() {
				$('#project-view-content').jstree({
					'core': {'animation':0},
					'plugins': ["themes","html_data"],
					'themes': {
						'theme': "default",
						'dots': false
					}
				});
			},
			resizePage: function() {
				_viewportRegion = _pageContainerNode.get('viewportRegion');

				var vportHeight = _viewportRegion['height'];
				var vportWidth = _viewportRegion['width'];

				var topbarRegion = _topbarNode.get('region');
				var mainBodyWrapperHeight = vportHeight - (topbarRegion['height']);
				_mainBodyWrapperNode.setStyles({'height':mainBodyWrapperHeight});

				var _lRegionHeightMargin = 20;
				var _lRegionWidthMargin = 15;
				var lPanelHeight = mainBodyWrapperHeight-_lRegionHeightMargin;
				_lRegionNode.setStyle('height',lPanelHeight);

				var lPanelHeaderNode = R8.Utils.Y.one('#l-panel-header');
				var lPanelHeaderRegion = lPanelHeaderNode.get('region');
				var lPanelContentNode = R8.Utils.Y.one('#l-panel-content');
				var lPanelContentRegion = lPanelContentNode.get('region');

				lPanelContentNode.setStyle('height',(lPanelHeight-lPanelHeaderRegion.height+2));

				var _editorRegionHeightMargin = 15;
				var _editorRegionWidthMargin = 15;
				var resizeWidth = _lResizerNode.get('region').width;
				var lPanelRegion = _lRegionNode.get('region');

				var editorPanelWidth = vportWidth - (lPanelRegion.width+_lRegionWidthMargin+resizeWidth+_editorRegionWidthMargin);
				var editorPanelHeight = mainBodyWrapperHeight-_editorRegionHeightMargin;
				_lRegionNode.setStyle('height',lPanelHeight);
				_editorRegionNode.setStyles({'height':editorPanelHeight,'width':editorPanelWidth});

				var editorPanelHeaderNode = R8.Utils.Y.one('#editor-panel-header');
				var editorPanelHeaderRegion = editorPanelHeaderNode.get('region');
				var editorPanelContentNode = R8.Utils.Y.one('#editor-panel-content');
				var editorPanelContentRegion = editorPanelContentNode.get('region')

//				editorPanelHeaderNode.setStyle('width',editorPanelWidth-2);
				editorPanelContentNode.setStyles({
//					'width': editorPanelWidth,
					'height': (editorPanelHeight - (editorPanelHeaderRegion.height + 2))
				});

				var e = {
					'editorRegion': _editorRegionNode.get('region'),
					'contentRegion': editorPanelContentNode.get('region')
				};
				R8.IDE.fire('editorResize',e);
/*
				var lRegionWidth = _lRegionNode.get('region').width;
				var mainRegionWidth = vportWidth - lRegionWidth - _resizerWidth;
				_mainRegionNode.setStyles({'height':mainBodyWrapperHeight,'width':mainRegionWidth});
*/

//				var editorNodeHeight = mainBodyWrapperHeight - (_consolePanelNode.get('region').height+_resizerWidth);
//				_mainPanelNode.setStyle('height',editorNodeHeight);

//TODO: revisit to cleanup after more fully implementing IDE
//				this.resizePanelContent();

//				this.resizePanels();
			},
			panelResizeInit: function() {
				var _this = this;
				YUI().use('dd',function(Y){
					var leftResizer = new Y.DD.Drag({
						node: '#l-resizer',
						
					}).plug(Y.Plugin.DDConstrained, {
						stickX: true
					}).plug(Y.Plugin.DDProxy, {
						moveOnEnd: false,
//						borderStyle: false,
					});
					leftResizer.on('drag:end',function(e){
//						var lRegionWidth = (e.pageX < _lPanelMinWidth) ? _lPanelMinWidth : e.pageX;
						var lRegionWidth = e.pageX;

//						var mainWidth = _viewportRegion.width-(mblPanelWidth+_resizerWidth);
//						mainWidth = (mainWidth < _mainPanelMinWidth) ? _mainPanelMinWidth : mainWidth;
						var mainWidth = _viewportRegion.width-(lRegionWidth+_resizerWidth);

						_lRegionNode.setStyle('width',(_viewportRegion.width-(mainWidth+_resizerWidth)));
						_mainRegionNode.setStyle('width',(_viewportRegion.width-(_lRegionNode.get('region').width+_resizerWidth)));

						_this.resizePanels('width');
					});

//DEBUG
//begin console panel handling
					var editorResizer = new Y.DD.Drag({
						node: '#mr-resizer-1'
					}).plug(Y.Plugin.DDConstrained, {
						stickY: true
					}).plug(Y.Plugin.DDProxy, {
						moveOnEnd: false,
//						borderStyle: false,
					});
					editorResizer.on('drag:end',function(e){
						var editorHeight = e.pageY - _mainRegionNode.get('region').top;
//						editorHeight = (editorHeight < _mainPanelMinHeight) ? _mainPanelMinHeight : editorHeight;

//						var consoleHeight =  _mainRegionNode.get('region').height - (_mainRegionNode.get('region').height+_resizerWidth);
//						consoleHeight = (consoleHeight < _consolePaneMinHeight) ? _consolePaneMinHeight : consoleHeight;

						var editorPanelNode = R8.Utils.Y.one('#editor-panel');
						editorPanelNode.setStyle('height',editorHeight);

						var consolePanelNode = R8.Utils.Y.one('#console-panel');
						consolePanelNode.setStyle('height',(_mainRegionNode.get('region').height - (editorPanelNode.get('region').height+_resizerWidth)));

						_mainRegionPanels['editor-panel'].resize('height');
						_mainRegionPanels['console-panel'].resize('height');
//						that.resizePanels();
					});
/*
					editorResizer.on('drag:end',function(e){
						var editorPanelNode = R8.Utils.Y.one('#editor-panel');
						var editorHeight = editorPanelNode.getStyle('height');
//TODO: revisit to do more user settings work
						R8.User.setSetting('editorPanelHeight',editorHeight);
					});
*/
//end console panel handling
				});
			},
			toggleDetails: function(e) {
				var id = e.currentTarget.get('id'),
					selectedCat = id.replace('-cat','');

				if(selectedCat === _focusedIndex) return;

				for(var contentId in _contentList) {
					R8.Utils.Y.one('#'+contentId+'-cat').removeClass('selected');
					R8.Utils.Y.one('#'+contentId+'-content').setStyle('display','none');
				}

				R8.Utils.Y.one('#'+selectedCat+'-cat').addClass('selected');
				R8.Utils.Y.one('#'+selectedCat+'-content').setStyle('display','block');

				if(typeof(_contentList[_focusedIndex].blur) != 'undefined') _contentList[_focusedIndex].blur();
				_focusedIndex = selectedCat;

				if(_contentList[selectedCat].loaded != true) {
					var params = {
						'cfg':{
							'data':'panel_id='+selectedCat+'-content&'+_contentList[selectedCat].getParams(_itemId)
						}
					};
//console.log(_contentList[selectedCat].getParams(_itemId));
					R8.Ctrl.call(_contentList[selectedCat].getRoute(_itemId),params);
//					console.log(selectedCat+' content isnt loaded yet...');
				}
			},
			openFile: function(file_asset) {
//				if (_editorPanelActive) {
//					_panels['editor-panel'].loadView(file_asset);
					_panels['editor'].loadFileView(file_asset);
//				}
			},
			openEditorView: function(obj,viewName) {
//				if (_editorPanelActive) {
//					_panels['editor-panel'].pushTargetView(target);
					if(typeof(viewName) != 'undefined') {
						_panels['editor'].loadView(obj.getView(viewName));
					} else {
						_panels['editor'].loadView(obj.getView('editor'));
					}
//				}
			},
			openTarget: function(target) {
				if (_editorPanelActive) {
//					_panels['editor-panel'].pushTargetView(target);
					_panels['editor-panel'].loadView(target);
				}
			},
			openComponent: function(component) {
				if (_editorPanelActive) {
					_panels['editor-panel'].loadView(component);
				}
			},
			getPanelContentRegion: function(type) {
				switch(type) {
					case "l-panel":
						var tabsHeight = 25;
						var region = _lPanelNode.get('region');
						region.top = region.top + tabsHeight;
						region.height = region.height - tabsHeight;
						break;
				}
				return region;
			},
//TODO: this is temp until implementing context based func execution
			pushConsoleView: function(viewDef) {
				if(!_consolePanelActive) return;

				for(var p in _mainRegionPanels) {
					if(_mainRegionPanels[p].get('type') == 'console') {
						_mainRegionPanels[p].loadView(viewDef);
					}
				}
			},
			refreshChefDebug: function(level) {
				var tempNode = R8.Utils.Y.one('#view-content-chef_debugger');
				this.views.renderChefDebugger(tempNode,level);
			},
			views: {
				renderEditor: function(contentNode) {
					var cfg = {'containerNodeId': contentNode.get('id')};
					R8.Editor.init(cfg);
				},
				resizeEditor: function() {
					R8.Editor.resize();
				},
				renderProjectTree: function(contentNode) {
					for (var p in _projects) {
/*						_loadedProjects[_projects[p].id] = new R8.Project(_projects[p]);

						_loadedProjects[_projects[p].id].renderTree(contentNode);
						_loadedProjects[_projects[p].id].init();
*/
						contentNode.append(_projects[p].getView('project').render());

//DEBUG : hack to see about rendering a new style of tree
//						contentNode.append(this.renderProjectTreeR8());

						_projects[p].getView('project').init();
					}
				},
				renderProjectTreeR8: function() {
					var tpl = '<div class="r8-project-tree">\
									<ul id="project-foo" class="project-container"></div>\
								</div>';

					return tpl;
				},
			    renderChefDebugger: function(contentNode,level) {
//contentNode.set('innerHTML','fooooooooooooo!!!!');
					var setLogsCallback = function(ioId,responseObj) {
						eval("var response =" + responseObj.responseText);
						var log_content = response.application_task_get_logs.content[0].content;
//console.log(log_content);
						contentNode.set('innerHTML',log_content);
//						contentNode.append(log_content);
					}
					var params = {
						'cfg': {
							'data': ''
						},
						'callbacks': {
							'io:success': setLogsCallback
						}
					};
					R8.Ctrl.call('task/get_logs/'+level,params);
				},
			},
			targetItemsAdd: function(items) {
//console.log(items);
				var consolePanel = this.get('consolePanel');
				if(consolePanel != null) {
					var configDebuggerView = consolePanel.get('configDebuggerView');
//console.log(configDebuggerView);
					if(configDebuggerView == null) return;

					for(var i in items) {
						configDebuggerView.addNode(items[i].object);
					}
				}
			},
			updateNodeName: function(nodeId,nodeName) {
				var consolePanel = this.get('consolePanel');
				if(consolePanel != null) {
					var configDebuggerView = consolePanel.get('configDebuggerView');
//console.log(configDebuggerView);
					if(configDebuggerView == null) return;

					configDebuggerView.updateNodeName(nodeId,nodeName);
				}
			},
			updateTargetNodeName: function(nodeId) {
				var newName = this.get('currentEditorView').updateItemName(nodeId);

				this.updateNodeName(nodeId,newName);
			},
			renderEditor: function() {
				R8.Editor.init({'containerNodeId':'editor-panel'});
			},
			triggerCompilation: function() {
				var consolePanel = this.get('consolePanel');
				if(consolePanel == null) return;

				var jitterView = consolePanel.get('jitterView');
				if(jitterView == null) return;

				jitterView.getCompilation();
			},
			minimizePanel: function(panelId) {
//console.log(_panels);
				_panels[panelId].minimize();
			},
			resizePanelContent: function() {
				var panelRegion = this.getPanelContentRegion('l-panel');
//				_projectViewNode.setStyles({'height':panelRegion.height-6,'width':panelRegion.width});

//				R8.Editor.resizePage();
			},
			pushPanelContent: function(contentDef) {
				switch(contentDef.panel) {
					case "main":
						_mainPanelNode.set('innerHTML',contentDef.content);
						_mainPanelList[contentDef.id] = 'foo';
						break;
				}
			},
			pushViewSpace: function(viewSpaceDef) {
				var id = viewSpaceDef['object']['id'];
				_viewSpaces[id] = new R8.ViewSpace(viewSpaceDef);
				_viewSpaces[id].init();
				_viewSpaceStack.push(id);
				_currentViewSpace = id;

				var contextTpl = '<span class="context-span">'+viewSpaceDef.i18n+' > '+viewSpaceDef.object.display_name+'</span>';
				_contextBarNode.append(contextTpl);

				if(typeof(viewSpaceDef.items) != 'undefined') {
					this.addItems(viewSpaceDef.items, id);
					_viewSpaces[id].retrieveLinks(viewSpaceDef.items);
				}

				this.refreshNotifications();
			},
			View: {},
//---------------------------------------------
//MODAL RELATED, used with toolbar and others
//---------------------------------------------
			shimify: function(nodeId) {
				var node = R8.Utils.Y.one('#'+nodeId),
					_shimNodeId = R8.Utils.Y.guid(),
					nodeRegion = node.get('region'),
					height = nodeRegion.bottom - nodeRegion.top,
					width = nodeRegion.right - nodeRegion.left;

				node.append('<div id="'+_shimNodeId+'" class="wspace-shim" style="height:'+height+'; width:'+width+'"></div>');
				_shimNode = R8.Utils.Y.one('#'+_shimNodeId);
				_shimNode.setStyle('opacity','0.8');
				var that=this;
				_shimNode.on('click',function(Y){
					that.destroyShim();
				});
			},
			destroyShim: function() {
//DEBUG
//TODO: THIS IS TEMP SOLUTION FOR MEMORY LEAK ISSUE ON COMMIT
//console.log(jQuery("#"+_modalNode.get('children').item(0).get('id')));
				jQuery("#"+_modalNode.get('children').item(0).get('id')).remove();

				_modalNode.purge(true);
				_modalNode.remove();
				_modalNode = null,

				_shimNode.purge(true);
				_shimNode.remove();
				_shimId = null;
				_shimNode = null;
			},

			renderModal: function() {
				var modalTpl = '<div id="'+_modalNodeId+'" class="wspace-modal" style="display:none;">\
									<div id="'+_modalNodeId+'-content" class="content"></div>\
								</div>',
					node = R8.Utils.Y.one('#main-body-wrapper'),
					nodeRegion = node.get('region'),
					height = nodeRegion.bottom - nodeRegion.top,
					width = nodeRegion.right - nodeRegion.left,
					mTop = Math.floor((height - 350)/2),
					mLeft = Math.floor((width-700)/2);

				this.shimify('main-body-wrapper');

				node.append(modalTpl);
				_modalNode = R8.Utils.Y.one('#'+_modalNodeId);
				_modalNode.setStyles({'top':mTop,'left':mLeft,'display':'block'});

				var contentNode = R8.Utils.Y.one('#'+_modalNodeId+'-content');

				return contentNode;
			},
			showAlert: function(alertStr) {
				_alertNodeId = R8.Utils.Y.guid();

				var alertTpl = '<div id="'+_alertNodeId+'" class="modal-alert-wrapper">\
									<div class="l-cap"></div>\
									<div class="body"><b>'+alertStr+'</b></div>\
									<div class="r-cap"></div>\
								</div>',

					nodeRegion = _mainBodyWrapperNode.get('region'),
					height = nodeRegion.bottom - nodeRegion.top,
					width = nodeRegion.right - nodeRegion.left,
					aTop = 0,
					aLeft = Math.floor((width-250)/2);

//				containerNode.append(alertTpl);
				_mainBodyWrapperNode.append(alertTpl);
				_alertNode = R8.Utils.Y.one('#'+_alertNodeId);
				_alertNode.setStyles({'top':aTop,'left':aLeft,'display':'block'});
//return;
				YUI().use('anim', function(Y) {
					var anim = new Y.Anim({
						node: '#'+_alertNodeId,
						to: { opacity: 0 },
						duration: .7
					});
					anim.on('end', function(e) {
						var node = this.get('node');
						node.get('parentNode').removeChild(node);
					});
					var delayAnimRun = function(){
							anim.run();
						}
					setTimeout(delayAnimRun,2000);
				});
//				alert(alertStr);
			},
//---------------------------------------------
//IDE Toolbar button related
//---------------------------------------------
			initCreateProject: function() {
console.log('hello there......');
			}
		}
	}();
}
