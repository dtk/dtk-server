
if (!R8.Editor) {

	R8.Editor = function() {
		var _cfg = null,
			_initialized = false,

			_currentFileFocus = '',
			_itemId = null,
			_fileId = null,
			_pageContainerNode = null,
			_topbarWrapperNode = null,
			_editorWrapperNode = null,

			_editorContainerNode = null,

			_editorBtnNode = null,
			_editorBarWrapperNode = null,
			_editorBarWrapperClosedWidth = 90,
			_editorOpen = false,

			_editor = null,
			_editorHeaderNode = null,
			_editorHeaderHeight = 25,
			_editorCloseBtnNode = null,

			_editorNode = null,
			_gutterNode = null,
			_editorContentNode = null,

			_fileExplorerNode = null,

			_mbSpacerNode = null,
			_mbTopCapNode = null,
			_mbBtmCapNode = null,

			_detailsHeader = null,
			_contentWrapperNode = null,

			_viewportRegion = null,

			_selectionSize = 0;
			_selectionPopTimeout = null,
			_selectRange = null,
			_mousePos = null,

			_files = {},

			_topbarTpl = '<div id="editor-bar-wrapper" class="editor-bar-wrapper closed">\
						<div class="divider"></div>\
						<div id="editor-btn" class="editor-btn">\
							<div class="item">Editor</div>\
							<div class="arrow"></div>\
						</div>\
					</div>',

			_editorTpl = '<div id="editor-wrapper" class="editor-wrapper">\
							<div id="editor-header" class="editor-header" style="height: '+_editorHeaderHeight+'px;">\
							</div>\
							<div id="editor" style="position: relative; float: left;"></div>\
						</div>',
			_events = {};

		return {
			init: function(cfg) {
				_editorContainerNode = R8.Utils.Y.one('#'+cfg.containerNodeId);
				_editorContainerNode.append(_editorTpl);

				_editorWrapperNode = R8.Utils.Y.one('#editor-wrapper');
//				_editorHeaderNode = R8.Utils.Y.one('#editor-header');
				_editorNode = R8.Utils.Y.one('#editor');

				_pageContainerNode = R8.Utils.Y.one('#page-container');

				this.initEditor();
			},
			toggleEditor: function() {
				if(_editorOpen) {
					_editorBarWrapperNode.setStyles({'width':_editorBarWrapperClosedWidth});

					_editorWrapperNode.setStyle('display','none');
					_editorBarWrapperNode.addClass('closed');
					_editorBarWrapperNode.removeClass('open');
					_editorOpen = false;
				} else {
					var mainMenuItemWrapperNode = R8.Utils.Y.one('#main-menu-items');
					var itemsRightPos = mainMenuItemWrapperNode.get('region').right;
					var width = _editorBarWrapperNode.get('region').right - itemsRightPos;
					_editorBarWrapperNode.setStyles({'width':width});

					_editorWrapperNode.setStyle('display','block');
					_editor.resize();
					_editorBarWrapperNode.addClass('open');
					_editorBarWrapperNode.removeClass('closed');
					_editorOpen = true;
				}
			},
			initEditor: function() {
				_editor = ace.edit("editor");
				_editor.setShowPrintMargin(false);
				_editor.setTheme("ace/theme/twilight");
//				_editor.setTheme("ace/theme/cobalt");

				var RubyScriptMode = require("ace/mode/ruby").Mode;
				_editor.getSession().setMode(new RubyScriptMode());

//				_editor.getSession().setValue("NOD Getting Editor to work.....\n\nFooooooo!!!");

				_gutterNode = R8.Utils.Y.one('#editor .ace_gutter');
//				_contentNode = R8.Utils.Y.one('#editor .ace_content');

//DEBUG
//console.log(_gutterNode);
//console.log(_gutterNode.get('region'));

//				var headerSpacerTpl = '<div style="height: inherit; width: '+(_gutterNode.get('region').width+10)+'px;"></div>';

//				var headerSpacerTpl = '<div style="height: inherit; width: 60px; float: left;"></div>';
//				_editorHeaderNode.append(headerSpacerTpl);

				this.resize();

				var that=this;

				_selectRange = _editor.getSelectionRange();
				//setup events-----------------------------
				_editor.getSession().selection.on('changeSelection', function(e){
			//		console.log(arguments);
//					console.log(_editor.getSelectionRange());
					_selectRange = _editor.getSelectionRange();

					clearTimeout(_selectionPopTimeout);
					if (that.get('selectionSize') > 0) {
						var selectCallback = function() {
							R8.Editor.renderSelectionPopup();
						}
						_selectionPopTimeout = setTimeout(selectCallback, 400);
					} else {
						R8.Editor.closeSelectionPopup();
					}
				});
				_editor.getSession().selection.on('changeCursor', function(e){
					if (that.get('selectionSize') <= 0) {
						R8.Editor.closeSelectionPopup();
					}
				});

				_events['bodyClick'] = _pageContainerNode.on('click',function(e){
					this.closeSelectionPopup();
					_mousePos = { 'pageX': e.pageX, 'pageY': e.PageY};
				},this);

/*
				_events['ftabMouseEnter'] = R8.Utils.Y.delegate('mouseenter',function(e){
					e.currentTarget.addClass('show-close');
				},_editorHeaderNode,'.file-tab');

				_events['ftabMouseLeave'] = R8.Utils.Y.delegate('mouseleave',function(e){

					e.currentTarget.removeClass('show-close');
				},_editorHeaderNode,'.file-tab');

				_events['ftabClick'] = R8.Utils.Y.delegate('click',function(e){
					var tabNodeId = e.currentTarget.get('id');
					var fileId = tabNodeId.replace('file-tab-','');

					R8.Editor.fileFocus(fileId);
				},_editorHeaderNode,'.file-tab');

				_events['fCloseClick'] = R8.Utils.Y.delegate('click',function(e){
					var tabNodeId = e.currentTarget.get('id');
					var fileId = tabNodeId.replace('close-file-','');

					R8.Editor.closeFile(fileId);
				},_editorHeaderNode,'.file-tab .close-file');
*/
				_initialized = true;
			},
			isInitialized: function() {
				return _initialized;
			},
			closeEditor: function() {
				_editorWrapperNode.purge(true);
				_editorWrapperNode.remove();
				_editor = null;
			},
			closeFile: function(fileId) {
				_editor.getSession().setValue('');
				var fTabNode = R8.Utils.Y.one('#file-tab-'+fileId);
				fTabNode.purge(true);
				fTabNode.remove();
				delete(_files[fileId]);

				_currentFileFocus = '';
				for(var f in _files) {
					this.fileFocus(f);
					return;
				}
			},
			get: function(key) {
				switch(key) {
					case "selectionSize":
						return _selectRange.start.column < _selectRange.end.column;
						break;
				}
			},
			renderSelectionPopup: function() {
				var gutterWidth = _gutterNode.getStyle('width');

//var fontSize = document.getElementById('editor').style.fontSize;
//fontSize = fontSize.replace('px','');
//console.log(fontSize);

//				var fontLOffset = (10*_selectRange.end.column)+5;
				var fontLOffset = (7*_selectRange.end.column)+20;
//				var fontTOffset = (12*_selectRange.end.row)+5;
				var fontTOffset = (14*_selectRange.end.row)+5;
				var pLeft = _gutterNode.get('region').right + fontLOffset;

//				var tpl = '<div id="selection-popup" class="select-popup" style="left: '+pLeft+'px; top: 100px;">\
				var tpl = '<div id="selection-popup" class="select-popup" style="left: '+pLeft+'px; top: '+fontTOffset+'px;">\
								&nbsp;<a href="javascript: R8.Editor.addAttribute();">Add as Attribute</a><br/>\
								&nbsp;<a href="javascript: R8.Editor.subTemplateVariable();">Sub Template Variable</a>\
							</div>';
				_editorWrapperNode.append(tpl);

				_events['bodyClick'] = _editorWrapperNode.on('click',function(e){
//console.log('clicking main body...');
					this.closeSelectionPopup();
				},this);
			},
			closeSelectionPopup: function() {
				if(typeof(_events['bodyClick']) != 'undefined') {
					_events['bodyClick'].detach();
					delete(_events['bodyClick']);
				}
				var popupNode = R8.Utils.Y.one('#selection-popup');
				if(popupNode != null) {
					popupNode.purge(true);
					popupNode.remove();
				}
			},
			addAttribute: function() {
alert('should create new attr for component...');
			},
			subTemplateVariable: function() {
//				var selectionContent = _editor.getSession().doc.getTextRange(_editor.getSelectionRange());
				var selectionContent = _editor.getSession().doc.getTextRange(_selectRange);
//console.log('selection content:'+selectionContent);
				var varContent = '<%'+selectionContent+'%>';
				_editor.find(selectionContent);
				_editor.replace(varContent);
				clearTimeout(_selectionPopTimeout);
			},
			resize: function() {
/*
				_viewportRegion = _pageContainerNode.get('viewportRegion');

				var vportHeight = _viewportRegion['height'];
				var vportWidth = _viewportRegion['width'];

				var topbarRegion = _topbarWrapperNode.get('region');

				var pgRegion = _pageContainerNode.get('region');
*/
//DEBUG
//console.log('inside resize in editor...');
if(_editorContainerNode == null) return;

				var wrapperRegion = _editorContainerNode.get('region');
				var editorWrapperHeight = wrapperRegion.height;
				var editorWrapperWidth = wrapperRegion.width;
/*
				_editorWrapperNode.setStyles({
					'height':editorWrapperHeight,
					'width':editorWrapperWidth,
//					'top': _topbarWrapperNode.get('region').height
				});
*/
				_editorNode.setStyles({'height':(editorWrapperHeight),'width':editorWrapperWidth});
//				_editorNode.setStyles({'height':(editorWrapperHeight-_editorHeaderHeight),'width':editorWrapperWidth});
//				_editorHeaderNode.setStyles({'width':editorWrapperWidth});
				_editor.resize();
			},
			resizePageOld: function() {
				_viewportRegion = _pageContainerNode.get('viewportRegion');

				var vportHeight = _viewportRegion['height'];
				var vportWidth = _viewportRegion['width'];
//				var fxWidthOffset = _fileExplorerNode.get('region').width + 4;

				var topbarRegion = _topbarWrapperNode.get('region');
//				var editorWrapperHeight = vportHeight - (topbarRegion['height']);
//				var editorWrapperHeight = _editorWrapperNode.get('region').height-40;
//				var editorWrapperHeight = pgRegion.height-_topbarWrapperNode.get('region').height;
//				var editorWrapperWidth = _editorWrapperNode.get('region').width;

				var pgRegion = _pageContainerNode.get('region');
				var editorWrapperHeight = pgRegion.height-_topbarWrapperNode.get('region').height-10;
				var editorWrapperWidth = pgRegion.width;
//				_editorWrapperNode.setStyles({'height':editorWrapperHeight});

//				_fileExplorerNode.setStyle('height',editorWrapperHeight);
//				_editorNode.setStyles({'height':editorWrapperHeight,'width':editorWrapperWidth});
//				_editorNode.setStyles({'height':editorWrapperHeight,'width':(vportWidth-fxWidthOffset)});

				_editorWrapperNode.setStyles({
					'height':editorWrapperHeight,
					'width':editorWrapperWidth,
					'top': _topbarWrapperNode.get('region').height
				});

				_editorNode.setStyles({'height':(editorWrapperHeight-_editorHeaderHeight),'width':editorWrapperWidth});
//				_editorHeaderNode.setStyles({'width':editorWrapperWidth});
				_editor.resize();
			},
			loadFileOld: function(fileId) {
				var that=this;
				var params = {
					'cfg': {
						'data': ''
					},
					'callbacks': {
						'io:success': that.setFileContents
					}
				};
				R8.Ctrl.call('editor/load_file/'+fileId,params);
			},
			fileInit: function(file) {
				if(!this.isInitialized()) { this.initEditor(); }

				var fileDef = {
					'file': file,
					'editor': _editor
				};
				_files[file.id] = new R8.File(fileDef);
				this.addTab(file.id);
				this.fileFocus(file.id);
			},
			addTab: function(fileId) {
				var fileName = _files[fileId].get('name');
				var tabTpl = '<div id="file-tab-'+fileId+'" class="file-tab">'+fileName+'<div id="close-file-'+fileId+'" class="close-file"></div></div>';

//				_editorHeaderNode.append(tabTpl);
			},
			fileFocus: function(fileId) {
				if(_currentFileFocus == fileId) return;

				_editor.getSession().setValue(_files[fileId].get('content'));
				var callback = function() {
					_editor.gotoLine(1);
				}
				setTimeout(callback,150);
/*
				for(var f in _files) {
					R8.Utils.Y.one('#file-tab-'+f).removeClass('focus');
				}
				R8.Utils.Y.one('#file-tab-'+fileId).addClass('focus');
				_currentFileFocus = fileId;
*/
			},
			loadFile: function(fileId) {
/*
				if(typeof(_files[fileId]) != 'undefined') {
					this.fileFocus(fileId);
					return;
				}
*/
				var callback = function(ioId,responseObj) {
					eval("var response =" + responseObj.responseText);
//					var file = response.application_component_get_cfg_file_contents.content[0].data;
					var file = response.application_file_asset_get.content[0].data;

					R8.Editor.fileInit(file);
//DEBUG
//TODO: this is for when editor is docked on toolbar
//					if(_editorOpen == false) { R8.Editor.toggleEditor(); }
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
				R8.Ctrl.call('file_asset/get/'+fileId,params);
			},
			setFileContents: function(ioId,responseObj) {
				eval("var response =" + responseObj.responseText);
				var file_contents = response.application_editor_load_file.content[0].data;
				_editor.getSession().setValue(file_contents);

				var callback = function() {
					_editor.gotoLine(1);
				}
				setTimeout(callback,100);
//console.log(file_contents);
			}

		}
	}();
}
