
if (!R8.Detailview) {

	R8.Detailview = function() {
		var _item_id = null,
			_pageContainerNode = null,
			_topbarNode = null,
			_mainBodyNode = null,
			_mblPaneNode = null,
			_mbrPaneNode = null,
			_detailsHeader = null,
			_contentWrapperNode = null,

			_viewportRegion = null,
			_events = {},
			_contentList = {
				'details': {
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
				_mainBodyNode = R8.Utils.Y.one('#main-body');
				_topbarNode = R8.Utils.Y.one('#page-topbar');

				_mblPaneNode = R8.Utils.Y.one('#mb-l-pane');
				_mbrPaneNode = R8.Utils.Y.one('#mb-r-pane');

				_detailsHeaderNode = R8.Utils.Y.one('#details-header');
				_contentWrapperNode = R8.Utils.Y.one('#content-wrapper');

				var that = this;
				R8.Utils.Y.one(window).on('resize',function(e){
					that.resizePage();
				});
				this.resizePage();

//TODO: move this to centralized place
				_events['catClick'] = R8.Utils.Y.delegate('click',this.toggleDetails,'#detail-categories','.details-cat');
			},
			resizePage: function() {
				_viewportRegion = _pageContainerNode.get('viewportRegion');

				var vportHeight = _viewportRegion['height'];
				var vportWidth = _viewportRegion['width'];

				var topbarRegion = _topbarNode.get('region');
				var mainBodyHeight = vportHeight - (topbarRegion['height']);
				_mainBodyNode.setStyles({'height':mainBodyHeight});

				var mblPaneWidth = _mblPaneNode.get('region').width;
				var mbrPaneWidth = (vportWidth - mblPaneWidth);
				_mbrPaneNode.setStyles({'width': mbrPaneWidth,'height':mainBodyHeight,'left': mblPaneWidth});

				var contentBorder = 10;
				var contentHeight = (mainBodyHeight - _detailsHeaderNode.get('region').height - contentBorder);
				_contentWrapperNode.setStyles({'height': contentHeight, 'width': (mbrPaneWidth-contentBorder)});
			},

			toggleDetails: function(e) {
				var id = e.currentTarget.get('id'),
					selectedCat = id.replace('-details-cat','');

				for(var contentId in _contentList) {
					R8.Utils.Y.one('#'+contentId+'-details-cat').removeClass('selected');
					R8.Utils.Y.one('#'+contentId+'-content').setStyle('display','none');
				}
				R8.Utils.Y.one('#'+selectedCat+'-details-cat').addClass('selected');
				R8.Utils.Y.one('#'+selectedCat+'-content').setStyle('display','block');

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
