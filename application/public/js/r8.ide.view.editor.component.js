
if (!R8.IDE.View.editor) { R8.IDE.View.editor = {}; }

if (!R8.IDE.View.editor.component) {

	R8.IDE.View.editor.component = function(component) {
		var _component = component,
			_idPrefix = 'editor-component-',
			_panel = null,
			_contentWrapperNode = null,
			_contentNode = null,

			_initialized = false,

			_pendingDelete = {},

			_modalNode = null,
			_modalNodeId = 'component-'+_component.get('id')+'-modal',
			_shimNodeId = null,
			_shimNode = null,

			_alertNode = null,
			_alertNodeId = null,

			_events = {};

		return {
			init: function() {
				_contentNode = R8.Utils.Y.one('#'+this.get('id'));
				_contentWrapperNode = R8.Utils.Y.one('#'+this.get('id')+'-wrapper');
//DEBUG
console.log('going to load component:'+_component.get('id'));
				var params = {
					'cfg': {
						'data': 'panel_id='+_contentNode.get('id')
					},
					'callbacks': {
					}
				};
				R8.Ctrl.call('component/editor/'+_component.get('id'),params);

				_initialized = true;
				return;
			},
			render: function() {
				var id=this.get('id');
				_contentTpl = '<div id="'+id+'-wrapper" style="">\
									<div id="'+id+'" class="editor-component" data-id="'+_component.get('id')+'">\
									</div>\
							</div>';

				return _contentTpl;
			},
			resize: function() {
				if(!_initialized) return;

			},
			get: function(key) {
				switch(key) {
					case "id":
						return _idPrefix+_component.get('id');
						break;
					case "name":
						return _component.get('name');
						break;
					case "type":
						return _component.get('type');
						break;
					case "node":
						return _contentNode;
						break;
				}
			},
			set: function(key,value) {
				switch(key) {
					case "panel":
						_panel = value;
						break;
				}
			},
			focus: function() {
				this.resize();
				_contentWrapperNode.setStyle('display','block');
			},
			blur: function() {
				_contentWrapperNode.setStyle('display','none');
			},
			close: function() {
				_contentWrapperNode.purge(true);
				_contentWrapperNode.remove();
			}

//--------------------------------------
//COMPONENT VIEW FUNCTIONS
//--------------------------------------

		}
	};
}