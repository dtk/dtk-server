
if (!R8.Port) {

	R8.Port = function(portDef,parentObj){
		var _def = portDef,
			_id = _def['id'],
//			_type = _def['type'],
			_dataModel = null,

			_parentObj = parentObj,
			_parentRegion = _parentObj.get('node').get('region'),
			_parentWidth = _parentRegion.right - _parentRegion.left,
			_parentHeight = _parentRegion.bottom - _parentRegion.top,

			_status = null,
			_node = null,
			_top = null,
			_left = null,

			_drag = null;
		
		return {
			render: function() {
				if(_def == null) return;

				this.renderNorth();
			},

			renderNorth: function() {

				//TODO: make this some config param
				var portSpacer = 2;

				var count = 0;
				var prevPortWidth = 0;
				var prevPortHeight = 0;
				var totalPortWidth = 0;
				var totalPortHeight = 0;

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

				this.registerPorts();
			},

			renderSouth: function() {
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
			},

			renderWest: function() {
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
			},

			renderEast: function() {
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

			init: function() {

			}
		}
	};
}