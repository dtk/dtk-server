
if (!R8.Target) {

	R8.Target = function(targetDef,project) {
		var _def = targetDef,
			_project = project,
			_views = {},
			_events = {},
			_initialized = false,

			_nodes = {},
			_nodeGroups = {},
			
			_portDefs = null,
			_linkDefs = null;

			if(_def.ui == null) _def.ui = {'items':{}};

		return {
			init: function() {
				for(var n in _def.nodes) {
					var node = _def.nodes[n];
					_nodes[node.id] = new R8.Node(node,this)
					_nodes[node.id].init();
				}

				this.setupEvents();
				this.retrievePorts();

				_initialized = true;
			},
			get: function(key) {
				switch(key) {
					case "id":
						return _def.id;
						break;
					case "type":
						return "target";
						break;
					case "ui":
						return _def.ui;
						break;
					case "iaas_type":
						return _def.iaas_type;
						break;
					case "name":
						return _def.name;
						break;
					case "nodes":
						return _nodes;
						break;
					case "project":
						return _project;
						break;
				}
			},
			setupEvents: function() {
//			on: function(eventName,callback,scope) {
				R8.IDE.on('target-'+this.get('id')+'-node-add',this.instantiateNode,this);
			},
//-----------------------------------------------
//VIEW RELATED METHODS-------------------
//-----------------------------------------------
			requireView: function(viewType) {
				if(typeof(_views[viewType]) == 'undefined') _views[viewType] = {};

				_views[viewType] = new R8.IDE.View[viewType].target(this);
			},
			getView: function(viewType) {
				if(typeof(_views[viewType]) == 'undefined') this.requireView(viewType);

				return _views[viewType];
			},
			renderView: function(viewType) {
				if(typeof(_views[viewType]) == 'undefined') this.requireView(viewType);

				return _views[viewType].render();
			},
			initView: function(viewType) {
				return _views[viewType].init();
			},
			isInitialized: function() {
				return _initialized;
			},
//-----------------------------------------------
//END VIEW RELATED METHODS---------------
//-----------------------------------------------

//----------------------------------------------
//TARGET SPECIFIC METHODS
//----------------------------------------------
			hasNode: function(nodeId) {
				for(var n in _nodes) {
					if(_nodes[n].get('id') == nodeId) return true;
				}
				return false;
			},
			deleteNode: function(nodeId) {
				if(!this.hasNode(nodeId)) return false;

				var _this=this;
				var removeNodeFromViews = function(ioId,responseObj) {
					eval("var response =" + responseObj.responseText);
					var delete_result = response.application_node_destroy_and_delete.content[0].data;
//DEBUG
console.log(delete_result);
if(delete_result.result == true) _this.purgeNode(delete_result.id);
				}
				var params = {
					'cfg':{
						'data':''
					},
					'callbacks': {
						'io:success': removeNodeFromViews
					}
				};
				R8.Ctrl.call('node/destroy_and_delete/'+nodeId,params);
			},
			purgeNode: function(nodeId) {
//DEBUG
console.log('should remove node from views....');				
				for(var v in _views) {
					_views[v].removeNode(nodeId);
				}
				delete(_nodes[nodeId]);
			},
			instantiateNode: function(e) {
				var nodePos = e.nodeDef.ui['target-'+this.get('id')];
				_def.ui.items[e.nodeDef.id] = nodePos;

				this.addNode(e.nodeDef,true);
				//----------------------------------------------------------------------

				var ui = {};
				ui[this.get('id')] = nodePos;

				var tempId = e.nodeDef.id;
				var _this = this;
				YUI().use("json", function(Y) {
					var uiStr = Y.JSON.stringify(ui);

					var queryParams = 'ui='+uiStr+'&model_id='+e.nodeDef.node_id+'&model=node';
					queryParams += '&model_redirect=node&action_redirect=get&id_redirect=*id';
					var successCallback = function(ioId,responseObj){
						eval("var response =" + responseObj.responseText);
						var newNodeDef = response.application_node_get.content[0]['data'];

						_this.swapNewNode(tempId,newNodeDef);
//DEBUG
//console.log('completed create of new node...,');
//console.log(newNode);
//						R8.Workspace.setupNewItems();
					}
					var callbacks = {
						'io:success' : successCallback
					};

					var params = {
						'callbacks': callbacks,
						'cfg': {
							'data': queryParams
						}
					}
					R8.Ctrl.call('target/add_item/'+_this.get('id'),params);
				});

			},
			swapNewNode: function(tempId,newNodeDef) {
				_def.ui.items[newNodeDef.id] = _def.ui.items[tempId];
				delete(_def.ui.items[tempId]);

				_nodes[newNodeDef.id] = _nodes[tempId];
				delete(_nodes[tempId]);

				_nodes[newNodeDef.id].refresh(newNodeDef)
			},
//TODO: git rid of newNode, should just check if _initialized=true
//WHY is node always initialized during render??????
			addNode: function(nodeDef,newNode) {
				_nodes[nodeDef.id] = new R8.Node(nodeDef,this);

				for(var v in _views) {
					_views[v].addNode(_nodes[nodeDef.id],newNode);
				}

				_nodes[nodeDef.id].init();
			},
			retrievePorts: function() {
				var that=this;
				var getPortsCallback = function(ioId, responseObj){
					eval("var response =" + responseObj.responseText);
//TODO: revisit once controllers are reworked for cleaner result package
					var portDefs = response['application_target_get_ports']['content'][0]['data'];
					that.setPorts(portDefs);
				}

				var asynCall = function(){
					var params = {
						'cfg': {},
						'callbacks': {'io:success':getPortsCallback}
					};
					R8.Ctrl.call('target/get_ports/' + _def.id, params);
				}
				setTimeout(asynCall, 1);
			},
			setPorts: function(portDefs) {
				for(var n in _nodes) {
					var nodeId = _nodes[n].get('id');
					var nodePorts = [];
					for(var p in portDefs) {
						if(portDefs[p].node_id==nodeId) nodePorts.push(portDefs[p]);
					}

					_nodes[n].setPorts(nodePorts);
				}
			}
		}
	};
}