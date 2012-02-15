
if (!R8.IDE.View.file) {

	R8.IDE.View.file = function(view) {
		var _view = view,
			_id = _view.id,
			_panel = _view.panel,
			_fileContent = '',
			_initialized = false,

			_file = null,
			_lineNo = 1,
			_cursorPos = null,
			_fileChanged = false,

			_events = {};

		return {
			init: function() {
				R8.Editor.loadFile(_id,this);
				_initialized = true;
			},
			render: function() {
				return '';
			},
			resize: function() {
				if(!_initialized) return;

/*
				var contentHeight = _node.get('region').height - _headerNode.get('region').height;
				_contentNode.setStyles({'height':contentHeight,'width':_node.get('region').width,'backgroundColor':'#FFFFFF'});

				if(_fileList.length > 0) R8.Editor.resize();
*/
			},
			get: function(key) {
				switch(key) {
					case "id":
						return _id;
						break;
					case "name":
						return _view.name;
						break;
					case "type":
						return _view.type;
						break;
				}
			},
			focus: function() {
				R8.Editor.setViewContext(this);
				this.resize();
				R8.Utils.Y.one('#'+_panel.get('id')+'-editor-wrapper').setStyle('display','block');
				this.setEditorContent();
//DEBUG
//console.log('should be navigating to cursor pos...');
//console.log(_cursorPos);
				R8.Editor.goToPos(_cursorPos);
				R8.Editor.focus();
			},
			blur: function() {
				_cursorPos = R8.Editor.get('cursorPos');
				_file.content = R8.Editor.getEditorContent();
				R8.Utils.Y.one('#'+_panel.get('id')+'-editor-wrapper').setStyle('display','none');

			},
			close: function() {

			},

//------------------------------------------------------
//these are file view specific functions
//------------------------------------------------------

			setFile: function(file) {
				_file = file;
			},
			setEditorContent: function() {
				if(_file == null) {
					var that = this;
					var callback = function() {
						that.setEditorContent();
					}
					setTimeout(callback,100);
					return;
				}

				R8.Editor.setEditorContent(_file.content);

				var callback = function() {
					R8.Editor.goToLine(_lineNo);
				}
				setTimeout(callback,150);
			}
		}
	};
}
