
if (!R8.IDE) {

	R8.IDE = function() {
		var _pageContainerNode = null,
			_topbarNode = null,
			_mainBodyWrapperNode = null,
			_viewportRegion = null,

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

			_spacerWidth = 3,

			_projects = [],

			_panels = {},

			_openItems =  {},
//panel content specific.., should be moved out of here after flushing out details
			_projectViewNode = null,

			_regions = {
				'top_full': {
					'numPanels':0
				},
				'top': {
					'numPanels':0
				},
				'bottom': {
					'numPanels':0
				},
				'bottom_full': {
					'numPanels':0
				},
				'left': {
					'numPanels':0
				},
				'right': {
					'numPanels':0
				}
			};

			_numLeftPanels = 0,
			_numTopPanels = 0,
			_numTopFullPanels = 0,
			_numRightPanels = 0,
			_numBtmPanels = 0,
			_numBtmFullPanels = 0,

			_events = {};

			var layoutDef = {
				'panels': [{
					'id': 'l-panel',
					'minHeight': 200,
					'minWidth': 150,
					'relativePos': 'left'
				}, {
					'id': 'console-panel',
					'minHeight': 100,
					'minWidth': 300,
					'relativePos': 'bottom'
				}]
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
			init: function() {
				R8.UI.init();

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
				_lPanelNode = R8.Utils.Y.one('#mb-l-panel');
//				_lPanelHeaderNode = R8.Utils.Y.one('#l-panel-header');
//				_lPanelContentNode = R8.Utils.Y.one('#l-panel-content');

				_mainPanelNode = R8.Utils.Y.one('#main-panel');
				_mainPanelHeaderNode = R8.Utils.Y.one('#main-panel-header');
				_mainPanelContentNode = R8.Utils.Y.one('#main-panel-content');

				_consolePanelNode = R8.Utils.Y.one('#console-panel');
//				_consolePanelHeaderNode = R8.Utils.Y.one('#console-panel-header');
//				_consolePanelContentNode = R8.Utils.Y.one('#console-panel-content');

				_mbLSpacerNode = R8.Utils.Y.one('#l-panel-spacer');
				_spacerWidth = _mbLSpacerNode.get('region').width;


//TODO: revisit to have pluggable clean setup after more fully implementing IDE
//				this.initPanelContents();
//-------END INIT OF PANEL CONTENTS----------------------


				var that = this;
				R8.Utils.Y.one(window).on('resize',function(e){
					that.resizePage();
				});
				this.resizePage();

				this.panelResizeInit();

//				R8.Editor.init();
			},
			preProcessPanels: function() {
				var containerRegion = _mainBodyWrapperNode.get('region');

				this.setPanelCounts();
				this.setPanelSizings();
				this.sizeRegions();
			},
			sizeRegions: function() {
				
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
					}
				}
			},
			setPanelSizings: function() {
				var containerRegion = _mainBodyWrapperNode.get('region');

				for(var i in layoutDef.panels) {
					var pDef = layoutDef.panels[i];

					switch(pDef.relativePos) {
						case "top":
							var spacerOffset = (_numBtmPanels > 0) ? (_numBtmPanels*_spacerWidth) : _spacerWidth;
							pDef.height = Math.floor(containerRegion.height*.75)-spacerOffset;

							var numResizers = 0, widthOffset = 0;
							if (_numLeftPanels > 0) {
								numResizers++;
								widthOffset = widthOffset + 0.25;
							}
							if (_numLeftPanels > 0) {
								numResizers++;
								widthOffset = widthOffset + 0.25;
							}

							spacerOffset = numResizers*_spacerWidth;
							pDef.width = Math.floor(containerRegion.width*widthOffset)-spacerOffset;
							break;
						case "right":
							var spacerOffset = (_numRightPanels-1)*_spacerWidth;
							pDef.height = Math.floor(containerRegion.height/_numRightPanels)-spacerOffset;

							spacerOffset = (_numLeftPanels > 0) ? (2*_spacerWidth) : _spacerWidth;
							pDef.width = Math.floor(containerRegion.width*0.25)-spacerOffset;
							break;
						case "bottom":
							var spacerOffset = (_numTopPanels > 0) ? (_numTopPanels*_spacerWidth) : _spacerWidth;
							pDef.height = Math.floor(containerRegion.height*.75)-spacerOffset;

							var numResizers = 0, widthOffset = 0;
							if (_numLeftPanels > 0) {
								numResizers++;
								widthOffset = widthOffset + 0.25;
							}
							if (_numLeftPanels > 0) {
								numResizers++;
								widthOffset = widthOffset + 0.25;
							}

							spacerOffset = numResizers*_spacerWidth;
							pDef.width = Math.floor(containerRegion.width*widthOffset)-spacerOffset;
							break;
						case "left":
							var spacerOffset = (_numLeftPanels-1)*_spacerWidth;
							pDef.height = Math.floor(containerRegion.height/_numLeftPanels)-spacerOffset;

							spacerOffset = (_numRightPanels > 0) ? (2*_spacerWidth) : _spacerWidth;
							pDef.width = Math.floor(containerRegion.width*0.25)-spacerOffset;
							break;
					}					
					layoutDef.panels[i] = pDef;
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

				_lPanelNode.setStyle('height',mainBodyWrapperHeight);
				var lPanelWidth = _lPanelNode.get('region').width;

				var mainPanelWidth = vportWidth - lPanelWidth - _spacerWidth;

				_mainPanelWrapperNode.setStyles({'height':mainBodyWrapperHeight,'width':mainPanelWidth});

				var editorNodeHeight = mainBodyWrapperHeight - (_consolePanelNode.get('region').height+_spacerWidth);
				_mainPanelNode.setStyle('height',editorNodeHeight);

//TODO: revisit to cleanup after more fully implementing IDE
				this.resizePanelContent();
			},
			panelResizeInit: function() {
				var that = this;
				YUI().use('dd',function(Y){
					var leftResizer = new Y.DD.Drag({
						node: '#l-panel-spacer'
					});
					leftResizer.plug(Y.Plugin.DDProxy, {
						moveOnEnd: false,
						borderStyle: false,
					});
					leftResizer.on('drag:drag',function(e){
						var mblPanelWidth = (e.pageX < _lPanelMinWidth) ? _lPanelMinWidth : e.pageX;

						var mbMWidth = _viewportRegion.width-(mblPanelWidth+_spacerWidth);
						mbMWidth = (mbMWidth < _mainPanelMinWidth) ? _mainPanelMinWidth : mbMWidth;

						_lPanelNode.setStyle('width',(_viewportRegion.width-(mbMWidth+_spacerWidth)));
						_mainPanelWrapperNode.setStyle('width',(_viewportRegion.width-(_lPanelNode.get('region').width+_spacerWidth)));

						that.resizePanelContent();
					});

					var editorResizer = new Y.DD.Drag({
						node: '#editor-panel-spacer'
					});
					editorResizer.plug(Y.Plugin.DDProxy, {
						moveOnEnd: false,
						borderStyle: false,
					});
					editorResizer.on('drag:drag',function(e){
						var editorHeight = e.pageY - _mainPanelWrapperNode.get('region').top;
						editorHeight = (editorHeight < _mainPanelMinHeight) ? _mainPanelMinHeight : editorHeight;

						var consoleHeight =  _mainPanelWrapperNode.get('region').height - (_mainPanelNode.get('region').height+_spacerWidth);
						consoleHeight = (consoleHeight < _consolePaneMinHeight) ? _consolePaneMinHeight : consoleHeight;

						_mainPanelNode.setStyle('height',editorHeight);
						_consolePanelNode.setStyle('height',(_mainPanelWrapperNode.get('region').height - (_mainPanelNode.get('region').height+_spacerWidth)));

						that.resizePanelContent();
					});
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
			addProjects: function(projects) {
//DEBUG
return;
				for(var p in projects) {
					_projects[projects[p].id] = new R8.Project(projects[p]);
					_projects[projects[p].id].renderTree(_lPanelNode);
				}
return;
				for(var p in _projects) {
					var id = _projects[p].id,
						name = _projects[p].name;

					var projectTpl = '<div id="project-'+id+'" class="project-item open">\
									  	<div class="project-icon"></div>\
										<div class="project-label">'+name+'</div>\
									  </div><br/>';

					_projectViewNode.append(projectTpl);
				}
			},
			renderEditor: function() {
				R8.Editor.init({'containerNodeId':'editor-panel'});
			},
			resizePanelContent: function() {
//DEBUG
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
			}
		}
	}();
}
