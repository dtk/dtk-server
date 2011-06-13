
if (!R8.Node2) {

	R8.Node2 = function(nodeDef,viewSpace) {
		var _def = nodeDef,

//TODO: revisit, id/type/object are needed/shared between tree and workspace, need to merge behavior to one
			_id = (typeof(_def.id) == 'undefined') ?  _def['object']['id'] : _def.id,
			_object = _def['object'],
			_type = _def['type'],

			_os_type = _def.os_type,
			_dataModel = null,
			_ports = {},
			_portDefs = null,
			_portsReady = false,

			_applications = {},
			_leafNode = null,
			_applicationsLeafNode = null,

			c = null,
			_status = null,
			_node = null,
			_top = null,
			_left = null,

			_minimizeBtnId = null,
			_minimizeBtnNode = null,
			_maximizeBtnId = null,
			_maximizeBtnNode = null,

			_portDragDelegate = null,
			_portsReady = false,
//TODO: revisit.., link creation depends on this for drop setup/detection
			_viewSpace = viewSpace,

			_toolbar = null,

			_links = {};

			var _dropList = {};

			var _tempLinkDef = null;
			var _tempLinkObj = null;
			var _tempLinkId = null;

		return {

			render: function() {
				var tpl_callback = _def['tpl_callback'];
				return R8.Rtpl[tpl_callback]({'node': _def['object']});
			},
			renderTree: function() {
				var nodeLeaf = {
					'node_id': 'target-'+_def.id,
					'type': 'node-'+_os_type,
					'basic_type': 'node',
					'name': _def.display_name
//					'name': _def.name
				};

				_leafNode = R8.Utils.Y.Node.create(R8.Rtpl['project_tree_leaf']({'leaf_item': nodeLeaf}));

				var applicationsLeaf = {
					'node_id': 'node-applications-'+_def.id,
					'type': 'applications',
					'basic_type': '',
					'name': 'Applications'
				};
				_applicationsLeafNode = R8.Utils.Y.Node.create(R8.Rtpl['project_tree_leaf']({'leaf_item': applicationsLeaf}));

				var ulNode = R8.Utils.Y.Node.create('<ul></ul>');
				for(var c in _def.components) {
					var componentId = _def.components.id;
					_applications[componentId] = new R8.Component(_def.components[c]);
					ulNode.append(_applications[componentId].renderTree());
				}
				_applicationsLeafNode.append(ulNode);
				var ulNode2 = R8.Utils.Y.Node.create('<ul></ul>');
				ulNode2.append(_applicationsLeafNode);
				_leafNode.append(ulNode2);

				return _leafNode;
			},
			init: function() {
				_node = R8.Utils.Y.one('#item-'+_id);
				_status = _node.getAttribute('data-status');

				if(_status != 'pending_setup') return;

				_top = _node.getStyle('top');
				_left = _node.getStyle('left');
				_dataModel = _node.getAttribute('data-model');

//console.log(_portDefs);
				//if port defs werent passed as part of create, retrieve them
				if(_portDefs == null) {
//DEBUG
					this.retrievePorts();
				}

//DEBUG
//_portDragDelegate = _node.get('id');
				this.setupMinMax();

//TODO: decide if nodes will have toolbars like node groups, else just plug into dock
/*
				if(typeof(_def['toolbar_def']) != 'undefined') {
					_def['toolbar_def']['parent_node_id'] = this.get('node_id');
					_toolbar = new R8.Toolbar(_def['toolbar_def']);
					_toolbar.init();
				}
*
/*
				if(_status == 'pending_delete') {
					_viewSpace.pushPendingDelete(_id,{
						'top':_node.getStyle('top'),
						'left':_node.getStyle('left')
					})
				}
*/
			},

			portsReady: function() {
				return _portsReady;
			},
			refresh: function() {
				var that = this;
				this.retrievePorts(function(ioId,responseObj) {
					eval("var response =" + responseObj.responseText);
//					var response = R8.Ctrl.callResults[ioId]['response'];
					//TODO: revisit once controllers are reworked for cleaner result package
					portDefs = response['application_node_get_ports']['content'][0]['data'];

					var haveNewPorts = false;
					for(var p in portDefs) {
						var portId = 'port-'+portDefs[p]['id'];
						if(typeof(_ports[portId]) == 'undefined') {
							_portDefs.push(portDefs[p]);
							haveNewPorts = true;
						}
					}
//DEBUG
//	haveNewPorts = true;
					if(haveNewPorts == true) {
						that.reflowPorts();
//						that.clearPorts();
//						that.renderPorts();
//						that.refreshLinks();

/*
						var testcb = function() {
							that.renderPorts();
							that.refreshLinks();
						}
						setTimeout(testcb,1000);
*/
					}
				});
			},

			removePortOld: function(portId) {
				delete(_ports['port-'+portId]);
			},

			removePort: function(portId) {
				for(var p in _portDefs) {
					if(portId == ('port-'+_portDefs[p].id)) {
						var portNode = R8.Utils.Y.one('#'+_ports[portId].nodeId);
							portNode.purge(true);
							portNode.remove();
						R8.Utils.arrayRemove(_portDefs,p);
						delete(_ports[portId]);
						this.removeLinkByPortId(portId);
						this.reflowPorts();
						return;
					}
				}
			},
			reflowPorts: function() {
				this.clearPorts();
				this.renderPorts();
				this.updateLinkNodeRefs();
				this.refreshLinks();
			},
			updateLinkNodeRefs: function() {
				for (var p in _portDefs) {
					var portId = 'port-'+_portDefs[p].id,
						portNode = R8.Utils.Y.one('#'+portId),
						link = _viewSpace.getLinkByPortId(_portDefs[p].id);

					if(link == null) continue;

					if(link.get('startNodeId') == portId) {
						link.set('startNode',portNode);
					} else {
						link.set('endNode',portNode);
					}
				}
			},
			removeLinkByPortId: function(portId) {
				for(var l in _links) {
					if(portId == _links[l].startItem.nodeId || portId == _links[l].endItems[0].nodeId) {
						delete(_links[l]);
						return;
					}
				}
			},
/*
			refreshPorts: function(ioId,responseObj) {
				eval("R8.Ctrl.callResults[ioId]['response'] =" + responseObj.responseText);
				var response = R8.Ctrl.callResults[ioId]['response'];
				//TODO: revisit once controllers are reworked for cleaner result package
				portDefs = response['application_node_get_ports']['content'][0]['data'];

				var haveNewPorts = false;
				for(var p in portDefs) {
					var portId = 'port-'+portDefs[p]['id'];
					if(typeof(_ports[portId]) == 'undefined') {
						_ports[portId] = portDefs[p];
						haveNewPorts = true;
					}
				}
//DEBUG
haveNewPorts = true;
				if(haveNewPorts == true) {
					this.clearPorts();
				}
			},
*/
			clearPorts: function() {
				for(var p in _ports) {
					var portNode = R8.Utils.Y.one('#'+_ports[p].nodeId);
						portNode.purge(true);
						portNode.remove();
					delete(_ports[p]);
				}
			},

			retrievePorts: function(callback) {
				var that = this;

				if (typeof(callback) == 'undefined') {
					var getPortsCallback = function(ioId, responseObj){
//						eval("R8.Ctrl.callResults[ioId]['response'] =" + responseObj.responseText);
//						var response = R8.Ctrl.callResults[ioId]['response'];
						eval("var response =" + responseObj.responseText);
						//TODO: revisit once controllers are reworked for cleaner result package
						_portDefs = response['application_node_get_ports']['content'][0]['data'];
					}
				} else {
					var getPortsCallback = callback;
				}

				var asynCall = function(){
					var params = {
						'cfg': {
							'method': 'GET'
						},
						'callbacks': {'io:success':getPortsCallback}
					};
					R8.Ctrl.call('node/get_ports/' + _id, params);
				}
				setTimeout(asynCall, 1);
			},

			get: function(get_name) {
				switch(get_name) {
					case "id":
						return _id;
						break;
					case "type":
						return "node";
						break;
					case "model":
						return _dataModel;
						break;
					case "node_id":
						return _node.get('id');
						break;
					case "node":
						return _node;
						break;
					case "model":
						return _type;
						break;
					case "object":
						return _object;
						break;
					case "portDefs":
						return _ports;
						break;
					default:
						return null;
						break;
				}
			},
/*
			renderPortsOld: function() {

				if(_portDefs == null) {
					var that = this;
					var renderCallback = function(ioId,responseObj) {
						eval("R8.Ctrl.callResults[ioId]['response'] =" + responseObj.responseText);
						var response = R8.Ctrl.callResults[ioId]['response'];
//TODO: revisit once controllers are reworked for cleaner result package
						_portDefs = response['application_node_get_ports']['content'][0]['data'];

//						that.loadPorts();
						that.setupLoadedPorts();
					}
					var asynCall = function(){
						var params = {
							'cfg': {
								'method': 'GET'
							},
//							'callbacks': {'io:success':that.loadPorts}
							'callbacks': {'io:success':renderCallback}
						};
						R8.Ctrl.call('node/get_ports/' + _id, params);
					}
					setTimeout(asynCall, 1);
//					setTimeout(this.renderPorts,200);
					return;
				}
			},
*/
			renderPorts: function() {
				if(_portDefs == null) {
					var that = this;
					var recall = function() {
						that.renderPorts();
					}
					setTimeout(recall,250);
					return;
				}

//				this.setupLoadedPorts();
				if(_portDefs == null) return;

				var nodeRegion = _node.get('region'),
					nodeWidth = nodeRegion.right - nodeRegion.left,
					nodeHeight = nodeRegion.bottom - nodeRegion.top;

//TODO: make this some config param
				var portSpacer = 2;

				var numPorts = _portDefs.length,
					northPorts = [],
					southPorts = [],
					eastPorts = [],
					westPorts = [];

				for (i in _portDefs) {
					switch(_portDefs[i]['location']) {
						case "north":
							northPorts.push(_portDefs[i]);
							break;
						case "south":
							southPorts.push(_portDefs[i]);
							break;
						case "west":
							westPorts.push(_portDefs[i]);
							break;
						case "east":
							eastPorts.push(_portDefs[i]);
							break;
					}
				}

				var count = 0;
				var prevPortWidth = 0;
				var prevPortHeight = 0;
				var totalPortWidth = 0;
				var totalPortHeight = 0;
				var portObjs = {};

				//------------------------------------
				//Render North Ports
				//------------------------------------
				var numPorts = northPorts.length;
				for(i in northPorts) {
					var portNodeID = 'port-'+northPorts[i]['id'],
						portClass = 'basic-port port',
						portNode = new R8.Utils.Y.Node.create('<div>');

					northPorts[i]['nodeId'] = portNodeID;
					_ports[portNodeID] = northPorts[i];

					portObjs[portNodeID] = {};
					portNode.setAttribute('id',portNodeID);
					portNode.addClass(portClass + ' available '+northPorts[i]['port_type']+'-north');
//					portNode.addClass(portClass + ' available');
					_node.appendChild(portNode);

					var portRegion = portNode.get('region');
					portNode.setStyles({'display':'none'});
					portObjs[portNodeID].height = portRegion.bottom - portRegion.top;
					portObjs[portNodeID].width = portRegion.right - portRegion.left;
					portObjs[portNodeID].wOffset = Math.floor(portObjs[portNodeID].width/2);
					portObjs[portNodeID].hOffset = Math.floor(portObjs[portNodeID].height/2);

					totalPortWidth += portObjs[portNodeID].width;
					count++;
				}
				var numSpacers = count-1;
				count = 0;
				var prevLeft = 0;
				for(var portNodeID in portObjs) {
					var portNode = R8.Utils.Y.one('#'+portNodeID);
					var top = -1*(portObjs[portNodeID].hOffset);
					if (count == 0) {
						var left = (nodeWidth - (totalPortWidth + (numSpacers * portSpacer))) / 2;
					} else
						var left = (prevLeft + prevPortWidth + portSpacer);

					portNode.setStyles({'top':(-1*portObjs[portNodeID].hOffset)+'px','left':left+'px','display':'block'});

					totalPortWidth -= (portObjs[portNodeID].width+portSpacer);
					prevPortWidth = portObjs[portNodeID].width;
					prevPortHeight = portObjs[portNodeID].height;
					prevLeft = left;
					count++;
				}
				//END Rendering North Ports

				var count = 0;
				var prevPortWidth = 0;
				var prevPortHeight = 0;
				var totalPortWidth = 0;
				var totalPortHeight = 0;
				var portObjs = {};

				//------------------------------------
				//Render South Ports
				//------------------------------------
				var numPorts = southPorts.length;
				for(i in southPorts) {
					var portNodeID = 'port-'+southPorts[i]['id'],
						portClass = 'basic-port port',
						portNode = new R8.Utils.Y.Node.create('<div>');

					southPorts[i]['nodeId'] = portNodeID;
					_ports[portNodeID] = southPorts[i];

					portObjs[portNodeID] = {};
					portNode.setAttribute('id',portNodeID);
					portNode.addClass(portClass + ' available '+southPorts[i]['port_type']+'-south');
//					portNode.addClass(portClass + ' available');
					_node.appendChild(portNode);

					var portRegion = portNode.get('region');
					portNode.setStyles({'display':'none'});

					portObjs[portNodeID].height = portRegion.bottom - portRegion.top;
					portObjs[portNodeID].width = portRegion.right - portRegion.left;
					portObjs[portNodeID].wOffset = Math.floor(portObjs[portNodeID].width/2);
					portObjs[portNodeID].hOffset = Math.floor(portObjs[portNodeID].height/2);

					totalPortWidth += portObjs[portNodeID].width;
					count++;
				}
				var numSpacers = count-1;
				count = 0;
				var prevLeft = 0;
				for(var portNodeID in portObjs) {
					var portNode = R8.Utils.Y.one('#'+portNodeID);
					var top = nodeHeight - portObjs[portNodeID].hOffset;
					if (count == 0) {
						var left = (nodeWidth - (totalPortWidth + (numSpacers * portSpacer))) / 2;
					} else
						var left = (prevLeft + prevPortWidth + portSpacer);

					portNode.setStyles({'top':top+'px','left':left+'px','display':'block'});

					totalPortWidth -= (portObjs[portNodeID].width+portSpacer);
					prevPortWidth = portObjs[portNodeID].width;
					prevPortHeight = portObjs[portNodeID].height;
					prevLeft = left;
					count++;
				}
				//END Rendering South Ports

				var count = 0;
				var prevPortWidth = 0;
				var prevPortHeight = 0;
				var totalPortWidth = 0;
				var totalPortHeight = 0;
				var portObjs = {};

				//------------------------------------
				//Render West Ports
				//------------------------------------
				var numPorts = westPorts.length;
				for(i in westPorts) {
					var portNodeID = 'port-'+westPorts[i]['id'],
						portClass = 'basic-port port',
						portNode = new R8.Utils.Y.Node.create('<div>');

					westPorts[i]['nodeId'] = portNodeID;
					_ports[portNodeID] = westPorts[i];

					portObjs[portNodeID] = {};
					portNode.setAttribute('id',portNodeID);
					portNode.addClass(portClass + ' available '+westPorts[i]['port_type']+'-west');
					_node.appendChild(portNode);

					var portRegion = portNode.get('region');
					portNode.setStyles({'display':'none'});

					portObjs[portNodeID].height = portRegion.bottom - portRegion.top;
					portObjs[portNodeID].width = portRegion.right - portRegion.left;
					portObjs[portNodeID].wOffset = Math.floor(portObjs[portNodeID].width/2);
					portObjs[portNodeID].hOffset = Math.floor(portObjs[portNodeID].height/2);

					totalPortHeight += portObjs[portNodeID].height;
					count++;
				}
				var numSpacers = count-1;
				count = 0;
				var prevTop = 0;
				for(var portNodeID in portObjs) {
					var portNode = R8.Utils.Y.one('#'+portNodeID);
					var left = -1*(portObjs[portNodeID].wOffset);
					if (count == 0) {
						var top = (nodeHeight - (totalPortHeight + (numSpacers * portSpacer))) / 2;
					} else
						var top = (prevTop + prevPortHeight + portSpacer);

					portNode.setStyles({'top':top+'px','left':left+'px','display':'block'});

					totalPortHeight -= (portObjs[portNodeID].height+portSpacer);
					prevPortWidth = portObjs[portNodeID].width;
					prevPortHeight = portObjs[portNodeID].height;
					prevTop = top;
					count++;
				}
				//END Rendering West Ports

				var count = 0;
				var prevPortWidth = 0;
				var prevPortHeight = 0;
				var totalPortWidth = 0;
				var totalPortHeight = 0;
				var portObjs = {};

				//------------------------------------
				//Render East Ports
				//------------------------------------
				var numPorts = eastPorts.length;
				for(i in eastPorts) {
					var portNodeId = 'port-'+eastPorts[i]['id'],
						portClass = 'basic-port port',
						portNode = new R8.Utils.Y.Node.create('<div>');

					eastPorts[i]['nodeId'] = portNodeId;
					_ports[portNodeId] = eastPorts[i];

					portObjs[portNodeId] = {};
					portNode.setAttribute('id',portNodeId);
					portNode.addClass(portClass + ' available '+eastPorts[i]['port_type']+'-east');
					_node.appendChild(portNode);

					var portRegion = portNode.get('region');
					portNode.setStyles({'display':'none'});

					portObjs[portNodeId].height = portRegion.bottom - portRegion.top;
					portObjs[portNodeId].width = portRegion.right - portRegion.left;
					portObjs[portNodeId].wOffset = Math.floor(portObjs[portNodeId].width/2);
					portObjs[portNodeId].hOffset = Math.floor(portObjs[portNodeId].height/2);

					totalPortHeight += portObjs[portNodeId].height;
					count++;
				}
				var numSpacers = count-1;
				count = 0;
				var prevTop = 0;
				for(var portNodeId in portObjs) {
					var portNode = R8.Utils.Y.one('#'+portNodeId);
					var left = nodeWidth - portObjs[portNodeId].wOffset;
					if (count == 0) {
						var top = (nodeHeight - (totalPortHeight + (numSpacers * portSpacer))) / 2;
					} else
						var top = (prevTop + prevPortHeight + portSpacer);

					portNode.setStyles({'top':top+'px','left':left+'px','display':'block'});
					totalPortHeight -= (portObjs[portNodeId].height+portSpacer);
					prevPortWidth = portObjs[portNodeId].width;
					prevPortHeight = portObjs[portNodeId].height;
					prevTop = top;
					count++;
				}
				//END Rendering East Ports

				this.registerPorts();
				_portsReady = true;
			},

/*
			setupLoadedPorts: function() {
				if(_portDefs == null) return;

				var nodeRegion = _node.get('region'),
					nodeWidth = nodeRegion.right - nodeRegion.left,
					nodeHeight = nodeRegion.bottom - nodeRegion.top;

//TODO: make this some config param
				var portSpacer = 2;


				var numPorts = _portDefs.length,
					northPorts = [],
					southPorts = [];
				for (i in _portDefs) {
					switch(_portDefs[i]['port_type']) {
						case "input":
							_portDefs[i]['location'] = 'south';
							southPorts.push(_portDefs[i]);
							break;
						case "output":
							_portDefs[i]['location'] = 'north';
							northPorts.push(_portDefs[i]);
							break;
					}
				}

				var count = 0;
				var prevPortWidth = 0;
				var prevPortHeight = 0;
				var totalPortWidth = 0;
				var totalPortHeight = 0;
				var portObjs = {};

				//------------------------------------
				//Render North Ports
				//------------------------------------
				var numPorts = northPorts.length;
				for(i in northPorts) {
					var portNodeID = 'port-'+northPorts[i]['id'],
						portClass = 'basic-port port',
						portNode = new R8.Utils.Y.Node.create('<div>');

					northPorts[i]['nodeId'] = portNodeID;
					_ports[portNodeID] = northPorts[i];

					portObjs[portNodeID] = {};
					portNode.setAttribute('id',portNodeID);
					portNode.addClass(portClass + ' available '+northPorts[i]['port_type']+'-north');
//					portNode.addClass(portClass + ' available');
					_node.appendChild(portNode);

					var portRegion = portNode.get('region');
					portNode.setStyles({'display':'none'});
					portObjs[portNodeID].height = portRegion.bottom - portRegion.top;
					portObjs[portNodeID].width = portRegion.right - portRegion.left;
					portObjs[portNodeID].wOffset = Math.floor(portObjs[portNodeID].width/2);
					portObjs[portNodeID].hOffset = Math.floor(portObjs[portNodeID].height/2);

					totalPortWidth += portObjs[portNodeID].width;
					count++;
				}
				var numSpacers = count-1;
				count = 0;
				var prevLeft = 0;
				for(var portNodeID in portObjs) {
					var portNode = R8.Utils.Y.one('#'+portNodeID);
					var top = -1*(portObjs[portNodeID].hOffset);
					if (count == 0) {
						var left = (nodeWidth - (totalPortWidth + (numSpacers * portSpacer))) / 2;
					} else
						var left = (prevLeft + prevPortWidth + portSpacer);

					portNode.setStyles({'top':(-1*portObjs[portNodeID].hOffset)+'px','left':left+'px','display':'block'});

					totalPortWidth -= (portObjs[portNodeID].width+portSpacer);
					prevPortWidth = portObjs[portNodeID].width;
					prevPortHeight = portObjs[portNodeID].height;
					prevLeft = left;
					count++;
				}
				//END Rendering North Ports

				var count = 0;
				var prevPortWidth = 0;
				var prevPortHeight = 0;
				var totalPortWidth = 0;
				var totalPortHeight = 0;
				var portObjs = {};

				//------------------------------------
				//Render South Ports
				//------------------------------------
				var numPorts = southPorts.length;
				for(i in southPorts) {
					var portNodeID = 'port-'+southPorts[i]['id'],
						portClass = 'basic-port port',
						portNode = new R8.Utils.Y.Node.create('<div>');

					southPorts[i]['nodeId'] = portNodeID;
					_ports[portNodeID] = southPorts[i];

					portObjs[portNodeID] = {};
					portNode.setAttribute('id',portNodeID);
					portNode.addClass(portClass + ' available '+southPorts[i]['port_type']+'-south');
//					portNode.addClass(portClass + ' available');
					_node.appendChild(portNode);

					var portRegion = portNode.get('region');
					portNode.setStyles({'display':'none'});

					portObjs[portNodeID].height = portRegion.bottom - portRegion.top;
					portObjs[portNodeID].width = portRegion.right - portRegion.left;
					portObjs[portNodeID].wOffset = Math.floor(portObjs[portNodeID].width/2);
					portObjs[portNodeID].hOffset = Math.floor(portObjs[portNodeID].height/2);

					totalPortWidth += portObjs[portNodeID].width;
					count++;
				}
				var numSpacers = count-1;
				count = 0;
				var prevLeft = 0;
				for(var portNodeID in portObjs) {
					var portNode = R8.Utils.Y.one('#'+portNodeID);
					var top = nodeHeight - portObjs[portNodeID].hOffset;
					if (count == 0) {
						var left = (nodeWidth - (totalPortWidth + (numSpacers * portSpacer))) / 2;
					} else
						var left = (prevLeft + prevPortWidth + portSpacer);

					portNode.setStyles({'top':top+'px','left':left+'px','display':'block'});

					totalPortWidth -= (portObjs[portNodeID].width+portSpacer);
					prevPortWidth = portObjs[portNodeID].width;
					prevPortHeight = portObjs[portNodeID].height;
					prevLeft = left;
					count++;
				}
				//END Rendering South Ports


				this.registerPorts();
return;
				var count = 0;
				var prevPortWidth = 0;
				var prevPortHeight = 0;
				var totalPortWidth = 0;
				var totalPortHeight = 0;
				var portObjs = {};

				//------------------------------------
				//Render West Ports
				//------------------------------------
				var numPorts = R8.Workspace.components[compID].availPorts.west.length;
				for(var port in R8.Workspace.components[compID].availPorts.west) {
					var portNodeID = compID + '-west-' + R8.Workspace.components[compID].availPorts.west[port].id;
					var portClass = R8.Workspace.components[compID].availPorts.west[port].type + '-port';
					portObjs[portNodeID] = {};
					var portNode = new R8.Utils.Y.Node.create('<div>');
					portNode.setAttribute('id',portNodeID);
					portNode.addClass(portClass + ' available');
					compNode.appendChild(portNode);
					var region = portNode.get('region');
					portNode.setStyles({'display':'none'});
					portObjs[portNodeID].height = region.bottom - region.top;
					portObjs[portNodeID].width = region.right - region.left;
					portObjs[portNodeID].wOffset = Math.floor(portObjs[portNodeID].width/2);
					portObjs[portNodeID].hOffset = Math.floor(portObjs[portNodeID].height/2);

					totalPortHeight += portObjs[portNodeID].height;
					count++;
				}
				var numSpacers = count-1;
				count = 0;
				var prevTop = 0;
				for(var portNodeID in portObjs) {
					var portNode = R8.Utils.Y.one('#'+portNodeID);
					var left = -1*(portObjs[portNodeID].wOffset);
					if (count == 0) {
						var top = (compNodeHeight - (totalPortHeight + (numSpacers * portSpacer))) / 2;
					} else
						var top = (prevTop + prevPortHeight + portSpacer);

					portNode.setStyles({'top':top+'px','left':left+'px','display':'block'});

					totalPortHeight -= (portObjs[portNodeID].width+portSpacer);
					prevPortWidth = portObjs[portNodeID].width;
					prevPortHeight = portObjs[portNodeID].height;
					prevTop = top;
					count++;
				}
				//END Rendering West Ports


				var count = 0;
				var prevPortWidth = 0;
				var prevPortHeight = 0;
				var totalPortWidth = 0;
				var totalPortHeight = 0;
				var portObjs = {};

				//------------------------------------
				//Render East Ports
				//------------------------------------
				var numPorts = R8.Workspace.components[compID].availPorts.east.length;
				for(var port in R8.Workspace.components[compID].availPorts.east) {
					var portNodeID = compID + '-east-' + R8.Workspace.components[compID].availPorts.east[port].id;
					var portClass = R8.Workspace.components[compID].availPorts.east[port].type + '-port';
					portObjs[portNodeID] = {};
					var portNode = new R8.Utils.Y.Node.create('<div>');
					portNode.setAttribute('id',portNodeID);
					portNode.addClass(portClass + ' available');
					compNode.appendChild(portNode);
					var region = portNode.get('region');
					portNode.setStyles({'display':'none'});
					portObjs[portNodeID].height = region.bottom - region.top;
					portObjs[portNodeID].width = region.right - region.left;
					portObjs[portNodeID].wOffset = Math.floor(portObjs[portNodeID].width/2);
					portObjs[portNodeID].hOffset = Math.floor(portObjs[portNodeID].height/2);

					totalPortHeight += portObjs[portNodeID].height;
					count++;
				}
				var numSpacers = count-1;
				count = 0;
				var prevTop = 0;
				for(var portNodeID in portObjs) {
					var portNode = R8.Utils.Y.one('#'+portNodeID);
					var left = compNodeWidth - portObjs[portNodeID].wOffset;
					if (count == 0) {
						var top = (compNodeHeight - (totalPortHeight + (numSpacers * portSpacer))) / 2;
					} else
						var top = (prevTop + prevPortHeight + portSpacer);

					portNode.setStyles({'top':top+'px','left':left+'px','display':'block'});

					totalPortHeight -= (portObjs[portNodeID].width+portSpacer);
					prevPortWidth = portObjs[portNodeID].width;
					prevPortHeight = portObjs[portNodeID].height;
					prevTop = top;
					count++;
				}
				//END Rendering East Ports
			},
*/
			hidePorts: function() {
//console.log('going to hide ports...........................');
				for(var p in _ports) {
//console.log(_ports[p]);
					R8.Utils.Y.one('#port-'+_ports[p].id).setStyle('display','none');
				}
			},

			showPorts: function() {
//console.log('going to hide ports...........................');
				for(var p in _ports) {
//console.log(_ports[p]);
					R8.Utils.Y.one('#port-'+_ports[p].id).setStyle('display','block');
				}
			},


			registerPorts: function() {
				var parentItem = this;
				YUI().use('dd-proxy','dd-drag','dd-plugin','dd-drop', function(Y){
					for (var i in _portDefs) {
						_portDefs[i]['drag'] = new Y.DD.Drag({
							node: '#' + _portDefs[i]['nodeId']
						});
						_portDefs[i]['drag'].plug(Y.Plugin.DDProxy, {
							moveOnEnd: false,
							borderStyle: false
						});
						_portDefs[i]['drag'].on('drag:start', function(e){
							e.stopPropagation();

							var drag = this.get('dragNode'), c = e.currentTarget.get('node');
							drag.set('innerHTML',c.get('innerHTML'));
							drag.setAttribute('class', c.getAttribute('class'));
						});
						_portDefs[i]['drag'].on('drag:drag',function(e){
							e.stopPropagation();
							var portId = e.currentTarget.get('node').get('id'),
								portDef = _ports[portId];

//DEBUG
//TODO: revisit, this is to get things rendering in IDE
							R8.Canvas2.renderDragWire(e.currentTarget.get('node'),this.get('dragNode'),portDef,_viewSpace.get('node').get('id'));
//							R8.Canvas.renderDragWire(e.currentTarget.get('node'),this.get('dragNode'),portDef,);
						});
						_portDefs[i]['drag'].on('drag:end',function(e){
							e.stopPropagation();
							var wireCanvas = R8.Utils.Y.one('#wireCanvas');
							R8.Utils.Y.one('#'+_viewSpace.get('node').get('id')).removeChild(wireCanvas);
							delete(wireCanvas);
						});
						_portDefs[i]['drag'].on('drag:mouseDown',function(e){
							var dropList = Y.all('#'+_viewSpace.get('node').get('id')+' .port');
							dropList.each(function(){
								var dropGroup = 'foo';
								var dropId = this.get('id');

								if(typeof(_dropList[dropId]) == 'undefined') {
//								if(!this.hasClass('yui3-dd-drop')) {
									_dropList[dropId] = new Y.DD.Drop({node:this});
									_dropList[dropId].addToGroup([dropGroup]);

									_dropList[dropId].on('drop:enter',function(e){
									});

									_dropList[dropId].on('drop:hit',function(e){
										var endNode = e.drop.get('node'),
											startNode = e.drag.get('node'),
											startNodeId = startNode.get('id'),
											endNodeId = endNode.get('id');
//										var dragNode = e.drag.get('dragNode');

										var endParentId = endNode.get('parentNode').getAttribute('data-id');
										var endPortDef = _viewSpace.getItemPortDef(endParentId,endNode.getAttribute('id'));
										var startPortDef = _ports[startNodeId];

//										var startConnectorLocation = 'north';
//										var startCompID = R8.Workspace.ports[startElemID].compID;
//										var endConnectorLocation = 'north';
//										var endCompID = R8.Workspace.ports[endElemID].compID;
//										var connectorType = 'fullBezier';
										var date = new Date();
//										_tempLinkId = 't-'+date.getTime() + '-' + Math.floor(Math.random()*20);
										_tempLinkId = date.getTime() + '-' + Math.floor(Math.random()*20);

//TODO: temp hack to solve issue of connecting output port on node to input port on monitoring server
if(startPortDef.direction == "output") {
	var portId = endPortDef.id;
//	var itemId = endPortDef.parentItemId;
	var itemId = endParentId;
	var otherEndId = startPortDef.id;
} else {
	var portId = startPortDef.id;
	var otherEndId = endPortDef.id;
	var itemId = _id;
}

										_tempLinkObj = {
											id: _tempLinkId,
											port_id: portId,
//											port_id: startPortDef.id,
//											item_id: _id,
											item_id: itemId,
											other_end_id: otherEndId,
//											other_end_id: endPortDef.id,
											style:[
												{'strokeStyle':'#4EF7DE','lineWidth':5,'lineCap':'round'},
												{'strokeStyle':'#FF33FF','lineWidth':3,'lineCap':'round'}
											]
										}

/*
										_tempLinkDef = {
											'id': _tempLinkId,
											'startItemId':_id,
											'endItemId': endNode.get('parentNode').getAttribute('data-id'),
											'type': connectorType,
											'startItem': {
												'location':startPortDef.location,
												'nodeId':startNodeId,
//												'portNodeId':startNodeId,
												'parentItemId':_id
											},
											'endItems': [{
												'elemID':'?',
												'location':endPortDef.location,
												'nodeId':endNodeId,
//												'portNodeId':endNodeId,
												'parentItemId': endNode.get('parentNode').getAttribute('data-id'),
											}],
											'style':[
												{'strokeStyle':'#4EF7DE','lineWidth':5,'lineCap':'round'},
												{'strokeStyle':'#FF33FF','lineWidth':3,'lineCap':'round'}
											],
										}
*/
/*
										R8.Workspace.connectors[tempConnectorID] = {
											'type': connectorType,
											'startItem': {
												'elemID': '?',
												'location':startConnectorLocation,
												'connectElemID':startNodeId
											},
											'endItems': [{
												'elemID':'?',
												'location':endConnectorLocation,
												'connectElemID':endNodeId
											}]
										};
*/
										if((startPortDef['port_type'] == 'input' && endPortDef['port_type'] == 'output') || (startPortDef['port_type'] == 'output' && endPortDef['port_type'] == 'input')) {
											var parent_id = _viewSpace.get('id'),
												input_id = (startPortDef['port_type'] == 'input') ? startPortDef['id'] : endPortDef['id'],
												output_id = (startPortDef['port_type'] == 'output') ? startPortDef['id'] : endPortDef['id'];

											YUI().use('json','io',function(Y){
												var successCallback = function(ioId,returnObj) {
													parentItem.linkCreateCallback(ioId,returnObj);
												}
												var params = {
													'cfg': {
														'data': 'return_model=true&name=attribute_link&model=attribute_link&redirect=false&parent_model_name=datacenter&parent_id='+parent_id+'&input_id='+input_id+'&output_id='+output_id
													},
													'callbacks': {
														'io:success': successCallback,
//														'io:failure': bar
													}
												};
												R8.Ctrl.call('attribute_link/save',params);
											});

//DEBUG
console.log('calling addLink with tempLinkObj:');
console.log(_tempLinkObj);
											_viewSpace.addLink(_tempLinkObj);

//											R8.Canvas.renderLink(_tempLinkDef);
/*
											var startNode = R8.Utils.Y.one('#'+startNodeId);
											var endNode = R8.Utils.Y.one('#'+endNodeId);
											startNode.removeClass('available');
											startNode.addClass('connected');
											endNode.removeClass('available');
											endNode.addClass('connected');
*/
										} else {
//DEBUG
console.log('not a valid link.., mis-matched types...');
										}
									});
								}
							});

						});
					}
					_portsReady = true;
				});
			},

			linkCreateCallback: function(ioId,responseObj) {
				eval("R8.Ctrl.callResults[ioId]['response'] =" + responseObj.responseText);
				var response = R8.Ctrl.callResults[ioId]['response'];
				var errorData = response.application_attribute_link_save.content[0].data.error;

//TODO: fix error/cleanup scenario with new handling of links
				if(typeof(errorData) != 'undefined') {
					R8.Utils.Y.one('#link-'+_tempLinkObj.id).remove();
					R8.Workspace.showAlert(errorData.error_msg);

					var startPortNode = R8.Utils.Y.one('#port-'+_tempLinkObj.port_id);
					var endPortNode = R8.Utils.Y.one('#port-'+_tempLinkObj.other_end_id);
//					var startPortNode = R8.Utils.Y.one('#'+_tempLinkObj.startItem.nodeId);
//					var endPortNode = R8.Utils.Y.one('#'+_tempLinkObj.endItems[0].nodeId);
					startPortNode.removeClass('connected');
					startPortNode.addClass('available');
					endPortNode.removeClass('connected');
					endPortNode.addClass('available');

					return;
				}

//TODO: revisit after cleaning up responses so dont have to traverse way down to get data
				var linkResult = response.application_attribute_link_save.content[0].data,
					linkChanges = linkResult.link_changes;

				if(typeof(linkChanges) != 'undefined') {
					if (typeof(linkChanges.new_l4_ports) != 'undefined' && linkChanges.new_l4_ports.length > 0) {
						//TODO: assume only one new port for now, revisit to cleanup if no use case is found
						var newPortObjId = linkChanges.new_l4_ports[0], newPortId = 'port-' + newPortObjId;
						var oldPortId = 'port-' + linkChanges.merged_external_ports[0].external_port_id;

//TODO: temp hack b/c of differences between link object returned from create/save and get_links
						var newLink = linkResult.link;
						newLink.port_id = newLink.input_id;
						newLink.other_end_id = newLink.output_id;
						newLink.item_id = _id;
						var swapDef = {
								'oldPortId': oldPortId,
								'newPortId': newPortId,
								'tempLinkObj': _tempLinkObj,
								'newLink': newLink
							}
						if(typeof(_ports[oldPortId]) == 'undefined') {
							//this is node for output port, need input one
							var inputItem = _viewSpace.getItemByPortId(oldPortId);
							inputItem.swapExt4L4(swapDef);
						} else {
							this.swapExt4L4(swapDef);
						}
					} else if (typeof(linkChanges.merged_external_ports) != 'undefined') {
						var mergePortObjId = linkChanges.merged_external_ports[0].external_port_id,
							targetPortObjId = linkChanges.merged_external_ports[0].l4_port_id;

//TODO: temp hack b/c of differences between link object returned from create/save and get_links
/*
						_tempLinkDef.port_id = mergePortObjId;
						_tempLinkDef.other_end_id = targetPortObjId;
						_viewSpace.addLinkToItems(_tempLinkDef);
						_viewSpace.addLink(_tempLinkDef);
*/
						var nodeTest = R8.Utils.Y.one('#port-'+mergePortObjId);
//DEBUG
console.log('Have a link merge scenario link changes are...');
console.log(linkChanges);
console.log('nodeTest:');
console.log(nodeTest);
						if(nodeTest != null) {
							_viewSpace.mergePorts('port-' + mergePortObjId, 'port-' + targetPortObjId);
						}
					}
				}
			},

			swapExt4L4: function(swapDef) {
				var oldPortId = swapDef.oldPortId,
					newPortId = swapDef.newPortId,
					tempLinkObj = swapDef.tempLinkObj,
					newLink = swapDef.newLink;

				var oldPortNodeId = _ports[oldPortId].nodeId;
				R8.Utils.Y.one('#' + oldPortNodeId).set('id', newPortId);

				_ports[newPortId] = _ports[oldPortId];
				_ports[newPortId].id = newPortId;
				_ports[newPortId].nodeId = newPortId;

				var linkId = 'link-'+tempLinkObj.id;
				_viewSpace.removeLink(linkId);

//TODO: temp hack b/c of differences between link object returned from create/save and get_links
				newLink.item_id = _id
				newLink.style =  [
									{'strokeStyle':'#25A3FC','lineWidth':3,'lineCap':'round'},
									{'strokeStyle':'#63E4FF','lineWidth':1,'lineCap':'round'}
								];
				_viewSpace.addLink(newLink);
			},
			portsReady: function() {
				return _portsReady;
			},

			addLink: function(linkDef) {
				_links[linkDef.id] = linkDef;
			},
			removeLink: function(linkId) {
				delete(_links[linkId]);
			},
			refreshLinks: function() {
				for(var l in _links) {
					_viewSpace.links(l).render();
				}
			},
/*
			registerPorts: function() {
//console.log(_portDragDelegate + '    nodeid:'+_node.get('id'));
				YUI().use('dd-delegate', 'dd-proxy', 'dd-drop', 'dd-drop-plugin', 'node', function(Y){
					_portDragDelegate = new Y.DD.Delegate({
						cont: '#' + _node.get('id'),
						nodes: '.port.available'
					});
					_portDragDelegate.dd.plug(Y.Plugin.DDProxy, {
						moveOnEnd: false,
						borderStyle: false
					});
					_portDragDelegate.on('drag:start', function(e) {
//console.log('starting to drag port........'+_node.get('id'));
						e.stopPropagation();

						var drag = this.get('dragNode'), c = this.get('currentNode');
						drag.set('innerHTML',c.get('innerHTML'));
						drag.setAttribute('class', c.getAttribute('class'));
//						this.dd.addToGroup('viewspace_drop');
//						drag.setStyles({
//							opacity: .5,
//							zIndex: 1000
//						});
					});
					_portDragDelegate.on('drag:drag', function(e) {
						e.stopPropagation();
console.log(this.get('currentNode'));
						R8.Canvas.renderDragWire(this.get('currentNode'),this.get('dragNode'));
					});
					_portDragDelegate.on('drag:dropmiss', function(e) {
//console.log('missed port drop');
return;
						var wireCanvas = R8.Utils.Y.one('#wireCanvas');
						R8.Utils.Y.one('#viewspace').removeChild(wireCanvas);
						delete(wireCanvas);
					});

				});
			},
*/
			setupMinMax: function() {
				var nodeId = this.get('node_id'),
					_minimizeBtnId = nodeId+'-minimize-btn',
					_minimizeBtnNode = R8.Utils.Y.one('#'+_minimizeBtnId),
					_maximizeBtnId = nodeId+'-maximize-btn',
					_maximizeBtnNode = R8.Utils.Y.one('#'+_maximizeBtnId);


				if(_minimizeBtnNode != null) {

					//setup minimize
					_minimizeBtnNode.on('mouseover',function(e){
						e.currentTarget.setStyle('backgroundPosition','-16px 0px');
					});
					_minimizeBtnNode.on('mouseout',function(e){
						e.currentTarget.setStyle('backgroundPosition','0px 0px');
					});
					_minimizeBtnNode.on('click',function(e){
						this.minimize();
					},this);

					//setup maximize
					_maximizeBtnNode.on('mouseover',function(e){
						e.currentTarget.setStyle('backgroundPosition','-16px -16px');
					});
					_maximizeBtnNode.on('mouseout',function(e){
						e.currentTarget.setStyle('backgroundPosition','0px -16px');
					});
					_maximizeBtnNode.on('click',function(e){
						this.maximize();
					},this);
				}
			},

			maximize: function() {
				var itemNode = this.get('node'), itemId = this.get('node_id');

				R8.Utils.Y.one('#'+itemId+'-medium').setStyle('display','none');
				R8.Utils.Y.one('#'+itemId+'-large').setStyle('display','block');
				itemNode.addClass('large');
				itemNode.removeClass('medium');
			},

			minimize: function() {
				var itemNode = this.get('node'),itemId = this.get('node_id');

				R8.Utils.Y.one('#'+itemId+'-large').setStyle('display','none');
				R8.Utils.Y.one('#'+itemId+'-medium').setStyle('display','block');
				itemNode.addClass('medium');
				itemNode.removeClass('large');
			},

			hide: function() {
				
			},
			show: function() {
				
			},
			focus: function() {
				
			},

			blur: function() {
				
			}
		}
	};
}
