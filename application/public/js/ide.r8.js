
if (!R8.IDE) {

	R8.IDE = function() {
		var _pageContainerNode = null,
			_topbarNode = null,
			_mainBodyWrapperNode = null,
			_viewportRegion = null,

			_mblPaneMinWidth = 150,
			_mblPaneMinHeight = 200,
			_mblPanelNode = null,

			_mbMainPaneMinWidth = 300,
			_mbMainPaneMinHeight = 100,
			_mbMainPanelNode = null,

			_editorPaneMinWidth = 300,
			_editorPaneMinHeight = 100,
			_editorPanelNode = null,

			_consolePaneMinWidth = 300,
			_consolePaneMinHeight = 100,
			_consolePanelNode = null,

			_spacerWidth = 3,

			_projects = [],
//panel content specific.., should be moved out of here after flushing out details
			_projectViewNode = null,

			_events = {};

		return {
			init: function(projects) {
				R8.UI.init();

				_pageContainerNode = R8.Utils.Y.one('#page-container');
				_mainBodyWrapperNode = R8.Utils.Y.one('#main-body-wrapper');
				_topbarNode = R8.Utils.Y.one('#page-topbar');

				_mblPanelNode = R8.Utils.Y.one('#mb-l-panel');
				_mbMainPanelNode = R8.Utils.Y.one('#mb-main-panel');

				_editorPanelNode = R8.Utils.Y.one('#editor-panel');
				_consolePanelNode = R8.Utils.Y.one('#console-panel');

				_mbLSpacerNode = R8.Utils.Y.one('#l-panel-spacer');
				_spacerWidth = _mbLSpacerNode.get('region').width;
//				_mbRSpacerNode = R8.Utils.Y.one('#mb-panel-r-spacer');

//				_mbContentWrapperNode = R8.Utils.Y.one('#mb-content-wrapper');
//				_mbMainContentNode = R8.Utils.Y.one('#mb-main-content');

//TODO: revisit to have pluggable clean setup after more fully implementing IDE
				_projects = projects;
				this.initPanelContents();

				var that = this;
				R8.Utils.Y.one(window).on('resize',function(e){
					that.resizePage();
				});
				this.resizePage();

				this.panelResizeInit();
//				R8.Editor.init();
			},
			initPanelContents: function() {
				_projectViewNode = R8.Utils.Y.one('#project-view-content');
//				this.renderProjects();

				this.renderEditor();
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

				_mblPanelNode.setStyle('height',mainBodyWrapperHeight);
				var mblPanelWidth = _mblPanelNode.get('region').width;

				var mainPanelWidth = vportWidth - mblPanelWidth - _spacerWidth;

				_mbMainPanelNode.setStyles({'height':mainBodyWrapperHeight,'width':mainPanelWidth});

				var editorNodeHeight = mainBodyWrapperHeight - (_consolePanelNode.get('region').height+_spacerWidth);
				_editorPanelNode.setStyle('height',editorNodeHeight);

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
						var mblPanelWidth = (e.pageX < _mblPaneMinWidth) ? _mblPaneMinWidth : e.pageX;

						var mbMWidth = _viewportRegion.width-(mblPanelWidth+_spacerWidth);
						mbMWidth = (mbMWidth < _mbMainPaneMinWidth) ? _mbMainPaneMinWidth : mbMWidth;

						_mblPanelNode.setStyle('width',(_viewportRegion.width-(mbMWidth+_spacerWidth)));
						_mbMainPanelNode.setStyle('width',(_viewportRegion.width-(_mblPanelNode.get('region').width+_spacerWidth)));

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
						var editorHeight = e.pageY - _mbMainPanelNode.get('region').top;
						editorHeight = (editorHeight < _editorPaneMinHeight) ? _editorPaneMinHeight : editorHeight;

						var consoleHeight =  _mbMainPanelNode.get('region').height - (_editorPanelNode.get('region').height+_spacerWidth);
						consoleHeight = (consoleHeight < _consolePaneMinHeight) ? _consolePaneMinHeight : consoleHeight;

						_editorPanelNode.setStyle('height',editorHeight);
						_consolePanelNode.setStyle('height',(_mbMainPanelNode.get('region').height - (_editorPanelNode.get('region').height+_spacerWidth)));

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
						var region = _mblPanelNode.get('region');
						region.top = region.top + tabsHeight;
						region.height = region.height - tabsHeight;
						break;
				}
				return region;
			},
			renderProjects: function() {
//DEBUG
//console.log(_projects);
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
				_projectViewNode.setStyles({'height':panelRegion.height-6,'width':panelRegion.width});

				R8.Editor.resizePage();
			}
		}
	}();
}
