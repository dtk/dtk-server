
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

			_lRegionMinWidth = 150,
			_lRegionMinHeight = 200,
			_lRegionNode = null,
//			_lRegionHeaderNode = null,
//			_lPanelContentNode = null,
			_lRegionPanels = {},

			_lResizerNode = null,

			_mainRegionMinWidth = 300,
			_mainRegionMinHeight = 100,
			_mainRegionNode = null,
//			_mainPanelHeaderNode = null,
//			_mainPanelContentNode = null,
			_mainRegionPanels = {},

			_bottomPaneMinWidth = 300,
			_bottomPaneMinHeight = 100,
			_bottomPanelNode = null,
			_bottomPanelHeaderNode = null,
			_bottomPanelContentNode = null,
			_bottomViewList = {},

			_resizerWidth = 3,

			_projects = [],
			_loadedProjects = {},

			_panels = {},

			_openItems =  {},
//panel content specific.., should be moved out of here after flushing out details
			_projectViewNode = null,

			_editorPanelActive = false,

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

			_events = {};

			var layoutDef = {
				'panels': [{
					'id': 'l-panel',
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
				}
				,{
					'id': 'editor-panel',
					'type': 'editor',
					'pClass': 'foobut',
					'minHeight': 100,
					'minWidth': 300,
					'relativePos': 'main',
					'defaultHeight': .80,
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
				},
/*				 {
					'id': 'console-panel',
					'pClass': 'tempclass',
					'minHeight': 100,
					'minWidth': 300,
					'relativePos': 'main',
					'views': [{
						'id': 'chef_debugger',
						'label': 'Chef Debugger',
						'view': 'chefDebuggerView',
						'method': 'renderChefDebugger'
					}
					],
					'viewFocus': 'chef_debugger'
				}*/
				]
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

//TODO: fogure out how to more gracefully load this
				_projects = projects;

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
				_lRegionNode = R8.Utils.Y.one('#l-region');

				_mainRegionNode = R8.Utils.Y.one('#main-region');

//				_consolePanelNode = R8.Utils.Y.one('#console-panel');

				_lResizerNode = R8.Utils.Y.one('#l-resizer');
				_resizerWidth = _lResizerNode.get('region').width;


//TODO: revisit to have pluggable clean setup after more fully implementing IDE
//				this.initPanelContents();
//-------END INIT OF PANEL CONTENTS----------------------

				this.setupPanels();

				var that = this;
				R8.Utils.Y.one(window).on('resize',function(e){
					that.resizePage();
				});
				this.resizePage();

				this.initPanels();
				this.panelResizeInit();

//				R8.Editor.init();
			},
			get: function(key) {
				switch(key) {
					case "topbarNodeId":
						return 'page-topbar';
						break;
				}
			},
			setupPanels: function() {
				this.setPanelCounts();
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
			resizePanels: function() {
				this.setPanelSizings();

				for (var i in layoutDef.panels) {
					var pDef = layoutDef.panels[i];

					var tempNode = R8.Utils.Y.one('#'+pDef.id);
//TODO: revisit, should push resizing function down to actual object to update
					tempNode.setStyles({'height':pDef.height,'width':pDef.width});
					_panels[pDef.id].resize();
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
							if (_numLeftPanels > 0) {
								numResizers++;
								widthOffset = widthOffset + 0.25;
							}

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
							_editorPanelActive = true;
							_panels[pDef.id] = new R8.IDE.editorPanel(pDef);
							break;
						default:
							_panels[pDef.id] = new R8.IDE.panel(pDef);
							break;
					}

					switch (pDef.relativePos) {
						case "left":
							if(_regions.left.panelsRendered > 0) {
								_lRegionNode.append('<div id="lr-resizer-'+_regions.left.panelsRendered+'" class="h-region-resizer"></div>');
							}
//							_panels[pDef.id] = new R8.IDE.panel(pDef);
							_lRegionPanels[pDef.id] = _panels[pDef.id];
//							_lRegionPanels[pDef.id] = new R8.IDE.panel(pDef);
							_lRegionNode.append(_lRegionPanels[pDef.id].render());
							_regions.left.panelsRendered++;
							break;
						case "main":
							if(_regions.main.panelsRendered > 0) {
								_mainRegionNode.append('<div id="mr-resizer-'+_regions.main.panelsRendered+'" class="h-region-resizer"></div>');
							}
//							_panels[pDef.id] = new R8.IDE.panel(pDef);
							_mainRegionPanels[pDef.id] = _panels[pDef.id];
//							_mainRegionPanels[pDef.id] = new R8.IDE.panel(pDef);
							_mainRegionNode.append(_mainRegionPanels[pDef.id].render());
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

				_lRegionNode.setStyle('height',mainBodyWrapperHeight);
				var lRegionWidth = _lRegionNode.get('region').width;

				var mainRegionWidth = vportWidth - lRegionWidth - _resizerWidth;

				_mainRegionNode.setStyles({'height':mainBodyWrapperHeight,'width':mainRegionWidth});

//				var editorNodeHeight = mainBodyWrapperHeight - (_consolePanelNode.get('region').height+_resizerWidth);
//				_mainPanelNode.setStyle('height',editorNodeHeight);

//TODO: revisit to cleanup after more fully implementing IDE
//				this.resizePanelContent();
				this.resizePanels();
			},
			panelResizeInit: function() {
				var that = this;
				YUI().use('dd',function(Y){
					var leftResizer = new Y.DD.Drag({
						node: '#l-resizer'
					});
					leftResizer.plug(Y.Plugin.DDProxy, {
						moveOnEnd: false,
						borderStyle: false,
					});
					leftResizer.on('drag:drag',function(e){
//						var lRegionWidth = (e.pageX < _lPanelMinWidth) ? _lPanelMinWidth : e.pageX;
						var lRegionWidth = e.pageX;

//						var mainWidth = _viewportRegion.width-(mblPanelWidth+_resizerWidth);
//						mainWidth = (mainWidth < _mainPanelMinWidth) ? _mainPanelMinWidth : mainWidth;
						var mainWidth = _viewportRegion.width-(lRegionWidth+_resizerWidth);

						_lRegionNode.setStyle('width',(_viewportRegion.width-(mainWidth+_resizerWidth)));
						_mainRegionNode.setStyle('width',(_viewportRegion.width-(_lRegionNode.get('region').width+_resizerWidth)));

						that.resizePanels();
					});
/*
					var editorResizer = new Y.DD.Drag({
						node: '#mr-resizer-1'
					});
					editorResizer.plug(Y.Plugin.DDProxy, {
						moveOnEnd: false,
						borderStyle: false,
					});
					editorResizer.on('drag:drag',function(e){
						var editorHeight = e.pageY - _mainRegionNode.get('region').top;
//						editorHeight = (editorHeight < _mainPanelMinHeight) ? _mainPanelMinHeight : editorHeight;

//						var consoleHeight =  _mainRegionNode.get('region').height - (_mainRegionNode.get('region').height+_resizerWidth);
//						consoleHeight = (consoleHeight < _consolePaneMinHeight) ? _consolePaneMinHeight : consoleHeight;

						var editorPanelNode = R8.Utils.Y.one('#editor-panel');
						editorPanelNode.setStyle('height',editorHeight);

						var consolePanelNode = R8.Utils.Y.one('#console-panel');
						consolePanelNode.setStyle('height',(_mainRegionNode.get('region').height - (editorPanelNode.get('region').height+_resizerWidth)));

						_mainRegionPanels['editor-panel'].resize();
//						that.resizePanels();
					});
					editorResizer.on('drag:end',function(e){
						var editorPanelNode = R8.Utils.Y.one('#editor-panel');
						var editorHeight = editorPanelNode.getStyle('height');

						R8.User.setSetting('editorPanelHeight',editorHeight);
					});
*/
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
				if (_editorPanelActive) {
					_panels['editor-panel'].loadView(file_asset);
				}
			},
			openTarget: function(target) {
				if (_editorPanelActive) {
//					_panels['editor-panel'].pushTargetView(target);
					_panels['editor-panel'].loadView(target);
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
						_loadedProjects[_projects[p].id] = new R8.Project(_projects[p]);
						_loadedProjects[_projects[p].id].renderTree(contentNode);
					}
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

			renderEditor: function() {
				R8.Editor.init({'containerNodeId':'editor-panel'});
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
			}
		}
	}();
}
