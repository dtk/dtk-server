
if (!R8.LibraryView) {

	R8.LibraryView = function() {
		var _item_id = null,
			_pageContainerNode = null,
			_topbarNode = null,
			_mainBodyWrapperNode = null,

			_detailsHeader = null,
			_contentWrapperNode = null,

			_viewportRegion = null,

			_panels = {},

//			_focusedIndex = 'node',
			_loadedView = '',
			_contentList = {
				'node': {
					'loaded': false,
					'route': 'node/list',
					'params': {
						'search_pattern': {
							':columns': [],
//							':filter': [":and",[":eq",":ancestor_id",'']],
							':order_by': [],
							':paging': {},
							':relation': 'node'
						}
					},
					getParams: function(item_id) {
						var paramStr = '';
						this.params.search_pattern[':filter'][1][2] = item_id;
						var search = {
							'search_pattern':this.params.search_pattern
						};
						var searchJsonStr = R8.Utils.Y.JSON.stringify(search);

						return 'search='+searchJsonStr;
					},
					getRoute: function() {
						return this.route
					}
				},
				'component': {
					'loaded': false,
					'route': 'component/list',
					'params': {
						'search_pattern': {
							':columns': [],
							':filter': [":and",[":eq",":ancestor_id",'']],
							':order_by': [],
							':paging': {},
							':relation': 'component'
						}
					},
					getParams: function(item_id) {
						return '';

						var paramStr = '';
						this.params.search_pattern[':filter'][1][2] = item_id;
						var search = {
							'search_pattern':this.params.search_pattern
						};
						var searchJsonStr = R8.Utils.Y.JSON.stringify(search);

						return 'search='+searchJsonStr;
					},
					getRoute: function() {
						return this.route
					}
				},
				'datacenter': {
					'loaded': false,
					'route': 'target/list',
					'params': {
						'search_pattern': {
							':columns': [],
//							':filter': [":and",[":eq",":ancestor_id",'']],
							':order_by': [],
							':paging': {},
							':relation': 'component'
						}
					},
					getParams: function(item_id) {
						var paramStr = '';
						this.params.search_pattern[':filter'][1][2] = item_id;
						var search = {
							'search_pattern':this.params.search_pattern
						};
						var searchJsonStr = R8.Utils.Y.JSON.stringify(search);

						return 'search='+searchJsonStr;
					},
					getRoute: function() {
						return this.route
					}
				}
			},

			_events = {},
			_initialized = true;
			_this = {};

		_this = R8.mixin(_this,'event');

		_this.init = function(item_id) {
			R8.UI.init();

			_item_id = item_id;

			_pageContainerNode = R8.Utils.Y.one('#page-container');
			_mainBodyWrapperNode = R8.Utils.Y.one('#main-body-wrapper');
			_topbarNode = R8.Utils.Y.one('#page-topbar');

			var panelSet = {
				parentNode: _mainBodyWrapperNode,
				panels: [
					{
						'id': 'left-panel',
						'tplName': 'ui_panel',
						'hasHeader': true,
						'minHeight': 200,
						'minWidth': 150,
						'width': 200,
						'height': '100%',
						'marginTop': 10,
						'marginBottom': 10,
						'marginLeft': 5,
						'marginRight': 5,
						'relativePos': 'left',
						'resizeable': false
					},
					{
						'id': 'main-panel',
						'tplName': 'ui_panel',
						'hasHeader': true,
						'minHeight': 200,
						'minWidth': 150,
						'marginTop': 10,
						'marginBottom': 10,
						'marginLeft': 5,
						'marginRight': 5,
						'width': 'max',
						'height': '100%',
						'relativePos': 'left',
						'resizeable': false
					}
				]
			};

			_panelSet = new R8.UI.panelSet(panelSet);
			_panelSet.render();
			_panelSet.init();
/*
				var resizeTpl = '\
					<div id="l-resizer" class="v-region-resizer">\
						<div class="lines"></div>\
					</div>';

				_mainBodyWrapperNode.append(resizeTpl);
				_lResizerNode = R8.Utils.Y.one('#l-resizer');
				_resizerWidth = _lResizerNode.get('region').width;
*/

			_lRegionNode = R8.Utils.Y.one('#l-panel-wrapper');

			this.resizePage();

			var lPanel = _panelSet.getPanelById('left-panel');
			lPanel.set('headerText','Library Objects');

			var testTpl = '<div id="library-category-list" class="library-category-list">\
					<div id="node-cat" class="library-cat active"><div class="cat-label">Nodes</div></div>\
					<div id="component-cat" class="library-cat"><div class="cat-label">Components</div></div>\
					<div id="datacenter-cat" class="library-cat"><div class="cat-label">Targets</div></div>\
				</div>';

			lPanel.set('bodyContent',testTpl);

			this.setupEvents();
			_initialized = true;
		};

		_this.setupEvents = function() {
			R8.Utils.Y.one(window).on('resize',function(e){
				this.resizePage();
			},this);

//			R8.Utils.Y.one('#'+_item_id+'-cat').addClass('selected');
			_events['catClick'] = R8.Utils.Y.delegate('click',this.loadView,'#library-category-list','.library-cat');
		};

		_this.resizePage = function() {
				_viewportRegion = _pageContainerNode.get('viewportRegion');

				var vportHeight = _viewportRegion['height'];
				var vportWidth = _viewportRegion['width'];

				var topbarRegion = _topbarNode.get('region');
				var mainBodyWrapperHeight = vportHeight - (topbarRegion['height']);
				_mainBodyWrapperNode.setStyles({'height':mainBodyWrapperHeight});

				_panelSet.resize();
		};

		_this.loadNewViewKeep = function(e) {
			var id = e.currentTarget.get('id'),
				selectedCat = id.replace('-cat','');

			if(selectedCat === _focusedIndex) return;

			var route = R8.config['base_uri']+'/'+selectedCat+'/list';
			window.location=route;
		};
		_this.loadView = function(e) {
				var id = e.currentTarget.get('id'),
					selectedCat = id.replace('-cat','');

				if(selectedCat === _loadedView) return;

				for(var contentId in _contentList) {
					R8.Utils.Y.one('#'+contentId+'-cat').removeClass('active');
//					R8.Utils.Y.one('#'+contentId+'-content').setStyle('display','none');
				}

				R8.Utils.Y.one('#'+selectedCat+'-cat').addClass('active');
//				R8.Utils.Y.one('#'+selectedCat+'-content').setStyle('display','block');

				if(_loadedView != '') {
					if(typeof(_contentList[_loadedView].blur) != 'undefined') _contentList[_loadedView].blur();
				}
				_loadedView = selectedCat;

				if(_contentList[selectedCat].loaded != true) {
					var params = {
						'cfg': {
//							'data':'panel_id='+selectedCat+'-content&'+_contentList[selectedCat].getParams(_item_id)
							'data':'panel_id=main-panel-body&'+_contentList[selectedCat].getParams(_item_id)
						}
					};
//console.log(_contentList[selectedCat].getParams(_item_id));
					R8.Ctrl.call(_contentList[selectedCat].getRoute(_item_id),params);
//					console.log(selectedCat+' content isnt loaded yet...');
				}
		};

		return _this;
	}();
}
