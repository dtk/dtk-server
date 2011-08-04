
if (!R8.Node) {

	R8.Node = function(nodeDef) {
		var _def = nodeDef,
			_portDefs = null,
			_ports = null,

			_components = {},

			_views = {},
			_initialized = false,
			_events = {};

		return {
			init: function() {
				this.setupEvents();
//DEBUG
//console.log(_def.components);
				for(var c in _def.components) {
					this.addComponent(_def.components[c]);
				}
				_initialized = true;
			},
			get: function(key) {
				switch(key) {
					case "id":
						return _def.id;
						break;
					case "type":
						return "node";
						break;
					case "status":
						return _def.status;
						break;
					case "os_type":
						return _def.os_type;
						break;
					case "name":
						return _def.name;
//						return _def.display_name;
						break;
					case "ports":
						return _ports;
						break;
					case "applications":
						return _components;
						break;
					case "links":
						return _links;
						break;
					case "applications":
						return _applications;
						break;
				}
			},
			setupEvents: function() {
				R8.IDE.on('node-'+this.get('id')+'-component-add',this.instantiateComponent,this);
			},
//-----------------------------------------------
//VIEW RELATED METHODS-------------------
//-----------------------------------------------
			requireView: function(viewType) {
				if(typeof(_views[viewType]) == 'undefined') _views[viewType] = {};

				_views[viewType] = new R8.IDE.View[viewType].node(this);

			},
			getView: function(viewType) {
				if(typeof(_views[viewType]) == 'undefined') this.requireView(viewType);

				return _views[viewType];
			},
			renderView: function(viewType) {
				if(typeof(_views[viewType]) == 'undefined') this.requireView(viewType);

				return _views[viewType].render();
			},
/*
			initView: function(viewType) {
				return _views[viewType].init();
			},
*/
			isInitialized: function() {
				return _initialized;
			},
//------------------------------------
//NODE RELATED METHODS
//------------------------------------
			instantiateComponent: function(e) {
//DEBUG
console.log(e);

//				var modelName = containerNode.getAttribute('data-model');
//				var modelId = containerNode.getAttribute('data-id');

				var queryParams = 'target_model_name=node&target_id='+e.componentDef.node_id;
				queryParams += '&model_redirect=component&action_redirect=get&id_redirect=*id';
//				queryParams += '&model_redirect='+modelName+'&action_redirect=added_component_conf&id_redirect='+modelId;

				var _this = this;
				var successCallback = function(ioId,responseObj) {
						eval("var response =" + responseObj.responseText);
						var newComponent = response.application_component_get.content[0]['data'];

						_this.addComponent(newComponent,true);
//TODO: revisit for best way to do notification updates
//					R8.Workspace.refreshItem(modelId);
//					R8.Workspace.refreshNotifications();
				}
				var callbacks = {
					'io:success' : successCallback
				};

				R8.Ctrl.call('component/clone/'+e.componentDef.component_id,{
					'callbacks': callbacks,
					'cfg': {
						'data': queryParams
					}
				});
			},
			refresh: function(newNodeDef) {
				_def = newNodeDef;
//DEBUG
//console.log('going to refresh node...,');
//console.log(newNodeDef);
				for(var v in _views) {
					_views[v].refresh();
				}
			},
			addComponent: function(componentDef,tester) {
				_components[componentDef.id] = new R8.Component(componentDef);

				for(var v in _views) {
					_views[v].addComponent(_components[componentDef.id],tester);
				}

				_components[componentDef.id].init();
			},
			setPorts: function(portDefs) {
				_portDefs = portDefs;

				_ports = [];
				for(var p in _portDefs) {
					_ports.push(new R8.Port(_portDefs[p]));
					_ports[p].init();
				}
//console.log('Setting portDefs for node:'+_def.id);
//console.log(portDefs);
//console.log('-----------------------------');

			}
		}
	};
}