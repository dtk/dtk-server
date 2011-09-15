
if (!R8.IDE.View.component) { R8.IDE.View.component = {}; }

if (!R8.IDE.View.component.linkDefsEditor) {

	R8.IDE.View.component.linkDefsEditor = function(component) {
		var _component = component,
			_idPrefix = 'editor-component-link-defs',
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

				var _this = this;
				var renderComplete = function() {
					_this.setupEditorEvents();
				}
				var params = {
					'cfg': {
						'data': 'panel_id='+this.get('id')+'-wrapper'
					},
					'callbacks': {
						'io:renderComplete':renderComplete
					}
				};
				R8.Ctrl.call('component/link_defs_editor/'+_component.get('id'),params);

				_initialized = true;
				return;
			},
			render: function() {
				var id=this.get('id');
				_contentTpl = '<div id="'+id+'-wrapper" style="">\
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
			},

//--------------------------------------
//COMPONENT VIEW FUNCTIONS
//--------------------------------------
			setupEditorEvents: function() {
				R8.Utils.Y.one('#link_def_type').on('change',function(e){
					this.updateAvailableComponents(e.currentTarget.get('value'));
				},this);
			},
			updateAvailableComponents: function(type) {
				if(type=='') return;

				var _this = this;
				var callback = function(ioId,responseObj) {
					_this.setAvailableComponents(ioId,responseObj);
				}
				var params = {
					'cfg': {
						'data': ''
					},
					'callbacks': {
						'io:success':callback
					}
				};
				R8.Ctrl.call('component/get_by_type/'+type,params);
			},
			setAvailableComponents: function(ioId,responseObj) {
				eval("var response =" + responseObj.responseText);
				var availableComponents = response.application_component_get_by_type.content[0].data;

				var selectTpl = '<select id="available_components" name="available_components">';
				var optionTpl = '<option value="">--Select Component--</option';
				selectTpl = selectTpl+optionTpl;
				for(var i in availableComponents) {
					var optionTpl = '<option value="'+availableComponents[i].id+'">'+availableComponents[i].description+'</option';
					selectTpl = selectTpl+optionTpl;
				}
				selectTpl = selectTpl+'</select>';

				_contentWrapperNode.append(selectTpl);
//DEBUG
//console.log(availableComponents);
			}
		}
	};
}