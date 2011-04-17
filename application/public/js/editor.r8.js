
if (!R8.Editor) {

	R8.Editor = function() {
		var _item_id = null,
			_pageContainerNode = null,
			_topbarNode = null,
			_mainBodyWrapperNode = null,

			_editor = null,
			_selectionSize = 0;
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

			_selectionPopTimeout = null,


			_selectRange = null,

			_mousePos = null,
			_events = {};

		return {
			init: function(item_id) {
				_item_id = item_id;

				_pageContainerNode = R8.Utils.Y.one('#page-container');
				_mainBodyWrapperNode = R8.Utils.Y.one('#main-body-wrapper');
				_topbarNode = R8.Utils.Y.one('#page-topbar');

				_editorNode = R8.Utils.Y.one('#editor');
				_fileExplorerNode = R8.Utils.Y.one('#file-explorer');

				var that = this;
				R8.Utils.Y.one(window).on('resize',function(e){
					that.resizePage();
				});

				_editor = ace.edit("editor");
				_editor.setShowPrintMargin(false);
				_editor.setTheme("ace/theme/twilight");

				var RubyScriptMode = require("ace/mode/ruby").Mode;
				_editor.getSession().setMode(new RubyScriptMode());

//				_editor.getSession().setValue("NOD Getting Editor to work.....\n\nNow is the time....");

				_gutterNode = R8.Utils.Y.one('#editor .ace_gutter');
				_contentNode = R8.Utils.Y.one('#editor .ace_content');

				this.resizePage();

				var that=this;

				_selectRange = _editor.getSelectionRange();
				//setup events-----------------------------
				_editor.getSession().selection.on('changeSelection', function(e){
			//		console.log(arguments);
//					console.log(_editor.getSelectionRange());
					_selectRange = _editor.getSelectionRange();

					clearTimeout(_selectionPopTimeout);
					if (that.get('selectionSize') > 0) {
						var selectCallback = function(){
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

				_events['bodyClick'] = _mainBodyWrapperNode.on('click',function(e){
					this.closeSelectionPopup();
					_mousePos = { 'pageX': e.pageX, 'pageY': e.PageY};
				},this);
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

				var fontLOffset = (10*_selectRange.end.column)+5;
				var fontTOffset = (12*_selectRange.end.row)+5;
				var pLeft = _gutterNode.get('region').right + fontLOffset;

//				var tpl = '<div id="selection-popup" class="select-popup" style="left: '+pLeft+'px; top: '+fontTOffset+'px;">\
				var tpl = '<div id="selection-popup" class="select-popup" style="left: '+pLeft+'px; top: 100px;">\
								&nbsp;<a href="javascript: R8.Editor.addAttribute();">Add as Attribute</a><br/>\
								&nbsp;<a href="javascript: R8.Editor.subTemplateVariable();">Sub Template Variable</a>\
							</div>';
				_mainBodyWrapperNode.append(tpl);

				_events['bodyClick'] = _mainBodyWrapperNode.on('click',function(e){
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
			resizePage: function() {
				_viewportRegion = _pageContainerNode.get('viewportRegion');

				var vportHeight = _viewportRegion['height'];
				var vportWidth = _viewportRegion['width'];
				var fxWidthOffset = _fileExplorerNode.get('region').width + 4;

				var topbarRegion = _topbarNode.get('region');
				var mainBodyWrapperHeight = vportHeight - (topbarRegion['height']);
				_mainBodyWrapperNode.setStyles({'height':mainBodyWrapperHeight});

				_fileExplorerNode.setStyle('height',mainBodyWrapperHeight);
				_editorNode.setStyles({'height':mainBodyWrapperHeight,'width':(vportWidth-fxWidthOffset)});
				_editor.resize();
			},
			loadFile: function(fileId) {
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
