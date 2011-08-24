
if (!R8.Node) {

	R8.Node = function(nodeDef,target) {
		var _def = nodeDef,
			_target = target,

			_portDefs = null,
			_ports = null,
			_components = {},
			_links = {},

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
			get: function(key,value) {
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
//TODO: revisit, dont know why _ports would be not defined
						if(_ports == null) _ports = [];
						return _ports;
						break;
					case "port":
						if(typeof(value) == 'undefined') return null;
						for(var p in _ports) {
							if (_ports[p].get('id') == value) {
								return _ports[p];
							}
						}
						return null;
					case "applications":
						return _components;
						break;
					case "links":
						return _links;
						break;
					case "target":
						return _target;
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
console.log('going to instantiate a new component');
console.log(e);

//				var modelName = containerNode.getAttribute('data-model');
//				var modelId = containerNode.getAttribute('data-id');

				var queryParams = 'target_model_name=node&target_id='+e.componentDef.node_id;
				queryParams += '&model_redirect=component&action_redirect=get&id_redirect=*id';
//				queryParams += '&model_redirect='+modelName+'&action_redirect=added_component_conf&id_redirect='+modelId;

				var _this = this;
				var successCallback = function(ioId,responseObj) {
						eval("var response =" + responseObj.responseText);
						var cloneResponse = response.application_component_clone.content[0]['data'];

//DEBUG
console.log('going to instantiate new component....');
console.log(cloneResponse);
return;

var project = _this.get('target').get('project');
console.log('Have a project...');
console.log(project);
if(project.hasImplementation(newComponent.implementation_id)) {
	console.log('Project '+project.get('id')+' has the imp we r looking for...');
} else {
	console.log('Need to retrieve the new implementation from the project '+project.get('id'));
	project.instantiateImplementationById(newComponent.implementation_id);
}
//DEBUG
console.log('going to add new component...');
console.log(newComponent);
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
					_ports.push(new R8.Port(_portDefs[p],this));
					_ports[p].init();
				}
//console.log('Setting portDefs for node:'+_def.id);
//console.log(portDefs);
//console.log('-----------------------------');

			},
			swapInNewPort: function(oldPortId,newPortDef) {
/*
				var oldPortId = swapDef.oldPortId,
					newPortId = swapDef.newPortId,
					tempLinkObj = swapDef.tempLinkObj,
					newLink = swapDef.newLink;
*/
				for(var p in _ports) {
					if(_ports[p].get('id') == oldPortId) {
						_ports[p].swapInNew(newPortDef);
					}
				}
//				_ports[newPortDef.id] = _ports[oldPortId];
//				_ports[newPortDef.id].swapInNew(newPortDef);
//				delete(_ports[oldPortId]);
//				_ports[newPortId].id = newPortId;
//				_ports[newPortId].nodeId = newPortId;

/*
				var linkId = 'link-'+tempLinkObj.id;
				_target.removeLink(linkId);

//TODO: temp hack b/c of differences between link object returned from create/save and get_links
				newLink.item_id = _id
				newLink.style =  [
									{'strokeStyle':'#25A3FC','lineWidth':3,'lineCap':'round'},
									{'strokeStyle':'#63E4FF','lineWidth':1,'lineCap':'round'}
								];
				_target.addLink(newLink);
*/
			},
			addLink: function(link) {
				_links[link.get('id')] = link;
			}
		}
	};
}