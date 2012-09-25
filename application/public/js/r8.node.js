
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
					case "components":
						return _components;
						break;
					case "links":
						return _links;
						break;
					case "target":
						return _target;
						break;
					case "view":
						if(typeof(_views[value]) == 'undefined') this.requireView(value);
		
						return _views[value];
						break;
				}
			},
			setupEvents: function() {
				R8.IDE.on('node-'+this.get('id')+'-component-add',this.instantiateComponent,this);
				R8.IDE.on('node-'+this.get('id')+'-name-change',this.updateName,this);
			},
//-----------------------------------------------
//VIEW RELATED METHODS-------------------
//-----------------------------------------------
			requireView: function(viewType) {
				if(typeof(_views[viewType]) == 'undefined') _views[viewType] = {};

				_views[viewType] = new R8.IDE.View.node[viewType](this);

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
			updateStatus: function(newStatus) {
				for(var v in _views) {
					_views[v].updateStatus(_def.status,newStatus);
				}
				_def.status = newStatus;
				R8.IDE.showAlert(this.get('name')+' status has changed to '+newStatus);
			},
			updateName: function(e) {
//DEBUG
//console.log('going to update node name...');
//console.log(e);
				_def.name = e.name;
				var params = {
					'cfg': {
						'data': 'model=node&id='+this.get('id')+'&display_name='+this.get('name')+'&redirect=false'
					}
				};
				R8.Ctrl.call('node/save',params);

				for(var v in _views) {
					_views[v].updateName();
				}
			},
			instantiateComponent: function(e) {
//				var modelName = containerNode.getAttribute('data-model');
//				var modelId = containerNode.getAttribute('data-id');

				var queryParams = 'target_model_name=node&target_id='+e.componentDef.node_id;
				queryParams += '&model_redirect=component&action_redirect=get&id_redirect=*id';
//				queryParams += '&model_redirect='+modelName+'&action_redirect=added_component_conf&id_redirect='+modelId;

				var _this = this;
				var successCallback = function(ioId,responseObj) {
						eval("var response =" + responseObj.responseText);
						var cloneResponse = response.application_component_clone.content[0]['data'];
						var newComponent = cloneResponse.component;

						var project = _this.get('target').get('project');
//console.log('Have a project...');
//console.log(project);
						if(project.hasImplementation(newComponent.implementation_id)) {
//console.log('Project '+project.get('id')+' has the imp we r looking for...');
						} else {
//console.log('Need to retrieve the new implementation from the project '+project.get('id'));
							project.instantiateImplementationById(newComponent.implementation_id);
						}
//DEBUG
//console.log('going to add new component, have a clone response...');
//console.log(cloneResponse);
						_this.addComponent(newComponent,true);
						if(typeof(cloneResponse.ports) != 'undefined') {
//							_this.addPort(cloneResponse.ports[0]);
							_this.addPorts(cloneResponse.ports);
						}

						var alertMsg = 'Added component <b>'+newComponent.name+'</b> to node <b>'+_this.get('name')+'</b>';
						R8.IDE.showAlert(alertMsg);
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
			hasComponent: function(componentId) {
				for(var c in _components) {
					if(_components[c].get('id') == componentId) return true;
				}
				return false;
			},
			refresh: function(newNodeDef) {
				R8.IDE.clearEvent('node-'+this.get('id')+'-component-add');
				R8.IDE.clearEvent('node-'+this.get('id')+'-name-change');

				if(typeof(newNodeDef) != 'undefined') {
					_def = newNodeDef;
				}

				for(var v in _views) {
					_views[v].refresh();
				}

				this.setupEvents();
			},
			addComponents: function(component_list,newComponent) {
				for(var i in component_list) {
					this.addComponent(component_list[i],newComponent);
				}
			},
			addComponent: function(componentDef,newComponent) {
				_components[componentDef.id] = new R8.Component(componentDef);

				for(var v in _views) {
					_views[v].addComponent(_components[componentDef.id],newComponent);
				}

				_components[componentDef.id].init();
			},
			addPorts: function(ports) {
				for(var i in ports) {
					this.addPort(ports[i]);
				}
			},
			addPort: function(portDef) {
				if(_portDefs == null) _portDefs = [];
//DEBUG
//console.log('adding port...');
//console.log(portDef);
				_portDefs.push(portDef);
				var newIndex = _portDefs.length-1;
				_ports.push(new R8.Port(_portDefs[newIndex],this));
				_ports[(_ports.length-1)].init();
//DEBUG
//console.log('just added  new port..need to refresh myself now');
				this.refresh();
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
			},
			removeLink: function(linkId) {
				delete(_links[linkId]);
			},
			purge: function() {
				for(var l in _links) {
					delete(_links[l]);
				}
				for(var p in _ports) {
					delete(_ports[p]);
				}
			},
			//------------------------------------------
			//Component Related Actions
			//------------------------------------------
			deleteComponent: function(componentId) {
				if(!this.hasComponent(componentId)) return false;

				var _this=this;
				var removeComponentFromViews = function(ioId,responseObj) {
					eval("var response =" + responseObj.responseText);
					var delete_result = response.application_component_delete.content[0].data;

					if(delete_result.result == true) _this.purgeComponent(delete_result.id);
				}
				var params = {
					'cfg':{
						'data':'id='+componentId
					},
					'callbacks': {
						'io:success': removeComponentFromViews
					}
				};
				R8.Ctrl.call('component/delete',params);
			},
			deletePort: function(portId) {
				var ports = this.get('ports');
				for(var p in ports) {
					if(ports[p].get('id') == portId) {
						ports[p].purge();
						R8.Utils.arrayRemove(_ports,p);
					}
				}

				for(var v in _views) {
					_views[v].removePort(portId);
				}
			},
			purgeComponent: function(componentId) {
				var links = this.get('links'),
					ports = this.get('ports'),
					portsToRemove = [];

				for(var p in ports) {
					var pDef = ports[p].get('def');
					if(pDef.component_id == componentId) {
						for(var l in links) {
							var lDef = links[l].get('def');
							if(lDef.input_id == pDef.id || lDef.output_id == pDef.id) {
								_target.removeLink(lDef.id);
							}
						}
						//remove port now
						this.deletePort(pDef.id);
					}
				}

				for(var v in _views) {
					_views[v].removeComponent(componentId);
				}

				_components[componentId].purge();
				delete(_components[componentId]);
			}
		}
	};
}