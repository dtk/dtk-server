
if (!R8.File) {

	R8.File = function(fileDef) {
		var _file = fileDef.file,
			_editor = fileDef.editor,

			_events = {};

		return {
			init: function() {
				
			},
			get: function(key) {
				switch(key) {
					case "content":
						return _file.content;
						break;
					case "name":
						return _file.name;
						break;
				}
			},
			open: function() {
				
			},
			close: function() {
				
			},
			save: function() {
				
			},
			saveAs: function() {
				
			},
			deleteFile: function() {
				
			}
		}
	};
}