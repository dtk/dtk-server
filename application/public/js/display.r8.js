
if (!R8.Displayview) {

	R8.Displayview = function() {
		var _itemId = null,
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

			_addCfgBtnNode = null,

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
				'editor': {
					'loaded': false,
					'route': 'component/editor',
					'params': {
					},
					getParams: function(item_id) {
						return '';
					},
					getRoute: function(item_id) {
						return this.route+'/'+item_id
					},
					blur: function() {
/*
						var layoutEditorNode = R8.Utils.Y.one('#layout-editor');
						layoutEditorNode.purge(true);
						layoutEditorNode.remove();
						R8.LayoutEditor.reset();
*/
					}
				},
				'constraints': {
					'loaded': false,
					'route': 'component/constraints',
					'params': {
					},
					getParams: function(item_id) {
						return '';
					},
					getRoute: function(item_id) {
						return this.route+'/'+item_id
					},
					blur: function() {
					}
				},
				'file_editor': {
					'loaded': false,
					'route': 'component/file_editor',
					'params': {
					},
					getParams: function(itemId,fileAssetId) {
						return 'file_asset_id='+fileAssetId;
					},
					getRoute: function(itemId) {
						return this.route+'/'+itemId
					},
					blur: function() {
					}
				},
				'config_templates': {
					'loaded': false,
					'route': 'component/config_templates',
					'params': {
					},
					getParams: function(item_id) {
						return '';
					},
					getRoute: function(item_id) {
						return this.route+'/'+item_id
					},
					blur: function() {
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
				R8.UI.init();

				_itemId = item_id;

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

				_addCfgBtnNode = R8.Utils.Y.one('#add-cfg-file-btn');
				_addCfgBtnNode.on('click',function(e){
					var contentNode = R8.UI.renderModal();
					var params = {
						'cfg': {
							'data': 'panel_id='+contentNode.get('id')
						}
					};
					R8.Ctrl.call('component/add_cfg_file/'+_itemId,params);
				},this);

				var that = this;
				R8.Utils.Y.one(window).on('resize',function(e){
					that.resizePage();
				});
				this.resizePage();
				//R8.Editor.init();

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

			loadCfgFile: function(fileId) {
				//file_editor-content
/*
				for(var contentId in _contentList) {
					if(contentId == 'file_editor')
						R8.Utils.Y.one('#'+contentId+'-content').setStyle('display','block');
					else
						R8.Utils.Y.one('#'+contentId+'-content').setStyle('display','none');
				}
*/

				var editorWrapperTpl = '<div id="editor-wrapper"></div>';
				var editorWrapperNode = R8.Utils.Y.Node.create(editorWrapperTpl);
				var yOffset = _topbarNode.get('region').height;

				editorWrapperNode.setStyles({
					'width': _pageContainerNode.get('region').width+'px',
					'height': (_pageContainerNode.get('region').height)+'px',
					'top': yOffset+'px',
					'position': 'absolute',
					'zIndex': 10,
					'left': '0px',
					'backgroundColor': '#FFFFFF'
				});
				_pageContainerNode.append(editorWrapperNode);

				var callback = function(ioId,responseObj) {
					eval("var response =" + responseObj.responseText);
					var file = response.application_component_get_cfg_file_contents.content[0].data;

					R8.Editor.loadFile(file);
/*
					R8.Editor.init({
						itemId: _itemId,
//						editorWrapperNodeId: 'file_editor-content',
						editorWrapperNodeId: 'editor-wrapper',
						'fileId': file.id,
						contents: file.contents
					});
*/
				}
				var params = {
					'cfg' : {
						method: 'POST',
						'data': 'file_asset_id='+fileId
					},
					'callbacks': {
						'io:success':callback
					}
				};
				R8.Ctrl.call('component/get_cfg_file/'+_itemId,params);
//DEBUG
//console.log('loading file:'+fileId);
			},
			uploadCfgFile: function(formId) {
				var that=this;
				var callback = function(ioId,responseObj) {
					eval("var response =" + responseObj.responseText);
					var cfg_file_list = response.application_component_add_cfg_file_from_upload.content[0].data.cfg_file_list;
					var tpl = R8.Rtpl.component_cfg_file_list({
						'config_file_list':cfg_file_list
					});
					R8.Utils.Y.one('#cfg-file-container').set('innerHTML',tpl);
				}
				var params = {
					'cfg' : {
						method : 'POST',
						form: {
							id : formId,
							upload : true
						}
					},
					'callbacks': {
						'io:complete':callback
					}
				};
				R8.Ctrl.call('component/add_cfg_file_from_upload/'+_itemId,params);
				R8.UI.closeModal();
			}
		}
	}();
}
