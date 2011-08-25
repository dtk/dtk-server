
if (!R8.Canvas) {

	/*
	 * This is the utility r8 js class, more to be added
	 */
	R8.Canvas = function(){
		//defines for starting quadrant for connector rendering in relation to end point
		var UPPER_LEFT = 3;
		var UPPER_RIGHT = 0;
		var BOTTOM_RIGHT = 1;
		var BOTTOM_LEFT = 2;

		return {

//TODO: be able to pass config in onload and update dynamically as needed
			/*
			 * Configurations for canvas (styles,colors,etc)
			 */
			config : {
				'activeConnector':[
					{'strokeStyle':'#25A3FC','lineWidth':3,'lineCap':'round'},
					{'strokeStyle':'#63E4FF','lineWidth':1,'lineCap':'round'}
					],
				'dragWire':[
					{'strokeStyle':'#4EF7DE','lineWidth':5,'lineCap':'round'},
					{'strokeStyle':'#FF33FF','lineWidth':3,'lineCap':'round'}
					],
			},

			/**
			 * renderHanger
			 * @method renderHanger
			 * @param {string} some param here
			 */
			renderHanger: function(linkDef,startPortDef){
				var canvasNodeId = linkDef['id'];
				var startNodeId = startPortDef.nodeId;
				var startPortFacing = startPortDef.location;

//				var endElemID = linkDef.endItems[0].nodeId;
//				var connectorType = linkDef.type;
//				var endConnectorFacing = linkDef.endItems[0].location;
				var styleConfig = linkDef.style;

				var tempCanvas = document.getElementById(canvasNodeId);

				if (tempCanvas != null) {
					tempCanvas.getContext('2d').clearRect(0, 0, tempCanvas.width, tempCanvas.height);
					var canvasNode = R8.Utils.Y.one('#'+canvasNodeId);
				} else {
					var canvasNode = new R8.Utils.Y.Node.create('<canvas>');
					canvasNode.setAttribute('id', canvasNodeId);
					canvasNode.addClass('link');
					canvasNode.addClass('hanger');
					R8.Utils.Y.one('#viewspace').appendChild(canvasNode);
				}
				delete (tempCanvas);
				//---------------------------------------------------------------------

				var startNode = R8.Utils.Y.one('#' + startNodeId);
//				var endElemNode = R8.Utils.Y.one('#' + endElemID);
//				var startElemXY = startElemNode.getXY();
//				var endElemXY = endElemNode.getXY();

				//DEBUG
				var wspaceNode = R8.Utils.Y.one('#viewspace');
				var wspaceXY = wspaceNode.getXY();
				var tempXY = startNode.getXY();
				var startNodeXY = [(tempXY[0]-wspaceXY[0]),(tempXY[1]-wspaceXY[1])];
//				var tempXY = endElemNode.getXY();
//				var endElemXY = [(tempXY[0]-wspaceXY[0]),(tempXY[1]-wspaceXY[1])];

				//get offset for 1/2 start and end node height/widths
//				var endElemRegion = endElemNode.get('region');
				var startNodeRegion = startNode.get('region');
				var startNodeXOffset = Math.floor((startNodeRegion['right'] - startNodeRegion['left']) / 2);
				var startNodeYOffset = Math.floor((startNodeRegion['bottom'] - startNodeRegion['top']) / 2);
//				var endElemXOffset = Math.floor((endElemRegion['right'] - endElemRegion['left']) / 2);
//				var endElemYOffset = Math.floor((endElemRegion['bottom'] - endElemRegion['top']) / 2);

/*
				//check to see the positioning of the source and target objects in relation to eachother
				var startQuadrant = UPPER_RIGHT; //UPPER_RIGHT == 0 == start is above & to right of end target
				if ((startElemXY[0] <= endElemXY[0]) && (startElemXY[1] <= endElemXY[1])) 
					var startQuadrant = UPPER_LEFT;
				else if ((startElemXY[0] >= endElemXY[0]) && (startElemXY[1] <= endElemXY[1])) 
					var startQuadrant = UPPER_RIGHT;
				else if ((startElemXY[0] >= endElemXY[0]) && (startElemXY[1] >= endElemXY[1])) 
					var startQuadrant = BOTTOM_RIGHT;
				else if ((startElemXY[0] <= endElemXY[0]) && (startElemXY[1] >= endElemXY[1])) 
					var startQuadrant = BOTTOM_LEFT;
*/
				var canvasTop = startNodeXY[1];
				var canvasLeft = startNodeXY[0]-25;
				canvasNode.setStyles({
					'top': canvasTop + 'px',
					'left': canvasLeft + 'px'
				});
//TODO: dynamically style the connector, specifically for z-index overlays
//				var canvasClass = connectorType + '-' + ;
				canvasNode.addClass('hangerLink-basic');
//				canvasNode.setAttribute('width', canvasActualWidth);
//				canvasNode.setAttribute('height', canvasActualHeight);

				var canvasWidth = 30;
				var canvasHeight = 30;
				canvasNode.setAttribute('width', canvasWidth);
				canvasNode.setAttribute('height', canvasHeight);

				var startX = canvasWidth;
				var startY = startNodeYOffset;

				// use getContext to use the canvas for drawing
				var ctx = document.getElementById(canvasNodeId).getContext('2d');
				for (var i in styleConfig) {
					var connectorCfg = styleConfig[i];
					ctx.beginPath();
					ctx.strokeStyle = connectorCfg.strokeStyle;
					ctx.lineWidth = connectorCfg.lineWidth;
					ctx.lineCap = connectorCfg.lineCap;
					ctx.moveTo(startX, startY);
					ctx.lineTo(startX-20,startY);
//					ctx.lineTo(startX-20,startY+20);
					ctx.stroke();
				}
			},

			drawFullBezier: function(bezierDef) {
				var tempCanvas = document.getElementById(bezierDef.canvasNodeId);

				if (tempCanvas != null) {
					tempCanvas.getContext('2d').clearRect(0, 0, tempCanvas.width, tempCanvas.height);
					var canvasNode = R8.Utils.Y.one('#' + bezierDef.canvasNodeId);
				} else {
					var canvasNode = new R8.Utils.Y.Node.create('<canvas>');
					canvasNode.setAttribute('id', bezierDef.canvasNodeId);
					bezierDef.parentNode.appendChild(canvasNode);
				}
				delete (tempCanvas);


				canvasNode.setStyles({
					'top': bezierDef.canvasTop + 'px',
					'left': bezierDef.canvasLeft + 'px'
				});
//TODO: dynamically style the link, specifically for z-index overlays
//				var canvasClass = connectorType + '-' + ;
				if(typeof(bezierDef.canvasClass) == 'object' && bezierDef.canvasClass  instanceof Array) {
					for(var c in bezierDef.canvasClass) {
						canvasNode.addClass(bezierDef.canvasClass[c]);
					}
				} else {
					canvasNode.addClass(bezierDef.canvasClass);
				}

				canvasNode.setAttribute('width', bezierDef.canvasWidth);
				canvasNode.setAttribute('height', bezierDef.canvasHeight);

				// use getContext to use the canvas for drawing
				var ctx = document.getElementById(bezierDef.canvasNodeId).getContext('2d');
//DEBUG
console.log('INSIDE OF CANVAS RENDERIGN.., HAVE A BEZIERDEF OF:');
console.log(bezierDef);
				for (var i in bezierDef.style) {
					var connectorCfg = bezierDef.style[i];
					ctx.beginPath();
					ctx.strokeStyle = connectorCfg.strokeStyle;
					ctx.lineWidth = connectorCfg.lineWidth;
					ctx.lineCap = connectorCfg.lineCap;
					ctx.moveTo(bezierDef.startX, bezierDef.startY);
					ctx.bezierCurveTo(bezierDef.cpX1, bezierDef.cpY1, bezierDef.cpX2, bezierDef.cpY2, bezierDef.endX, bezierDef.endY);
					ctx.stroke();
				}
			},

			/*
			 * renderDragWire currently renders the connector during drag/connect activity
			 * @method renderDragWire
			 * @param {Node} srcNode
			 * @param {Node} dragNode
			 */
			renderDragWire : function(startElemNode,dragElemNode,portDef) {
				var ctrlPtBaseValue = 100;
//				var portsList = workspacePorts;
				var portElemID = startElemNode.get('id');
//				var startPortObj = R8.Workspace.ports[portElemID];
//				var startPortObj = workspacePorts[portElemID];

//				if(typeof(startPortObj) == 'undefined') { console.log('Failed to grab port with ID:'+portElemID); return;}
//				var startElemFacing = startPortObj.location;
				var startElemFacing = portDef.location;
//DEBUG
//TODO: revisit, need to offset by top bar size, right now using viewspace.top,need to revisit after
//implementing context views and having multiple at a time
var viewSpaceTop = R8.Utils.Y.one('#viewSpace').get('region').top;

				var canvasID = 'wireCanvas';
				var wireCanvasElem = document.getElementById(canvasID);
				//if null it doesnt exist so add to DOM
				if(wireCanvasElem === null) {
					var canvasElem = new R8.Utils.Y.Node.create('<canvas>');
					canvasElem.setAttribute('id',canvasID);
					R8.Utils.Y.one('#viewspace').appendChild(canvasElem);
				} else {
					var canvasElem = R8.Utils.Y.one('#'+canvasID);
					var width = canvasElem.get('width');
					var height = canvasElem.get('height');
					document.getElementById(canvasID).getContext('2d').clearRect(0,0,width,height);
				}

				var startElemXY = startElemNode.getXY();
				var dragElemXY = dragElemNode.getXY();

				canvasElem.addClass('dragWire');
				canvasElem.setAttribute('id',canvasID);

				//get offset for 1/2 start and end node height/widths
				var dragElemRegion = dragElemNode.get('region');
				var startElemRegion = startElemNode.get('region');
				var startElemXOffset = Math.floor((startElemRegion['right'] - startElemRegion['left']) / 2);
				var startElemYOffset = Math.floor((startElemRegion['bottom'] - startElemRegion['top']) / 2);
				var dragElemXOffset = Math.floor((dragElemRegion['right'] - dragElemRegion['left']) / 2);
				var dragElemYOffset = Math.floor((dragElemRegion['bottom'] - dragElemRegion['top']) / 2);

				//check to see the positioning of the source and target objects in relation to eachother
				var startQuadrant = UPPER_RIGHT; //UPPER_RIGHT == 0 == start is above & to right of end target
				if ((startElemXY[0] <= dragElemXY[0]) && (startElemXY[1] <= dragElemXY[1])) 
					var startQuadrant = UPPER_LEFT;
				else if ((startElemXY[0] >= dragElemXY[0]) && (startElemXY[1] <= dragElemXY[1])) 
					var startQuadrant = UPPER_RIGHT;
				else if ((startElemXY[0] >= dragElemXY[0]) && (startElemXY[1] >= dragElemXY[1])) 
					var startQuadrant = BOTTOM_RIGHT;
				else if ((startElemXY[0] <= dragElemXY[0]) && (startElemXY[1] >= dragElemXY[1])) 
					var startQuadrant = BOTTOM_LEFT;

				if(startQuadrant == UPPER_LEFT) {
					var offsetRegion = dragElemRegion;
					var elemWidthOffset = offsetRegion['right'] - offsetRegion['left'];
					var elemHeightOffset = offsetRegion['bottom'] - offsetRegion['top'];

					//get height/width of the base canvas bounding box to surround startNode and endNodes
					var canvasBaseWidth = elemWidthOffset + Math.sqrt(Math.pow((startElemXY[0] - dragElemXY[0]), 2));
					var canvasBaseHeight = elemHeightOffset + Math.sqrt(Math.pow((startElemXY[1] - dragElemXY[1]), 2));

					//calculate bezier control point size here
					var canvasDiagonal = Math.sqrt(Math.pow(height,2)+Math.pow(width,2));
					if(canvasBaseWidth < ctrlPtBaseValue) var ctrlXPtOffset = canvasBaseWidth/2;
					else var ctrlXPtOffset = ctrlPtBaseValue;
	
					if(canvasBaseHeight < ctrlPtBaseValue) var ctrlYPtOffset = canvasBaseHeight/2;
					else var ctrlYPtOffset = ctrlPtBaseValue;

//console.log('canvasBaseHeight:'+canvasBaseHeight+ '    canvasBaseWidth:'+canvasBaseWidth);

					switch(startElemFacing) {
						case 'north':
							var canvasActualWidth = canvasBaseWidth;
							var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
//DEBUG
//TODO: figure out why positioning is off by factor of the height of the toolbars
//							var canvasLeft = startElemXY[0];
//							var canvasTop = startElemXY[1] - ctrlYPtOffset;
							var canvasLeft = startElemXY[0];
//							var canvasTop = startElemRegion['top'] - (ctrlYPtOffset+60);
							var canvasTop = startElemRegion['top'] - (ctrlYPtOffset+viewSpaceTop);

							var startX = startElemXOffset;
							var startY = startElemYOffset + ctrlYPtOffset;
							var cpX1 = startX;
							var cpY1 = startY - ctrlYPtOffset;
							var endX = canvasActualWidth - dragElemXOffset;
							var endY = canvasActualHeight - dragElemYOffset;
							break;
						case 'south':
							var canvasActualWidth = canvasBaseWidth;
							var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
//DEBUG
//TODO: figure out why positioning is off by factor of the height of the toolbars
//							var canvasLeft = startElemXY[0];
//							var canvasTop = startElemXY[1];
							var canvasLeft = startElemRegion['left'];
							var canvasTop = startElemRegion['top']-viewSpaceTop;

							var startX = startElemXOffset;
							var startY = startElemYOffset;
							var cpX1 = startX;
							var cpY1 = startElemYOffset + ctrlYPtOffset;
							var endX = canvasActualWidth - dragElemXOffset;
							var endY = canvasActualHeight - (ctrlYPtOffset + dragElemYOffset);
							break;
						case 'east':
							var canvasActualWidth = canvasBaseWidth;
							var canvasActualHeight = canvasBaseHeight;
							var canvasLeft = startElemXY[0];
							var canvasTop = startElemXY[1] - viewSpaceTop;

							var startX = startElemXOffset;
							var startY = startElemYOffset;
							var cpX1 = startX + ctrlXPtOffset;
							var cpY1 = startY;
							var endX = canvasActualWidth - dragElemXOffset;
							var endY = canvasActualHeight - dragElemYOffset;
							break;
						case 'west':
							var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
							var canvasActualHeight = canvasBaseHeight;
							var canvasLeft = startElemXY[0] - ctrlXPtOffset;
							var canvasTop = startElemXY[1] - viewSpaceTop;

							var startX = startElemXOffset + ctrlXPtOffset;
							var startY = startElemYOffset;
							var cpX1 = startX - ctrlXPtOffset;
							var cpY1 = startY;
							var endX = canvasActualWidth - dragElemXOffset;
							var endY = canvasActualHeight - dragElemYOffset;
							break;
					}

					var cpX2 = endX;
					var cpY2 = endY;
/*
console.log('startX:'+ startX + '    startY:' + startY);
console.log('cpX1:'+ cpX1 + '    cpY1:' + cpY1);
console.log('cpX2:'+ cpX2 + '    cpY2:' + cpY2);
console.log('endX:'+ endX + '    endY:' + endY);
console.log('------------------');
*/				}
				else if(startQuadrant == BOTTOM_LEFT) {
					var offsetRegion = dragElemRegion;
					var elemWidthOffset = offsetRegion['right'] - offsetRegion['left'];
					var elemHeightOffset = offsetRegion['bottom'] - offsetRegion['top'];

					//get height/width of the base canvas bounding box to surround startNode and endNodes
					var canvasBaseWidth = elemWidthOffset + Math.sqrt(Math.pow((startElemXY[0] - dragElemXY[0]), 2));
					var canvasBaseHeight = elemHeightOffset + Math.sqrt(Math.pow((startElemXY[1] - dragElemXY[1]), 2));

					//calculate bezier control point size here
					var canvasDiagonal = Math.sqrt(Math.pow(height,2)+Math.pow(width,2));
					if(canvasBaseWidth < ctrlPtBaseValue) var ctrlXPtOffset = canvasBaseWidth/2;
					else var ctrlXPtOffset = ctrlPtBaseValue;
	
					if(canvasBaseHeight < ctrlPtBaseValue) var ctrlYPtOffset = canvasBaseHeight/2;
					else var ctrlYPtOffset = ctrlPtBaseValue;

					switch(startElemFacing) {
						case 'north':
							var canvasActualWidth = canvasBaseWidth;
							var canvasActualHeight = canvasBaseHeight;
//							var canvasLeft = startElemXY[0];
//							var canvasTop = dragElemXY[1];
//DEBUG
//TODO: figure out why positioning is off by factor of the toolbars at the top.., 25px + 35px
							var canvasLeft = startElemRegion['left'];
							var canvasTop = startElemRegion['top']-(canvasActualHeight+viewSpaceTop) + elemHeightOffset;

							var startX = startElemXOffset;
							var startY = canvasActualHeight - startElemYOffset;

							var cpX1 = startX;
							var cpY1 = startY - ctrlYPtOffset;
							var endX = canvasActualWidth - dragElemXOffset;
							var endY = dragElemYOffset;
							break;
						case 'south':
							var canvasActualWidth = canvasBaseWidth;
							var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
//DEBUG
//TODO: figure out why positioning is off by factor of the height of the toolbars
//							var canvasLeft = startElemXY[0];
//							var canvasTop = dragElemXY[1];
							var canvasLeft = startElemRegion['left'];
//							var canvasTop = startElemRegion['top'] - ((canvasActualHeight - (ctrlYPtOffset + startElemYOffset))+viewSpaceTop);
							var canvasTop = startElemRegion['top'] - ((canvasActualHeight - (ctrlYPtOffset + (2*startElemYOffset)))+viewSpaceTop);

							var startX = startElemXOffset;
							var startY = canvasActualHeight - (ctrlYPtOffset + startElemYOffset);
							var cpX1 = startX;
							var cpY1 = startY + ctrlYPtOffset;
							var endX = canvasActualWidth - dragElemXOffset;
							var endY = dragElemYOffset;
							break;
						case 'east':
							var canvasActualWidth = canvasBaseWidth;
							var canvasActualHeight = canvasBaseHeight;
							var canvasLeft = startElemXY[0];
							var canvasTop = dragElemXY[1] - viewSpaceTop;

							var startX = startElemXOffset;
							var startY = canvasActualHeight - startElemYOffset;
							var cpX1 = startX + ctrlXPtOffset;
							var cpY1 = startY;
							var endX = canvasActualWidth - dragElemXOffset;
							var endY = dragElemYOffset;
							break;
						case 'west':
							var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
							var canvasActualHeight = canvasBaseHeight;
							var canvasLeft = startElemXY[0] - ctrlXPtOffset;
							var canvasTop = dragElemXY[1] - viewSpaceTop;

							var startX = startElemXOffset + ctrlXPtOffset;
							var startY = canvasActualHeight - startElemYOffset;
							var cpX1 = startX - ctrlXPtOffset;
							var cpY1 = startY;
							var endX = canvasActualWidth - dragElemXOffset;
							var endY = dragElemYOffset;
							break;
					}

					var cpX2 = endX;
					var cpY2 = endY;
				}
				else if(startQuadrant == UPPER_RIGHT) {
					var offsetRegion = startElemRegion;
					var elemWidthOffset = offsetRegion['right'] - offsetRegion['left'];
					var elemHeightOffset = offsetRegion['bottom'] - offsetRegion['top'];

					//get height/width of the base canvas bounding box to surround startNode and endNodes
					var canvasBaseWidth = elemWidthOffset + Math.sqrt(Math.pow((startElemXY[0] - dragElemXY[0]), 2));
					var canvasBaseHeight = elemHeightOffset + Math.sqrt(Math.pow((startElemXY[1] - dragElemXY[1]), 2));

					//calculate bezier control point size here
					var canvasDiagonal = Math.sqrt(Math.pow(height,2)+Math.pow(width,2));
					if(canvasBaseWidth < ctrlPtBaseValue) var ctrlXPtOffset = canvasBaseWidth/2;
					else var ctrlXPtOffset = ctrlPtBaseValue;
	
					if(canvasBaseHeight < ctrlPtBaseValue) var ctrlYPtOffset = canvasBaseHeight/2;
					else var ctrlYPtOffset = ctrlPtBaseValue;

					switch(startElemFacing) {
						case 'north':
							var canvasActualWidth = canvasBaseWidth;
							var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
//DEBUG
//TODO: figure out why postitioning is off by factor of toolbar height..,25px+35px
//							var canvasLeft = dragElemXY[0];
//							var canvasTop = startElemXY[1] - ctrlYPtOffset;
							var canvasLeft = dragElemXY[0];
							var canvasTop = startElemRegion['top'] - (ctrlYPtOffset+viewSpaceTop);

							var startX = canvasActualWidth - startElemXOffset;
							var startY = ctrlYPtOffset + startElemYOffset;
							var cpX1 = startX;
							var cpY1 = startY - ctrlYPtOffset;
							var endX = dragElemXOffset;
							var endY = canvasActualHeight - dragElemYOffset;
							break;
						case 'south':
							var canvasActualWidth = canvasBaseWidth;
							var canvasActualHeight = canvasBaseHeight;
//DEBUG
//TODO: figure out why positioning is off by factor of the height of the toolbars
//							var canvasLeft = dragElemXY[0];
//							var canvasTop = startElemXY[1];
							var canvasLeft = dragElemRegion['left'];
							var canvasTop = startElemRegion['top']-viewSpaceTop;

							var startX = canvasActualWidth - startElemXOffset;
							var startY = startElemYOffset;
							var cpX1 = startX;
							var cpY1 = startY + ctrlYPtOffset;
							var endX = dragElemXOffset;
							var endY = canvasActualHeight - dragElemYOffset;
							break;
						case 'east':
							var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
							var canvasActualHeight = canvasBaseHeight;
							var canvasLeft = dragElemXY[0];
							var canvasTop = startElemXY[1] - viewSpaceTop;

							var startX = canvasActualWidth - (ctrlXPtOffset + startElemXOffset);
							var startY = startElemYOffset;
							var cpX1 = startX + ctrlXPtOffset;
							var cpY1 = startY;
							var endX = dragElemXOffset;
							var endY = canvasActualHeight - dragElemYOffset;
							break;
						case 'west':
							var canvasActualWidth = canvasBaseWidth;
							var canvasActualHeight = canvasBaseHeight;
							var canvasLeft = dragElemXY[0];
							var canvasTop = startElemXY[1] - viewSpaceTop;

							var startX = canvasActualWidth - startElemYOffset;
							var startY = startElemYOffset;
							var cpX1 = startX - ctrlXPtOffset;
							var cpY1 = startY;
							var endX = dragElemXOffset;
							var endY = canvasActualHeight - dragElemYOffset;
							break;
					}

					var cpX2 = endX;
					var cpY2 = endY;
				}
				else if(startQuadrant == BOTTOM_RIGHT) {
					var offsetRegion = startElemRegion;
					var elemWidthOffset = offsetRegion['right'] - offsetRegion['left'];
					var elemHeightOffset = offsetRegion['bottom'] - offsetRegion['top'];

					//get height/width of the base canvas bounding box to surround startNode and endNodes
					var canvasBaseWidth = elemWidthOffset + Math.sqrt(Math.pow((startElemXY[0] - dragElemXY[0]), 2));
					var canvasBaseHeight = elemHeightOffset + Math.sqrt(Math.pow((startElemXY[1] - dragElemXY[1]), 2));

					//calculate bezier control point size here
					var canvasDiagonal = Math.sqrt(Math.pow(height,2)+Math.pow(width,2));
					if(canvasBaseWidth < ctrlPtBaseValue) var ctrlXPtOffset = canvasBaseWidth/2;
					else var ctrlXPtOffset = ctrlPtBaseValue;
	
					if(canvasBaseHeight < ctrlPtBaseValue) var ctrlYPtOffset = canvasBaseHeight/2;
					else var ctrlYPtOffset = ctrlPtBaseValue;

					switch(startElemFacing) {
						case 'north':
							var canvasActualWidth = canvasBaseWidth;
							var canvasActualHeight = canvasBaseHeight;
//DEBUG
//TODO: figure out why postitioning is off by factor of toolbar height..,25px+35px
//							var canvasLeft = dragElemXY[0];
//							var canvasTop = dragElemXY[1];
							var canvasLeft = dragElemRegion['left'];
							var canvasTop = startElemRegion['top'] - (canvasActualHeight+viewSpaceTop) + elemHeightOffset;

							var startX = canvasActualWidth - startElemXOffset;
							var startY = canvasActualHeight - startElemYOffset;
							var cpX1 = startX;
							var cpY1 = startY - ctrlYPtOffset;
							var endX = dragElemXOffset;
							var endY = dragElemYOffset;
							break;
						case 'south':
							var canvasActualWidth = canvasBaseWidth;
							var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
//DEBUG
//TODO: figure out why positioning is off by factor of the height of the toolbars
//							var canvasLeft = dragElemXY[0];
//							var canvasTop = dragElemXY[1];
							var canvasLeft = dragElemRegion['left'];
							var canvasTop = startElemRegion['top'] - ((canvasActualHeight - (ctrlYPtOffset + (2*startElemYOffset)))+viewSpaceTop);

							var startX = canvasActualWidth - startElemXOffset;
							var startY = canvasActualHeight - (ctrlYPtOffset + startElemYOffset);
							var cpX1 = startX;
							var cpY1 = startY + ctrlYPtOffset;
							var endX = dragElemXOffset;
							var endY = dragElemYOffset;
							break;
						case 'east':
							var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
							var canvasActualHeight = canvasBaseHeight;
							var canvasLeft = dragElemXY[0];
							var canvasTop = dragElemXY[1] - viewSpaceTop;

							var startX = canvasActualWidth - (ctrlXPtOffset + startElemXOffset);
							var startY = canvasActualHeight - startElemYOffset;
							var cpX1 = startX + ctrlXPtOffset;
							var cpY1 = startY;
							var endX = dragElemXOffset;
							var endY = dragElemYOffset;
							break;
						case 'west':
							var canvasActualWidth = canvasBaseWidth;
							var canvasActualHeight = canvasBaseHeight;
							var canvasLeft = dragElemXY[0];
							var canvasTop = dragElemXY[1] - viewSpaceTop;

							var startX = canvasActualWidth - startElemXOffset;
							var startY = canvasActualHeight - startElemYOffset;
							var cpX1 = startX - ctrlXPtOffset;
							var cpY1 = startY;
							var endX = dragElemXOffset;
							var endY = dragElemYOffset;
							break;
					}

					var cpX2 = endX;
					var cpY2 = endY;
				}

				canvasElem.setAttribute('width',canvasActualWidth);
				canvasElem.setAttribute('height',canvasActualHeight);
				canvasElem.setStyles({
					'top': canvasTop + 'px',
					'left': canvasLeft + 'px'
				});

				var ctx = document.getElementById(canvasID).getContext('2d');

				for (var i in R8.Canvas.config.dragWire) {
					var connectorCfg = R8.Canvas.config.dragWire[i];
					ctx.beginPath();
					ctx.strokeStyle = connectorCfg.strokeStyle;
					ctx.lineWidth = connectorCfg.lineWidth;
					ctx.lineCap = connectorCfg.lineCap;
					ctx.moveTo(startX, startY);
					ctx.bezierCurveTo(cpX1, cpY1, cpX2, cpY2, endX, endY);
					ctx.stroke();
				}

			},

		}
	}();
}