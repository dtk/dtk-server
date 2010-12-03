
if (!R8.Node) {

	R8.Node = function(nodeDef,viewSpace) {
		var _def = nodeDef,
			_id = _def['object']['id'],
			_type = _def['type'],
			_dataModel = null,
			_ports = null,
			_status = null,
			_node = null,
			_top = null,
			_left = null,

			_minimizeBtnId = null,
			_minimizeBtnNode = null,
			_maximizeBtnId = null,
			_maximizeBtnNode = null,

			_viewSpace = viewSpace,
			_toolbar = null;

		return {

			render: function() {
				var tpl_callback = _def['tpl_callback'];
				return R8.Rtpl[tpl_callback]({'node': _def['object']});
			},

			init: function() {
				_node = R8.Utils.Y.one('#item-'+_id);
				_status = _node.getAttribute('data-status');

				if(_status != 'pending_setup') return;

				_top = _node.getStyle('top');
				_left = _node.getStyle('left');
				_dataModel = _node.getAttribute('data-model');

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

			get: function(get_name) {
				switch(get_name) {
					case "id":
						return _id;
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
					default:
						return null;
						break;
				}
			},

			renderPorts: function() {
				if(_ports == null) {
					var that = this;
					var renderCallback = function(ioId,responseObj) {
						eval("R8.Ctrl.callResults[ioId]['response'] =" + responseObj.responseText);
						var response = R8.Ctrl.callResults[ioId]['response'];
						_ports = response['application_node_get_ports']['content'][0]['data'];
//						that.loadPorts();
						that.renderPorts2();
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

			loadPorts: function(ioId,responseObj) {
				eval("R8.Ctrl.callResults[ioId]['response'] =" + responseObj.responseText);
				var response = R8.Ctrl.callResults[ioId]['response'];
				_ports = response['application_node_get_ports']['content'][0]['data'];
			},

			/*
			 * renderPorts adds one or more ports to a given component
			 * @method renderPorts
			 * @param {string} compID ID of the component object to lookup and render 
			 * @param {object} compObj JSON object to render
			 * @return {Node} Returns the node of the rendered component to be appended to workspace container
			 */
			renderPorts2: function() {
				if(_ports == null) return;

				var nodeRegion = _node.get('region'),
					nodeWidth = nodeRegion.right - nodeRegion.left,
					nodeHeight = nodeRegion.bottom - nodeRegion.top;

				//TODO: make this some config param
				var portSpacer = 2;

				var count = 0;
				var prevPortWidth = 0;
				var prevPortHeight = 0;
				var totalPortWidth = 0;
				var totalPortHeight = 0;
				var portObjs = {};


				//------------------------------------
				//Render North Ports
				//------------------------------------
				var numPorts = _ports.length;
				for(i in _ports) {
					var portNodeID = 'port-'+_id+'-north-' + _ports[i]['id'],
						portClass = 'basic-port port',
						portNode = new R8.Utils.Y.Node.create('<div>');

					portObjs[portNodeID] = {};
					portNode.setAttribute('id',portNodeID);
					portNode.addClass(portClass + ' available');
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

return;
				var count = 0;
				var prevPortWidth = 0;
				var prevPortHeight = 0;
				var totalPortWidth = 0;
				var totalPortHeight = 0;
				var portObjs = {};

				//------------------------------------
				//Render South Ports
				//------------------------------------
				var numPorts = R8.Workspace.components[compID].availPorts.south.length;
				for(var port in R8.Workspace.components[compID].availPorts.south) {
					var portNodeID = compID + '-south-' + R8.Workspace.components[compID].availPorts.south[port].id;
					var portClass = R8.Workspace.components[compID].availPorts.south[port].type + '-port';
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

					totalPortWidth += portObjs[portNodeID].width;
					count++;
				}
				var numSpacers = count-1;
				count = 0;
				var prevLeft = 0;
				for(var portNodeID in portObjs) {
					var portNode = R8.Utils.Y.one('#'+portNodeID);
					var top = compNodeHeight - portObjs[portNodeID].hOffset;
					if (count == 0) {
						var left = (compNodeWidth - (totalPortWidth + (numSpacers * portSpacer))) / 2;
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
