
if (!R8.Detailview) {

	R8.Detailview = function() {
		var _item_id = null,
			_pageContainerNode = null,
			_topbarNode = null,
			_mainBodyWrapperNode = null,

			_mblPanelNode = null,
			_mbContentWrapperNode = null,
			_mbMainContentNode = null,

			_mbSpacerNode = null,
			_mbTopCapNode = null,
			_mbBtmCapNode = null,

			_detailsHeader = null,
			_contentWrapperNode = null,

			_viewportRegion = null,
			_events = {},
			_focusedIndex = 'summary',
			_contentList = {
				'summary': {
					'loaded': true,
					'route': 'foo/bar'
				},
				'instances': {
					'loaded': false,
//					'route': 'component/instance_list',
					'route': 'component/list2',
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
				'dependencies': {
					'loaded': false,
					'route': 'foo/bar'
				},
				'editor': {
					'loaded': false,
					'route': 'component/editor_test',
					'params': {
					},
					getParams: function(item_id) {
						return '';
					},
					getRoute: function(item_id) {
						return this.route+'/'+item_id
					}
				},
				'layout': {
					'loaded': false,
					'route': 'component/layout_test',
					'params': {
					},
					getParams: function(item_id) {
						return '';
					},
					getRoute: function(item_id) {
						return this.route+'/'+item_id
					},
					blur: function() {
						var layoutEditorNode = R8.Utils.Y.one('#layout-editor');
						layoutEditorNode.purge(true);
						layoutEditorNode.remove();
						R8.LayoutEditor.reset();
					}
				}
			};
/*
					var searchObj = {
							'id': 'new',
							'display_name':'',
							'search_pattern': {
								':columns': [],
								':filter': [],
								':order_by': [],
								':paging': {},
								':relation': modelName
							}
					};
*/
		return {
			init: function(item_id) {
				_item_id = item_id;

				_pageContainerNode = R8.Utils.Y.one('#page-container');
				_mainBodyWrapperNode = R8.Utils.Y.one('#main-body-wrapper');
				_topbarNode = R8.Utils.Y.one('#page-topbar');

				_mblPanelNode = R8.Utils.Y.one('#mb-l-panel');
				_mbSpacerNode = R8.Utils.Y.one('#mb-panel-spacer');
				_mbContentWrapperNode = R8.Utils.Y.one('#mb-content-wrapper');
				_mbMainContentNode = R8.Utils.Y.one('#mb-main-content');
				_mbTopCapNode = R8.Utils.Y.one('#mb-top-cap');
				_mbBtmCapNode = R8.Utils.Y.one('#mb-btm-cap');

				_detailsHeaderNode = R8.Utils.Y.one('#details-header');

				var that = this;
				R8.Utils.Y.one(window).on('resize',function(e){
					that.resizePage();
				});
				this.resizePage();

//TODO: move this to centralized place
				_events['catClick'] = R8.Utils.Y.delegate('click',this.toggleDetails,'#display-categories','.display-cat');
			},
			resizePage: function() {
				_viewportRegion = _pageContainerNode.get('viewportRegion');

				var vportHeight = _viewportRegion['height'];
				var vportWidth = _viewportRegion['width'];

				var topbarRegion = _topbarNode.get('region');
				var mainBodyWrapperHeight = vportHeight - (topbarRegion['height']);
				_mainBodyWrapperNode.setStyles({'height':mainBodyWrapperHeight});

				var mblPanelWidth = _mblPanelNode.get('region').width;
				var spacerSize = 10;
				var spacerWidth = 2*spacerSize;
				var mbcWrapperWidth = (vportWidth - mblPanelWidth - spacerWidth),
					mbcWrapperHeight = (mainBodyWrapperHeight-spacerWidth);

				mbcWrapperWidth = (mbcWrapperWidth < 700) ? 700 : mbcWrapperWidth;
				mbcWrapperHeight = (mbcWrapperHeight < 400) ? 400 : mbcWrapperHeight;

				_mbContentWrapperNode.setStyles({'width': mbcWrapperWidth,'height':mbcWrapperHeight});

				var capsOffset = 10;
				var mContentHeight = mbcWrapperHeight - capsOffset;
				_mbMainContentNode.setStyles({'height':mContentHeight,'width':mbcWrapperWidth});

				var cornersWidth = 10;
				_mbTopCapNode.setStyle('width',(mbcWrapperWidth-cornersWidth));
				_mbBtmCapNode.setStyle('width',(mbcWrapperWidth-cornersWidth));

//				var contentHeight = (mainBodyHeight - _detailsHeaderNode.get('region').height);
//				_contentWrapperNode.setStyles({'height': contentHeight, 'width': (mbrPaneWidth)});
			},

			toggleDetails: function(e) {
				var id = e.currentTarget.get('id'),
					selectedCat = id.replace('-cat','');

				if(selectedCat === _focusedIndex) return;

				for(var contentId in _contentList) {
					R8.Utils.Y.one('#'+contentId+'-cat').removeClass('selected');
					R8.Utils.Y.one('#'+contentId+'-content').setStyle('display','none');
				}
console.log('selectedCat:'+selectedCat);
				R8.Utils.Y.one('#'+selectedCat+'-cat').addClass('selected');
				R8.Utils.Y.one('#'+selectedCat+'-content').setStyle('display','block');

				if(typeof(_contentList[_focusedIndex].blur) != 'undefined') _contentList[_focusedIndex].blur();
				_focusedIndex = selectedCat;

				if(_contentList[selectedCat].loaded != true) {
					var params = {
						'cfg':{
							'data':'panel_id='+selectedCat+'-content&'+_contentList[selectedCat].getParams(_item_id)
						}
					};
//console.log(_contentList[selectedCat].getParams(_item_id));
					R8.Ctrl.call(_contentList[selectedCat].getRoute(_item_id),params);
//					console.log(selectedCat+' content isnt loaded yet...');
				}
			}
		}
	}();
}
