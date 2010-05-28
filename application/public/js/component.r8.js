
if (!R8.Component) {

	/*
	 * This is the component r8 js class, more to be added
	 */
	R8.Component = function(){
		return {

			/*
			 * render 
			 * @method render
			 * @param {string} compID ID of the component object to lookup and render 
			 * @param {object} compObj JSON object to render
			 * @return {Node} Returns the node of the rendered component to be appended to workspace container
			 */
			render : function() {
				var a = arguments;
				if(typeof(a[0]) === 'object') {
					var component = a[0];
//TODO: currently tpl hardcoded, need to re-implement templating in ruby
					var templateFunc = 'render_'+component['template']+'_component';
//					var componentElem = R8.Templating[templateFunc](component);
					return R8.Templating.render_basic_component(component);
				}
			},

			/*
			 * renderPorts adds one or more ports to a given component
			 * @method renderPorts
			 * @param {string} compID ID of the component object to lookup and render 
			 * @param {object} compObj JSON object to render
			 * @return {Node} Returns the node of the rendered component to be appended to workspace container
			 */
			renderPorts : function() {
				var a = arguments;
				if(typeof(a[0]) === 'object') {
					var compNode = R8.utils.Y.one(a[0]);
				} else if(typeof(a[0]) === 'string') {
					var compNode = R8.utils.Y.one('#' + a[0]);
				}
				var compID = compNode.get('id');
				var compNodeRegion = compNode.get('region');
				var compNodeWidth = compNodeRegion.right - compNodeRegion.left;
				var compNodeHeight = compNodeRegion.bottom - compNodeRegion.top;

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
				var numPorts = R8.Workspace.components[compID].availPorts.north.length;
				for(var port in R8.Workspace.components[compID].availPorts.north) {
					var portNodeID = compID + '-north-' + R8.Workspace.components[compID].availPorts.north[port].id;
					var portClass = R8.Workspace.components[compID].availPorts.north[port].type + '-port';
					portObjs[portNodeID] = {};
					var portNode = new R8.utils.Y.Node.create('<div>');
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
					var portNode = R8.utils.Y.one('#'+portNodeID);
					var top = -1*(portObjs[portNodeID].hOffset);
					if (count == 0) {
						var left = (compNodeWidth - (totalPortWidth + (numSpacers * portSpacer))) / 2;
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
				var numPorts = R8.Workspace.components[compID].availPorts.south.length;
				for(var port in R8.Workspace.components[compID].availPorts.south) {
					var portNodeID = compID + '-south-' + R8.Workspace.components[compID].availPorts.south[port].id;
					var portClass = R8.Workspace.components[compID].availPorts.south[port].type + '-port';
					portObjs[portNodeID] = {};
					var portNode = new R8.utils.Y.Node.create('<div>');
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
					var portNode = R8.utils.Y.one('#'+portNodeID);
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
					var portNode = new R8.utils.Y.Node.create('<div>');
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
					var portNode = R8.utils.Y.one('#'+portNodeID);
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
					var portNode = new R8.utils.Y.Node.create('<div>');
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
					var portNode = R8.utils.Y.one('#'+portNodeID);
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

			/*
			 * updatePorts will re-render all ports for a given component on drag
			 * @method updatePorts
			 * @param {Event} Event object handle for give
			 * @param {string} compID ID for the component to update
			 * 
			 */
			refreshConnectors : function(compID) {
			//	console.log(YUI().Util.Dom.one('#handle1').getXY());
			//	console.log('ID Test:'+componentID);
			
				//TODO: update this once implement generic port model/interface
			//	if(wirePorted != true) return;
			
			//	renderPort('comp1-south','comp2-north','xyz','fullBezier',this);
				for(c in R8.Workspace.components[compID].connectors) {
					R8.Canvas.renderConnector(c);
				}
			}
		}
	}();
}
