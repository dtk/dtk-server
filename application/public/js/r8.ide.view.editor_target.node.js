
if (!R8.IDE.View.editor_target) { R8.IDE.View.editor_target = {}; }

if (!R8.IDE.View.editor_target.node) {

	R8.IDE.View.editor_target.node = function(node) {
		var _node = node,
			_parentView = null,
			_contentNode = null,
			_contentNodePrefix = 'node-',
			_nameNode = null,
			_events = {},
/*
			_minimizeBtnId = null,
			_minimizeBtnNode = null,
			_maximizeBtnId = null,
			_maximizeBtnNode = null,
*/

			_ports = null,
			_numPorts = null,
			_northPorts = [],
			_southPorts = [],
			_eastPorts = [],
			_westPorts = [],
			_portDragDelegate = null,
			_portsReady = false,
//TODO: make this some config param
			_portSpacer = 2,

//TODO: revisit.., link creation depends on this for drop setup/detection
			_applications = {},
//			_viewSpace = viewSpace,

			_toolbar = null,

			_links = {},
			_initialized = false;

			var _dropList = {};

			var _tempLinkDef = null;
			var _tempLinkDef = null;
			var _tempLinkId = null;

		return {
			init: function() {
				_contentNode = R8.Utils.Y.one('#'+_contentNodePrefix+_node.get('id'));
				_nameNode = R8.Utils.Y.one('#'+_contentNodePrefix+_node.get('id')+'-name');

				this.renderPorts();


				this.setupEvents();
//				_status = _node.getAttribute('data-status');

//				if(_status != 'pending_setup') return;



//				_top = _node.getStyle('top');
//				_left = _node.getStyle('left');
//				_dataModel = _node.getAttribute('data-model');

//console.log(_portDefs);
				//if port defs werent passed as part of create, retrieve them
//				if(_portDefs == null) {
//DEBUG
//					this.retrievePorts();
//				}

//DEBUG
//_portDragDelegate = _node.get('id');
//				this.setupMinMax();

//TODO: decide if nodes will have toolbars like node groups, else just plug into dock
/*
				if(typeof(_node['toolbar_node']) != 'undefined') {
					_node['toolbar_node']['parent_node_id'] = this.get('node_id');
					_toolbar = new R8.Toolbar(_node['toolbar_def']);
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
				_initialized = true;
			},
			setupEvents: function() {
				_nameNode.on('dblclick',function(e){
					var inputId = e.currentTarget.get('id')+'-input';
					var nameInputTpl = '<input id="'+inputId+'" type="text" size="20" value="'+_node.get('name')+'"/>'
					e.currentTarget.set('innerHTML', nameInputTpl); 
					var nameInputNode = R8.Utils.Y.one('#'+inputId);
					nameInputNode.on('keypress',function(e){
						if(e.charCode == 13) {
							R8.IDE.fire('node-'+_node.get('id')+'-name-change',{name:e.currentTarget.get('value')});
						}
					},this);
					nameInputNode.focus();
					nameInputNode.on('blur',function(e) {
						_nameNode.set('innerHTML',_node.get('name'));
					},this);
				},this);
			},
			render: function() {
//				var tpl_callback = _node['tpl_callback'];
//				return R8.Rtpl[tpl_callback]({'node': _node['object']});

				var testTpl = '<div id="'+_contentNodePrefix+_node.get('id')+'" class="dg-component item node basic" data-id="'+_node.get('id')+'">\
									<div id="'+_contentNodePrefix+_node.get('id')+'-name" class="name">'+_node.get('name')+'</div>\
							</div>';

				//DEBUG
				//console.log(testTpl);
				return testTpl;
			},
			get: function(key,param) {
				switch(key) {
					case "id":
						return _contentNodePrefix+_node.get('id');
						break;
					case "object":
						return _object;
						break;
					case "type":
						return "node";
						break;
					case "model":
						return _dataModel;
						break;
					case "node":
						return _contentNode;
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
					case "port_by_node_id":
						for(var p in _ports) {
							if(_ports[p].get('node_id') == param) return _ports[p];
						}
						return null;
						break;
					default:
						return null;
						break;
				}
			},
			setParent: function(parentView) {
				_parentView = parentView;
			},
			focus: function() {
			},
			blur: function() {
			},
			close: function() {
			},

//--------------------------------------
//EDITOR TARGET VIEW FUNCTIONS
//--------------------------------------

			addComponent: function() {

			},

		//--------------------------------------
		//PORT FUNCTIONS
		//--------------------------------------
			loadPorts: function() {
				var ports = _node.get('ports');
/*
				if(ports == null) {
					var that = this;
					var recall = function() {
						that.loadPorts();
					}
					setTimeout(recall,250);
					return;
				}
*/
				_ports = {};
//TODO: revsiit why its null
if(ports == null) return;

				_numPorts = ports.length;

				for(var p in ports) {
					var portId = ports[p].get('id');
					_ports[portId] = ports[p].getView('editor_target');

					switch(ports[p].get('location')) {
						case "north":
							_northPorts.push(portId);
							break;
						case "south":
							_southPorts.push(portId);
							break;
						case "east":
							_eastPorts.push(portId);
							break;
						case "west":
							_westPorts.push(portId);
							break;
					}
				}

				this.renderPorts();
				this.registerPorts();
			},
			portsReady: function() {
				return _portsReady;
			},
			renderPorts: function() {
				var ports = _node.get('ports');
				_ports = {};

				//TODO: revsiit why its null
				if(ports == null) return;

				_numPorts = ports.length;

				for(var p in ports) {
					var portId = ports[p].get('id');
					_ports[portId] = ports[p].getView('editor_target');

					switch(ports[p].get('location')) {
						case "north":
							_northPorts.push(portId);
							break;
						case "south":
							_southPorts.push(portId);
							break;
						case "east":
							_eastPorts.push(portId);
							break;
						case "west":
							_westPorts.push(portId);
							break;
					}
				}

				var nodeRegion = _contentNode.get('region'),
					nodeWidth = nodeRegion.right - nodeRegion.left,
					nodeHeight = nodeRegion.bottom - nodeRegion.top;

				var count = 0;
				var prevPortWidth = 0;
				var prevPortHeight = 0;
				var totalPortWidth = 0;
				var totalPortHeight = 0;
				var portObjs = {};

				//------------------------------------
				//Render North Ports
				//------------------------------------
				var numPorts = _northPorts.length;
				for(var p in _northPorts) {
					var portId = _northPorts[p];
					var port = _ports[portId];
					portObjs[portId] = {};

					_contentNode.appendChild(port.render());

					var portNode = port.get('node');
					var portRegion = portNode.get('region');
					portNode.setStyles({'display':'none'});
					portObjs[portId].height = portRegion.bottom - portRegion.top;
					portObjs[portId].width = portRegion.right - portRegion.left;
					portObjs[portId].wOffset = Math.floor(portObjs[portId].width/2);
					portObjs[portId].hOffset = Math.floor(portObjs[portId].height/2);

					totalPortWidth += portObjs[portId].width;
					count++;
				}
				var numSpacers = count-1;
				count = 0;
				var prevLeft = 0;
				for(var portId in portObjs) {
					var portNode = _ports[portId].get('node');
					var top = -1*(portObjs[portId].hOffset);
					if (count == 0) {
						var left = (nodeWidth - (totalPortWidth + (numSpacers * _portSpacer))) / 2;
					} else
						var left = (prevLeft + prevPortWidth + _portSpacer);

					portNode.setStyles({'top':(-1*portObjs[portId].hOffset)+'px','left':left+'px','display':'block'});

					totalPortWidth -= (portObjs[portId].width+_portSpacer);
					prevPortWidth = portObjs[portId].width;
					prevPortHeight = portObjs[portId].height;
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
				var numPorts = _southPorts.length;
				for(p in _southPorts) {
					var portId = _southPorts[p];
					var port = _ports[portId];
					portObjs[portId] = {};

					_contentNode.appendChild(port.render());

					var portNode = port.get('node');
					var portRegion = portNode.get('region');
					portNode.setStyles({'display':'none'});
					portObjs[portId].height = portRegion.bottom - portRegion.top;
					portObjs[portId].width = portRegion.right - portRegion.left;
					portObjs[portId].wOffset = Math.floor(portObjs[portId].width/2);
					portObjs[portId].hOffset = Math.floor(portObjs[portId].height/2)+3;

					totalPortWidth += portObjs[portId].width;
					count++;
				}

				var numSpacers = count-1;
				count = 0;
				var prevLeft = 0;
				for(var portId in portObjs) {
					var portNode = _ports[portId].get('node');
					var top = nodeHeight - portObjs[portId].hOffset;
					if (count == 0) {
						var left = (nodeWidth - (totalPortWidth + (numSpacers * _portSpacer))) / 2;
					} else
						var left = (prevLeft + prevPortWidth + _portSpacer);

					portNode.setStyles({'top':top+'px','left':left+'px','display':'block'});

					totalPortWidth -= (portObjs[portId].width+_portSpacer);
					prevPortWidth = portObjs[portId].width;
					prevPortHeight = portObjs[portId].height;
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
				var numPorts = _westPorts.length;
				for(p in _westPorts) {
					var portId = _westPorts[p];
					var port = _ports[portId];
					portObjs[portId] = {};

					_contentNode.appendChild(port.render());

					var portNode = port.get('node');
					var portRegion = portNode.get('region');
					portNode.setStyles({'display':'none'});
					portObjs[portId].height = portRegion.bottom - portRegion.top;
					portObjs[portId].width = portRegion.right - portRegion.left;
					portObjs[portId].wOffset = Math.floor(portObjs[portId].width/2);
					portObjs[portId].hOffset = Math.floor(portObjs[portId].height/2);

					totalPortWidth += portObjs[portId].width;
					count++;
				}
				var numSpacers = count-1;
				count = 0;
				var prevTop = 0;
				for(var portId in portObjs) {
					var portNode = _ports[portId].get('node');
					var left = -1*(portObjs[portId].wOffset);
					if (count == 0) {
						var top = (nodeHeight - (totalPortHeight + (numSpacers * _portSpacer))) / 2;
					} else
						var top = (prevTop + prevPortHeight + _portSpacer);

					portNode.setStyles({'top':top+'px','left':left+'px','display':'block'});

					totalPortHeight -= (portObjs[portId].height+_portSpacer);
					prevPortWidth = portObjs[portId].width;
					prevPortHeight = portObjs[portId].height;
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
				var numPorts = _eastPorts.length;
				for(p in _eastPorts) {
					var portId = _eastPorts[p];
					var port = _ports[portId];
					portObjs[portId] = {};

					_contentNode.appendChild(port.render());

					var portNode = port.get('node');
					var portRegion = portNode.get('region');
					portNode.setStyles({'display':'none'});
					portObjs[portId].height = portRegion.bottom - portRegion.top;
					portObjs[portId].width = portRegion.right - portRegion.left;
					portObjs[portId].wOffset = Math.floor(portObjs[portId].width/2);
					portObjs[portId].hOffset = Math.floor(portObjs[portId].height/2);

					totalPortWidth += portObjs[portId].width;
					count++;
				}
				var numSpacers = count-1;
				count = 0;
				var prevTop = 0;
				for(var portId in portObjs) {
					var portNode = _ports[portId].get('node');
					var left = nodeWidth - portObjs[portId].wOffset;
					if (count == 0) {
						var top = (nodeHeight - (totalPortHeight + (numSpacers * _portSpacer))) / 2;
					} else
						var top = (prevTop + prevPortHeight + _portSpacer);

					portNode.setStyles({'top':top+'px','left':left+'px','display':'block'});
					totalPortHeight -= (portObjs[portId].height+_portSpacer);
					prevPortWidth = portObjs[portId].width;
					prevPortHeight = portObjs[portId].height;
					prevTop = top;
					count++;
				}
				//END Rendering East Ports

				this.registerPorts();
			},
			hidePorts: function() {
				for(var p in _ports) {
					R8.Utils.Y.one('#port-'+_ports[p].id).setStyle('display','none');
				}
			},
			showPorts: function() {
				for(var p in _ports) {
					R8.Utils.Y.one('#port-'+_ports[p].id).setStyle('display','block');
				}
			},
			registerPorts: function() {
				var _this = this;
				YUI().use('dd-proxy','dd-drag','dd-plugin','dd-drop', function(Y){
					for (var p in _ports) {
						var port = _ports[p];
						var dragEvent = new Y.DD.Drag({
							node: '#' + port.get('id')
						});
						dragEvent.plug(Y.Plugin.DDProxy, {
							moveOnEnd: false,
							borderStyle: false
						});
						dragEvent.on('drag:start', function(e){
							e.stopPropagation();

							var drag = this.get('dragNode'), c = e.currentTarget.get('node');
							drag.set('innerHTML',c.get('innerHTML'));
							drag.setAttribute('class', c.getAttribute('class'));
						});
						dragEvent.on('drag:drag',function(e){
							e.stopPropagation();
							var portId = e.currentTarget.get('node').get('id'),
								port = _this.get('port_by_node_id',_ports[portId]),
								portDef = port.get('def');

							R8.Canvas2.renderDragWire(e.currentTarget.get('node'),this.get('dragNode'),portDef,_parentView.get('node').get('id'));
//							R8.Canvas.renderDragWire(e.currentTarget.get('node'),this.get('dragNode'),portDef,);
						});
						dragEvent.on('drag:end',function(e){
							e.stopPropagation();
							var wireCanvas = R8.Utils.Y.one('#wireCanvas');
							R8.Utils.Y.one('#'+_parentView.get('node').get('id')).removeChild(wireCanvas);
							delete(wireCanvas);
						});
						dragEvent.on('drag:mouseDown',function(e){
							var dropList = Y.all('#'+_parentView.get('node').get('id')+' .port');
							dropList.each(function(){
								var dropGroup = 'portDrop1';
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
											startPortId = startNodeId.replace('port-',''),
											endNodeId = endNode.get('id');
//										var dragNode = e.drag.get('dragNode');

										var endParentId = endNode.get('parentNode').getAttribute('data-id');
										var pDefNodeId = endNode.getAttribute('id');
										var portDefId  = pDefNodeId.replace('port-','');
										if(_node.get('id') == endParentId) {
											var endPort = _node.get('port',portDefId);
										} else {
											var endPort = _node.get('target').get('item',endParentId).get('port',portDefId);
										}
//DEBUG
//console.log('Have an end Port:');
//console.log(endPort);
//										var endPortDef = _viewSpace.getItemPortDef(endParentId,endNode.getAttribute('id'));
//										var startPortDef = _ports[startNodeId];
										var startPort = _node.get('port',startPortId);
//console.log('Have a start port:');
//console.log(startPort);

//										var startConnectorLocation = 'north';
//										var startCompID = R8.Workspace.ports[startElemID].compID;
//										var endConnectorLocation = 'north';
//										var endCompID = R8.Workspace.ports[endElemID].compID;
//										var connectorType = 'fullBezier';
										var date = new Date();
//										_tempLinkId = 't-'+date.getTime() + '-' + Math.floor(Math.random()*20);
										_tempLinkId = date.getTime() + '-' + Math.floor(Math.random()*20);

/*
//TODO: temp hack to solve issue of connecting output port on node to input port on monitoring server
if(startPort.get('direction') == "output") {
	var portId = endPort.get('id');
//	var itemId = endPortDef.parentItemId;
//	var itemId = endParentId;
	var otherEndId = startPort.get('id');
} else {
	var portId = startPort.get('id');
	var otherEndId = endPort.get('id');
//	var itemId = _id;
}
*/
/*
										_tempLinkDef = {
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
*/
										_tempLinkDef = {
											id: _tempLinkId,
//											input_id: startPort.get('id'),
//											output_id: endPort.get('id'),
											ui: {
												type: 'fullBezier',
												style: [{
													'strokeStyle': '#4EF7DE',
													'lineWidth': 5,
													'lineCap': 'round'
												}, {
													'strokeStyle': '#FF33FF',
													'lineWidth': 3,
													'lineCap': 'round'
												}]
											}
										}

										if((startPort.get('direction') == 'input' && endPort.get('direction') == 'output') || (startPort.get('direction') == 'output' && endPort.get('direction') == 'input')) {
											var parent_id = _node.get('target').get('id'),
												input_id = (startPort.get('direction') == 'input') ? startPort.get('id') : endPort.get('id'),
												output_id = (startPort.get('direction') == 'output') ? startPort.get('id') : endPort.get('id');

											_tempLinkDef.input_id = input_id;
											_tempLinkDef.output_id = output_id;

											YUI().use('json','io',function(Y){
												var successCallback = function(ioId,returnObj) {
													_this.linkCreateCallback(ioId,returnObj);
												}
												var params = {
													'cfg': {
														'data': 'return_model=true&name=attribute_link&model=attribute_link&redirect=false&parent_model_name=datacenter&parent_id='+parent_id+'&input_id='+input_id+'&output_id='+output_id+'&temp_link_id='+_tempLinkId
													},
													'callbacks': {
														'io:success': successCallback,
//														'io:failure': bar
													}
												};
												R8.Ctrl.call('attribute_link/save',params);
											});
											_node.get('target').addLink(_tempLinkDef);
//DEBUG
//UNCOMMENT WHEN ALL IS PORTED
//											_viewSpace.addLink(_tempLinkDef);
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
			updateName: function() {
				_nameNode.set('innerHTML',_node.get('name'));
			},
			refresh: function() {
				_contentNode.set('id',_contentNodePrefix+_node.get('id'));
				_nameNode.set('id',_contentNodePrefix+_node.get('id')+'-name');

				_nameNode.set('innerHTML',_node.get('name'));
//DEBUG
console.log('inside of refresh node....');
				this.reflowPorts();
return;
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
					if(haveNewPorts == true) {
						that.reflowPorts();
					}
				});
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
//				this.updateLinkNodeRefs();
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
			clearPorts: function() {
				for(var p in _ports) {
					var portNode = R8.Utils.Y.one('#'+_ports[p].nodeId);
						portNode.purge(true);
						portNode.remove();
					delete(_ports[p]);
				}
			},
			linkCreateCallback: function(ioId,responseObj) {
				eval("R8.Ctrl.callResults[ioId]['response'] =" + responseObj.responseText);
				var response_data = R8.Ctrl.callResults[ioId]['response'].application_attribute_link_save.content[0].data;
//				var errorData = response.application_attribute_link_save.content[0].data.error;

//DEBUG
//console.log('have response from link save call....');
//console.log(response_data);

				var newLinkDef = response_data.link;
				var tempLinkId = response_data.temp_link_id;
				var inputPortDef = response_data.input_port;
				var outputPortDef = response_data.output_port;


/*
//TODO: fix error/cleanup scenario with new handling of links
				if(typeof(errorData) != 'undefined') {
					R8.Utils.Y.one('#link-'+_tempLinkDef.id).remove();
//TODO: re-add error rendering once switch from IDE to workspace it made
//					R8.Workspace.showAlert(errorData.error_msg);

					var startPortNode = R8.Utils.Y.one('#port-'+_tempLinkDef.port_id);
					var endPortNode = R8.Utils.Y.one('#port-'+_tempLinkDef.other_end_id);
//					var startPortNode = R8.Utils.Y.one('#'+_tempLinkDef.startItem.nodeId);
//					var endPortNode = R8.Utils.Y.one('#'+_tempLinkDef.endItems[0].nodeId);
					startPortNode.removeClass('connected');
					startPortNode.addClass('available');
					endPortNode.removeClass('connected');
					endPortNode.addClass('available');

					return;
				}
*/

//TODO: revisit after cleaning up responses so dont have to traverse way down to get data
//				var linkResult = response.application_attribute_link_save.content[0].data,
//					linkChanges = linkResult.link_changes;

				if(typeof(inputPortDef.replace_id) != 'undefined') {
/*
					var swapDef = {
							'oldPortId': inputPort.replace_id,
							'newPortId': inputPort.id,
							'newPortDef': inputPort,
							'tempLinkObj': _tempLinkDef,
							'newLink': link
						}
*/
					var oldPort = _node.get('port',inputPortDef.replace_id);
					if(oldPort == null) {
						//this is node for output port, need input one
						var oppositeNode = _node.get('target').get('itemByPortId',inputPortDef.replace_id);
						oppositeNode.swapInNewPort(inputPortDef.replace_id,inputPortDef);
					} else {
						_node.swapInNewPort(inputPortDef.replace_id,inputPortDef);
					}
				}


//				var linkId = 'link-'+tempLinkObj.id;
				_node.get('target').removeLink(tempLinkId);
				_node.get('target').addLink(newLinkDef);
				return;

//TODO: temp hack b/c of differences between link object returned from create/save and get_links
				newLink.item_id = _id
				newLink.style =  [
									{'strokeStyle':'#25A3FC','lineWidth':3,'lineCap':'round'},
									{'strokeStyle':'#63E4FF','lineWidth':1,'lineCap':'round'}
								];

//-----------------------------------------------
//-----------------------------------------------

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
								'tempLinkObj': _tempLinkDef,
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
//console.log('Have a link merge scenario link changes are...');
//console.log(linkChanges);
//console.log('nodeTest:');
//console.log(nodeTest);
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
				var links = _node.get('links');
				for(var l in links) {
					links[l].render();
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
