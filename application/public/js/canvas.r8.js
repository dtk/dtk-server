
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
					{'strokeStyle':'#25A3FC','lineWidth':5,'lineCap':'round'},
					{'strokeStyle':'#63E4FF','lineWidth':3,'lineCap':'round'}
					],
				'dragWire':[
					{'strokeStyle':'#4EF7DE','lineWidth':5,'lineCap':'round'},
					{'strokeStyle':'#FF33FF','lineWidth':3,'lineCap':'round'}
					],
			},

			/**
			 * renderLink will draw a connection between to points on a workspace.
			 * It is overloaded will either take just input of a connectionID, or startNodeID,endNodeID,connectorType
			 * @method renderConnector
			 * @param {string} startNodeID DOM ElementID to start rendering the connector from
			 * @param {string} endNodeID DOM ElementID to finish rendering the connector to
			 * @param {string} connectorType Type of connection to render, Available are fullBezier,startBezier,endBezier,Line,RightAngle
			 */
			renderLink: function(){
				var a = arguments;
				var ctrlPtBaseValue = 100;
				//this use case is for creating new connector on the fly
//TODO: might remove this, this function should just render a curve between two end pts
				if (a.length == 3) {
					var startElemID = a[0];
					var endElemID = a[1];
					var startConnectorFacing = R8.Workspace.ports[startElemID].location;
					var endConnectorFacing = R8.Workspace.ports[endElemID].location;
					var connectorType = a[2];
					var date = new Date();
					var canvasID = date.getTime() + '-' + Math.floor(Math.random()*20);
				} else {
				//this use case is for rendering pre existing connectors
//					var canvasID = a[0];
					var linkDef = a[0];
					var canvasID = linkDef['id'];

//					var startElemID = R8.Workspace.connectors[canvasID].startElement.connectElemID;
//					var startConnectorFacing = R8.Workspace.connectors[canvasID].startElement.location;
					var startElemID = linkDef.startElement.connectElemID;
					var startConnectorFacing = linkDef.startElement.location;
					//assuming one endpoint for now
//					var endElemID = R8.Workspace.connectors[canvasID].endElements[0].connectElemID;
//					var connectorType = R8.Workspace.connectors[canvasID].type;
//					var endConnectorFacing = R8.Workspace.connectors[canvasID].endElements[0].location;
					var endElemID = linkDef.endElements[0].connectElemID;
					var connectorType = linkDef.type;
					var endConnectorFacing = linkDef.endElements[0].location;
				}

				var tempCanvas = document.getElementById(canvasID);

				if (tempCanvas != null) {
					tempCanvas.getContext('2d').clearRect(0, 0, tempCanvas.width, tempCanvas.height);
					var canvasNode = R8.Utils.Y.one('#' + canvasID);
				} else {
					var canvasNode = new R8.Utils.Y.Node.create('<canvas>');
					canvasNode.setAttribute('id', canvasID);
					R8.Utils.Y.one('#viewspace').appendChild(canvasNode);
				}
				delete (tempCanvas);
				//---------------------------------------------------------------------

				var startElemNode = R8.Utils.Y.one('#' + startElemID);
				var endElemNode = R8.Utils.Y.one('#' + endElemID);
//				var startElemXY = startElemNode.getXY();
//				var endElemXY = endElemNode.getXY();

				//DEBUG
				var startElemXY = R8.Component.getPortXY(startElemID);
				var endElemXY = R8.Component.getPortXY(endElemID);

				//get offset for 1/2 start and end node height/widths
				var endElemRegion = endElemNode.get('region');
				var startElemRegion = startElemNode.get('region');
				var startElemXOffset = Math.floor((startElemRegion['right'] - startElemRegion['left']) / 2);
				var startElemYOffset = Math.floor((startElemRegion['bottom'] - startElemRegion['top']) / 2);
				var endElemXOffset = Math.floor((endElemRegion['right'] - endElemRegion['left']) / 2);
				var endElemYOffset = Math.floor((endElemRegion['bottom'] - endElemRegion['top']) / 2);

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

				//StartNode is top left of EndNode
				if (startQuadrant == UPPER_LEFT) {
					var offsetRegion = endElemRegion;
					var elemWidthOffset = offsetRegion['right'] - offsetRegion['left'];
					var elemHeightOffset = offsetRegion['bottom'] - offsetRegion['top'];

					//get height/width of the base canvas bounding box to surround startNode and endNodes
					var canvasBaseWidth = elemWidthOffset + Math.sqrt(Math.pow((startElemXY[0] - endElemXY[0]), 2));
					var canvasBaseHeight = elemHeightOffset + Math.sqrt(Math.pow((startElemXY[1] - endElemXY[1]), 2));

					//calculate bezier control point size here
					var canvasBaseDiagonal = Math.sqrt(Math.pow(canvasBaseHeight, 2) + Math.pow(canvasBaseWidth, 2));

					if((startConnectorFacing == 'north' || startConnectorFacing == 'south') && (endConnectorFacing == 'north' || endConnectorFacing == 'south')) {
						if (canvasBaseDiagonal > ctrlPtBaseValue) {
							var ctrlYPtOffset = ctrlPtBaseValue;
							var ctrlXPtOffset = ctrlPtBaseValue;
						}
						else {
							var ctrlYPtOffset = canvasBaseDiagonal / 2;
							var ctrlXPtOffset = ctrlYPtOffset;
						}
					} else if((startConnectorFacing == 'west' || startConnectorFacing == 'east') && (endConnectorFacing == 'west' || endConnectorFacing == 'east')) {
						if (canvasBaseDiagonal > ctrlPtBaseValue) {
							var ctrlYPtOffset = ctrlPtBaseValue;
							var ctrlXPtOffset = ctrlPtBaseValue;
						}
						else {
							var ctrlYPtOffset = canvasBaseDiagonal / 2;
							var ctrlXPtOffset = ctrlYPtOffset;
						}
					} else {
						if (canvasBaseWidth > ctrlPtBaseValue) var ctrlXPtOffset = ctrlPtBaseValue;
						else var ctrlXPtOffset = canvasBaseWidth;
	
						if (canvasBaseHeight > ctrlPtBaseValue) var ctrlYPtOffset = ctrlPtBaseValue;
						else var ctrlYPtOffset = canvasBaseHeight;
					}

					switch(startConnectorFacing) {
						case 'south':
							if(endConnectorFacing =='east')
								var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
							else
								var canvasActualWidth = canvasBaseWidth;

							if(endConnectorFacing != 'north')
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
							else
								var canvasActualHeight = canvasBaseHeight + (2*ctrlYPtOffset);

							var startX = startElemXOffset;
							var cpX1 = startX;
							var canvasLeft = startElemXY[0];
							if(endConnectorFacing == 'south') {
								var canvasTop = startElemXY[1];
								var startY = startElemYOffset;
								var cpY1 = startElemYOffset + ctrlYPtOffset;
							} else {
								var canvasTop = startElemXY[1] - ctrlYPtOffset;
								var startY = startElemYOffset + ctrlYPtOffset;
								var cpY1 = startElemYOffset + (2 * ctrlYPtOffset);
							}

							break;
						case 'north':
							var startX = startElemXOffset;
							var cpX1 = startX;
							var canvasLeft = startElemXY[0];

							if(endConnectorFacing == 'south') var canvasActualHeight = canvasBaseHeight + (2*ctrlYPtOffset);
							else var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;

							if(endConnectorFacing == 'east')
								var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
							else var canvasActualWidth = canvasBaseWidth;

							var canvasTop = startElemXY[1] - ctrlYPtOffset;
							if(endConnectorFacing != 'south') {
								var startY = startElemYOffset + ctrlYPtOffset;
								var cpY1 = startY - ctrlYPtOffset;
							} else {
								var startY = startElemYOffset + ctrlYPtOffset;
								var cpY1 = startY - (2*ctrlYPtOffset);
							}
							break;
						case 'west':
							if(endConnectorFacing == 'east') var canvasActualWidth = canvasBaseWidth + (2*ctrlXPtOffset);
							else var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;

							if (endConnectorFacing != 'east') {
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
							} else {
								var canvasActualHeight = canvasBaseHeight + (2 * ctrlYPtOffset);
							}
							var canvasTop = startElemXY[1] - ctrlYPtOffset;
							var startY = startElemYOffset + ctrlYPtOffset;
							var cpY1 = startY;

							if (endConnectorFacing != 'east') {
								var canvasLeft = startElemXY[0] - ctrlXPtOffset;
								var startX = startElemXOffset + ctrlXPtOffset;
								var cpX1 = startX - ctrlXPtOffset;
							}
							else {
								var canvasLeft = startElemXY[0] - ctrlXPtOffset;
								var startX = startElemXOffset + ctrlXPtOffset;
								var cpX1 = startX - ctrlXPtOffset;
							}
							break;
						case 'east':
							var startY = startElemYOffset;
							var cpY1 = startY;
							var canvasTop = startElemXY[1];

							if(endConnectorFacing == 'east')
								var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
							else var canvasActualWidth = canvasBaseWidth;

							if(endConnectorFacing == 'south')
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
							else var canvasActualHeight = canvasBaseHeight;

							if(endConnectorFacing != 'west') {
								var canvasLeft = startElemXY[0];
								var startX = startElemXOffset;
								var cpX1 = startX + ctrlXPtOffset;
							} else {
								var canvasLeft = startElemXY[0];
								var startX = startElemXOffset;
								var cpX1 = startX + ctrlXPtOffset;
							}
							break;
					}

					switch(endConnectorFacing) {
						case 'south':
							var endX = canvasActualWidth - endElemXOffset;
							var endY = canvasActualHeight - (ctrlYPtOffset + endElemYOffset);

							var cpX2 = endX;
							var cpY2 = endY + ctrlYPtOffset;
							break;
						case 'north':
							var endX = canvasActualWidth - endElemXOffset;
							var cpX2 = endX;
							if(startConnectorFacing == 'south') {
								var endY = canvasActualHeight - (ctrlYPtOffset + endElemYOffset);
								var cpY2 = endY - ctrlYPtOffset;
							} else {
								var endY = canvasActualHeight - endElemYOffset;
								var cpY2 = endY - ctrlYPtOffset;
							}
							break;
						case 'west':
							if (startConnectorFacing != 'east') {
								var endX = canvasActualWidth - endElemXOffset;
								var cpX2 = endX - ctrlXPtOffset;
							} else {
								var endX = canvasActualWidth - endElemXOffset;
								var cpX2 = endX - ctrlXPtOffset;
							}
							var endY = canvasActualHeight - endElemYOffset;
							var cpY2 = endY;
							break;
						case 'east':
							var endX = canvasActualWidth - (ctrlXPtOffset + endElemXOffset);
							var cpX2 = endX + ctrlXPtOffset;
							if(startConnectorFacing != 'west')
								var endY = canvasActualHeight - endElemYOffset;
							else var endY = canvasActualHeight - (ctrlYPtOffset + endElemYOffset);
							var cpY2 = endY;
							break;
					}
				}
				//StartNode is bottom left of EndNode
				else if (startQuadrant == BOTTOM_LEFT) {
					var offsetRegion = endElemRegion;
					var elemWidthOffset = offsetRegion['right'] - offsetRegion['left'];
					var elemHeightOffset = offsetRegion['bottom'] - offsetRegion['top'];

					//get height/width of the base canvas bounding box to surround startNode and endNodes
					var canvasBaseWidth = elemWidthOffset + Math.sqrt(Math.pow((startElemXY[0] - endElemXY[0]), 2));
					var canvasBaseHeight = elemHeightOffset + Math.sqrt(Math.pow((startElemXY[1] - endElemXY[1]), 2));

					//calculate bezier control point size here
					var canvasBaseDiagonal = Math.sqrt(Math.pow(canvasBaseHeight, 2) + Math.pow(canvasBaseWidth, 2));

					if((startConnectorFacing == 'north' || startConnectorFacing == 'south') && (endConnectorFacing == 'north' || endConnectorFacing == 'south')) {
						if (canvasBaseDiagonal > ctrlPtBaseValue) {
							var ctrlYPtOffset = ctrlPtBaseValue;
							var ctrlXPtOffset = ctrlPtBaseValue;
						}
						else {
							var ctrlYPtOffset = canvasBaseDiagonal / 2;
							var ctrlXPtOffset = ctrlYPtOffset;
						}
					} else if((startConnectorFacing == 'west' || startConnectorFacing == 'east') && (endConnectorFacing == 'west' || endConnectorFacing == 'east')) {
						if (canvasBaseDiagonal > ctrlPtBaseValue) {
							var ctrlYPtOffset = ctrlPtBaseValue;
							var ctrlXPtOffset = ctrlPtBaseValue;
						}
						else {
							var ctrlYPtOffset = canvasBaseDiagonal / 2;
							var ctrlXPtOffset = ctrlYPtOffset;
						}
					} else {
						if (canvasBaseWidth > ctrlPtBaseValue) var ctrlXPtOffset = ctrlPtBaseValue;
						else var ctrlXPtOffset = canvasBaseWidth;
	
						if (canvasBaseHeight > ctrlPtBaseValue) var ctrlYPtOffset = ctrlPtBaseValue;
						else var ctrlYPtOffset = canvasBaseHeight;
					}

					switch(startConnectorFacing) {
						case 'south':
							if(endConnectorFacing =='east')
								var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
							else
								var canvasActualWidth = canvasBaseWidth;

							if(endConnectorFacing == 'south')
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
							else if(endConnectorFacing == 'north')
								var canvasActualHeight = canvasBaseHeight + (2*ctrlYPtOffset);
							else
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;

							var startX = startElemXOffset;
							var cpX1 = startX;
							var canvasLeft = startElemXY[0];
							if(endConnectorFacing != 'north') {
								var canvasTop = endElemXY[1];
								var startY = canvasActualHeight - (ctrlYPtOffset + startElemYOffset);
								var cpY1 = startY + ctrlYPtOffset;
							} else {
								var canvasTop = endElemXY[1] - ctrlYPtOffset;
								var startY = canvasActualHeight - (endElemYOffset + ctrlYPtOffset);
								var cpY1 = startY + ctrlYPtOffset;
							}
							break;
						case 'north':
							var startX = startElemXOffset;
							var cpX1 = startX;
							var canvasLeft = startElemXY[0];

							if(endConnectorFacing == 'east')
								var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
							else var canvasActualWidth = canvasBaseWidth;

							if (endConnectorFacing == 'north') {
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
								var canvasTop = endElemXY[1] - ctrlYPtOffset;
								var startY = canvasActualHeight - startElemYOffset;
								var cpY1 = startY - ctrlYPtOffset;
							} else if(endConnectorFacing == 'south') {
								var canvasTop = endElemXY[1] - ctrlYPtOffset;
								var canvasActualHeight = canvasBaseHeight + (2*ctrlYPtOffset);
								var startY = canvasActualHeight - (ctrlYPtOffset + startElemYOffset);
								var cpY1 = startY - ctrlYPtOffset;
							} else {
								var canvasActualHeight = canvasBaseHeight;
								var canvasTop = endElemXY[1];
								var startY = canvasActualHeight - startElemYOffset;
								var cpY1 = startY - ctrlYPtOffset;
							}
							break;
						case 'west':
							if(endConnectorFacing == 'east') var canvasActualWidth = canvasBaseWidth + (2*ctrlXPtOffset);
							else var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;

							if (endConnectorFacing == 'south' || endConnectorFacing == 'north') {
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
								var canvasTop = endElemXY[1] - ctrlYPtOffset;
							} else {
								var canvasActualHeight = canvasBaseHeight;
								var canvasTop = endElemXY[1];
							}

							var startY = canvasActualHeight - startElemYOffset;
							var cpY1 = startY;

							if (endConnectorFacing != 'east') {
								var canvasLeft = startElemXY[0] - ctrlXPtOffset;
								var startX = startElemXOffset + ctrlXPtOffset;
								var cpX1 = startX - ctrlXPtOffset;
							}
							else {
								var canvasLeft = startElemXY[0] - ctrlXPtOffset;
								var startX = startElemXOffset + ctrlXPtOffset;
								var cpX1 = startX - ctrlXPtOffset;
							}
							break;
						case 'east':

							if(endConnectorFacing == 'west')
								var canvasActualWidth = canvasBaseWidth + (2*ctrlXPtOffset);
							else if(endConnectorFacing == 'east')
								var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
							else var canvasActualWidth = canvasBaseWidth;

							if(endConnectorFacing == 'north') {
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
								var canvasTop = endElemXY[1] - ctrlYPtOffset;
								var startY = canvasActualHeight - startElemYOffset;
								var cpY1 = startY - ctrlYPtOffset;
							} else {
								var canvasActualHeight = canvasBaseHeight;
								var canvasTop = endElemXY[1];
								var startY = canvasActualHeight - startElemYOffset;
								var cpY1 = startY;
							}

							if(endConnectorFacing != 'west') {
								var canvasLeft = startElemXY[0];
								var startX = startElemXOffset;
								var cpX1 = startX + ctrlXPtOffset;
							} else {
								var canvasLeft = startElemXY[0] - ctrlXPtOffset;
								var startX = ctrlXPtOffset + startElemXOffset;
								var cpX1 = startX + ctrlXPtOffset;
							}
							break;
					}

					switch(endConnectorFacing) {
						case 'south':
							var endX = canvasActualWidth - endElemXOffset;
							var cpX2 = endX;

							if(startConnectorFacing == 'north') {
								var endY = ctrlYPtOffset + endElemYOffset;
								var cpY2 = endY + ctrlYPtOffset;
							} else {
								var endY = endElemYOffset;
								var cpY2 = endY + ctrlYPtOffset;
							}
							break;
						case 'north':
							var endX = canvasActualWidth - endElemXOffset;
							var cpX2 = endX;
							var endY = (ctrlYPtOffset + endElemYOffset);
							var cpY2 = endY - ctrlYPtOffset;
							break;
						case 'west':
							if (startConnectorFacing != 'east') {
								var endX = canvasActualWidth - endElemXOffset;
								var cpX2 = endX - ctrlXPtOffset;
								var endY = endElemYOffset;
								var cpY2 = endY;
							} else {
								var endX = canvasActualWidth - (ctrlXPtOffset + endElemXOffset);
								var cpX2 = endX - ctrlXPtOffset;
								var endY = endElemYOffset;
								var cpY2 = endY;
							}
							break;
						case 'east':
							var endX = canvasActualWidth - (ctrlXPtOffset + endElemXOffset);
							var cpX2 = endX + ctrlXPtOffset;
							var endY = endElemYOffset;
							var cpY2 = endY;
							break;
					}
				}
				//StartNode is top right of EndNode
				else if (startQuadrant == UPPER_RIGHT) {
					var offsetRegion = startElemRegion;
					var elemWidthOffset = offsetRegion['right'] - offsetRegion['left'];
					var elemHeightOffset = offsetRegion['bottom'] - offsetRegion['top'];

					//get height/width of the base canvas bounding box to surround startNode and endNodes
					var canvasBaseWidth = elemWidthOffset + Math.sqrt(Math.pow((startElemXY[0] - endElemXY[0]), 2));
					var canvasBaseHeight = elemHeightOffset + Math.sqrt(Math.pow((startElemXY[1] - endElemXY[1]), 2));

					//calculate bezier control point size here
					var canvasBaseDiagonal = Math.sqrt(Math.pow(canvasBaseHeight, 2) + Math.pow(canvasBaseWidth, 2));

					if((startConnectorFacing == 'north' || startConnectorFacing == 'south') && (endConnectorFacing == 'north' || endConnectorFacing == 'south')) {
						if (canvasBaseDiagonal > ctrlPtBaseValue) {
							var ctrlYPtOffset = ctrlPtBaseValue;
							var ctrlXPtOffset = ctrlPtBaseValue;
						}
						else {
							var ctrlYPtOffset = canvasBaseDiagonal / 2;
							var ctrlXPtOffset = ctrlYPtOffset;
						}
					} else if((startConnectorFacing == 'west' || startConnectorFacing == 'east') && (endConnectorFacing == 'west' || endConnectorFacing == 'east')) {
						if (canvasBaseDiagonal > ctrlPtBaseValue) {
							var ctrlYPtOffset = ctrlPtBaseValue;
							var ctrlXPtOffset = ctrlPtBaseValue;
						}
						else {
							var ctrlYPtOffset = canvasBaseDiagonal / 2;
							var ctrlXPtOffset = ctrlYPtOffset;
						}
					} else {
						if (canvasBaseWidth > ctrlPtBaseValue) var ctrlXPtOffset = ctrlPtBaseValue;
						else var ctrlXPtOffset = canvasBaseWidth;
	
						if (canvasBaseHeight > ctrlPtBaseValue) var ctrlYPtOffset = ctrlPtBaseValue;
						else var ctrlYPtOffset = canvasBaseHeight;
					}

					switch(startConnectorFacing) {
						case 'south':
							if(endConnectorFacing == 'west') {
								var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
								var canvasLeft = endElemXY[0] - ctrlXPtOffset;
							} else {
								var canvasActualWidth = canvasBaseWidth;
								var canvasLeft = endElemXY[0];
							}
							if(endConnectorFacing == 'south')
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
							else if(endConnectorFacing == 'north')
								var canvasActualHeight = canvasBaseHeight + (2*ctrlYPtOffset);
							else
								var canvasActualHeight = canvasBaseHeight;

							var startX = canvasActualWidth - endElemXOffset;
							var cpX1 = startX;
							if(endConnectorFacing != 'north') {
								var startY = endElemYOffset;
								var canvasTop = startElemXY[1];
							} else {
								var startY = endElemYOffset + ctrlYPtOffset;
								var canvasTop = startElemXY[1] - ctrlYPtOffset;
							}
							var cpY1 = startY + ctrlYPtOffset;
							break;
						case 'north':
							if(endConnectorFacing == 'west') {
								var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
								var canvasLeft = endElemXY[0] - ctrlXPtOffset;
							} else {
								var canvasActualWidth = canvasBaseWidth;
								var canvasLeft = endElemXY[0];
							}
							var startX = canvasActualWidth - startElemXOffset;
							var cpX1 = startX;

							if (endConnectorFacing == 'north') {
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
							} else if(endConnectorFacing == 'south') {
								var canvasActualHeight = canvasBaseHeight + (2*ctrlYPtOffset);
							} else {
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
							}
							var startY = startElemYOffset + ctrlYPtOffset;
							var cpY1 = startY - ctrlYPtOffset;
							var canvasTop = startElemXY[1] - ctrlYPtOffset;
							break;
						case 'west':
							if(endConnectorFacing == 'east') {
								var canvasActualWidth = canvasBaseWidth + (2 * ctrlXPtOffset);
								var canvasLeft = endElemXY[0] - ctrlXPtOffset;
								var startX = canvasActualWidth - (ctrlXPtOffset + endElemXOffset);
							} else if (endConnectorFacing == 'west') {
								var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
								var canvasLeft = endElemXY[0] - ctrlXPtOffset;
								var startX = canvasActualWidth - endElemXOffset;
							} else {
								var canvasActualWidth = canvasBaseWidth;
								var canvasLeft = endElemXY[0];
								var startX = canvasActualWidth - endElemXOffset;
							}
							var cpX1 = startX - ctrlXPtOffset;

							if(endConnectorFacing == 'south') {
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
								var startY = endElemYOffset;
								var cpY1 = startY;
								var canvasTop = startElemXY[1];
							} else {
								var canvasActualHeight = canvasBaseHeight;
								var startY = startElemYOffset;
								var cpY1 = startY;
								var canvasTop = startElemXY[1];
							}
							break;
						case 'east':
							var startY = startElemYOffset;
							var cpY1 = startY;
							var canvasTop = startElemXY[1];

							if (endConnectorFacing == 'west') {
								var canvasActualWidth = canvasBaseWidth + (2 * ctrlXPtOffset);
								var canvasLeft = endElemXY[0] - ctrlXPtOffset;
							} else {
								var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
								var canvasLeft = endElemXY[0];
							}
							var startX = canvasActualWidth - (ctrlXPtOffset + startElemXOffset);
							var cpX1 = startX + ctrlXPtOffset;

							if(endConnectorFacing == 'south')
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
							else var canvasActualHeight = canvasBaseHeight;

							break;
					}

					switch(endConnectorFacing) {
						case 'south':
							var endX =  endElemXOffset;
							var cpX2 = endX;

							var endY = canvasActualHeight - (ctrlYPtOffset + endElemYOffset);
							var cpY2 = endY + ctrlYPtOffset;
							break;
						case 'north':
							var endX = endElemXOffset;
							var cpX2 = endX;
							if(startConnectorFacing == 'south') {
								var endY = canvasActualHeight - (ctrlYPtOffset + endElemYOffset);
							} else {
								var endY = canvasActualHeight - endElemYOffset;
							}

							var cpY2 = endY - ctrlYPtOffset;
							break;
						case 'west':
							var endX = ctrlXPtOffset + endElemXOffset;
							var cpX2 = endX - ctrlXPtOffset;
							var endY = canvasActualHeight - endElemYOffset;
							var cpY2 = endY;
							break;
						case 'east':
							if(startConnectorFacing == 'west') {
								var endX = endElemXOffset + ctrlXPtOffset;
							} else {
								var endX = endElemXOffset;
							}
							var cpX2 = endX + ctrlXPtOffset;
							var endY = canvasActualHeight - endElemYOffset;
							var cpY2 = endY;
							break;
					}
				}
				//StartNode is bottom right to EndNode
				else if (startQuadrant == BOTTOM_RIGHT) {
					var offsetRegion = startElemRegion;
					var elemWidthOffset = offsetRegion['right'] - offsetRegion['left'];
					var elemHeightOffset = offsetRegion['bottom'] - offsetRegion['top'];

					//get height/width of the base canvas bounding box to surround startNode and endNodes
					var canvasBaseWidth = elemWidthOffset + Math.sqrt(Math.pow((startElemXY[0] - endElemXY[0]), 2));
					var canvasBaseHeight = elemHeightOffset + Math.sqrt(Math.pow((startElemXY[1] - endElemXY[1]), 2));

					//calculate bezier control point size here
					var canvasBaseDiagonal = Math.sqrt(Math.pow(canvasBaseHeight, 2) + Math.pow(canvasBaseWidth, 2));

					if((startConnectorFacing == 'north' || startConnectorFacing == 'south') && (endConnectorFacing == 'north' || endConnectorFacing == 'south')) {
						if (canvasBaseDiagonal > ctrlPtBaseValue) {
							var ctrlYPtOffset = ctrlPtBaseValue;
							var ctrlXPtOffset = ctrlPtBaseValue;
						}
						else {
							var ctrlYPtOffset = canvasBaseDiagonal / 2;
							var ctrlXPtOffset = ctrlYPtOffset;
						}
					} else if((startConnectorFacing == 'west' || startConnectorFacing == 'east') && (endConnectorFacing == 'west' || endConnectorFacing == 'east')) {
						if (canvasBaseDiagonal > ctrlPtBaseValue) {
							var ctrlYPtOffset = ctrlPtBaseValue;
							var ctrlXPtOffset = ctrlPtBaseValue;
						}
						else {
							var ctrlYPtOffset = canvasBaseDiagonal / 2;
							var ctrlXPtOffset = ctrlYPtOffset;
						}
					} else {
						if (canvasBaseWidth > ctrlPtBaseValue) var ctrlXPtOffset = ctrlPtBaseValue;
						else var ctrlXPtOffset = canvasBaseWidth;
	
						if (canvasBaseHeight > ctrlPtBaseValue) var ctrlYPtOffset = ctrlPtBaseValue;
						else var ctrlYPtOffset = canvasBaseHeight;
					}

					switch(startConnectorFacing) {
						case 'south':
							if(endConnectorFacing == 'west') {
								var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
								var canvasLeft = endElemXY[0] - ctrlXPtOffset;
							} else {
								var canvasActualWidth = canvasBaseWidth;
								var canvasLeft = endElemXY[0];
							}
							if(endConnectorFacing == 'north')
								var canvasActualHeight = canvasBaseHeight + (2*ctrlYPtOffset);
							else
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;

							var startX = canvasActualWidth - endElemXOffset;
							var cpX1 = startX;
							if(endConnectorFacing != 'north') {
								var canvasTop = endElemXY[1];
							} else {
								var canvasTop = endElemXY[1] - ctrlYPtOffset;
							}
							var startY = canvasActualHeight - (startElemYOffset + ctrlYPtOffset);
							var cpY1 = startY + ctrlYPtOffset;
							break;
						case 'north':
							if(endConnectorFacing == 'west') {
								var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
								var canvasLeft = endElemXY[0] - ctrlXPtOffset;
							} else {
								var canvasActualWidth = canvasBaseWidth;
								var canvasLeft = endElemXY[0];
							}
							var startX = canvasActualWidth - startElemXOffset;
							var cpX1 = startX;

							if (endConnectorFacing == 'north') {
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
								var startY = canvasActualHeight - startElemYOffset;
								var canvasTop = endElemXY[1] - ctrlYPtOffset;
							} else if(endConnectorFacing == 'south') {
								var canvasActualHeight = canvasBaseHeight + (2*ctrlYPtOffset);
								var startY = canvasActualHeight - (ctrlYPtOffset + startElemYOffset);
								var canvasTop = endElemXY[1] - ctrlYPtOffset;
							} else {
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
								var startY = canvasActualHeight - startElemYOffset;
								var canvasTop = endElemXY[1] - ctrlYPtOffset;
							}
							var cpY1 = startY - ctrlYPtOffset;
							break;
						case 'west':
							if(endConnectorFacing == 'east') {
								var canvasActualWidth = canvasBaseWidth + (2 * ctrlXPtOffset);
								var canvasLeft = endElemXY[0] - ctrlXPtOffset;
								var startX = canvasActualWidth - (ctrlXPtOffset + endElemXOffset);
							} else if (endConnectorFacing == 'west') {
								var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
								var canvasLeft = endElemXY[0] - ctrlXPtOffset;
								var startX = canvasActualWidth - endElemXOffset;
							} else {
								var canvasActualWidth = canvasBaseWidth;
								var canvasLeft = endElemXY[0];
								var startX = canvasActualWidth - endElemXOffset;
							}
							var cpX1 = startX - ctrlXPtOffset;

							if(endConnectorFacing == 'south') {
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
								var canvasTop = endElemXY[1];
								var startY = canvasActualHeight - (ctrlYPtOffset + endElemYOffset);
							} else if (endConnectorFacing == 'north') {
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
								var canvasTop = endElemXY[1] - ctrlYPtOffset;
								var startY = canvasActualHeight - endElemYOffset;
							}
							else {
								var canvasActualHeight = canvasBaseHeight;
								var canvasTop = endElemXY[1];								
								var startY = canvasActualHeight - endElemYOffset;
							}
							var cpY1 = startY;
							break;
						case 'east':
							if(endConnectorFacing == 'north') {
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
							} else {
								var canvasActualHeight = canvasBaseHeight;
							}
							var startY = canvasActualHeight - startElemYOffset;
							var cpY1 = startY;

							if (endConnectorFacing == 'west') {
								var canvasActualWidth = canvasBaseWidth + (2 * ctrlXPtOffset);
								var canvasLeft = endElemXY[0] - ctrlXPtOffset;
								var canvasTop = endElemXY[1];
							} else if(endConnectorFacing == 'north'){
								var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
								var canvasLeft = endElemXY[0];
								var canvasTop = endElemXY[1] - ctrlYPtOffset;
							} else {
								var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
								var canvasLeft = endElemXY[0];
								var canvasTop = endElemXY[1];
							}
							var startX = canvasActualWidth - (ctrlXPtOffset + startElemXOffset);
							var cpX1 = startX + ctrlXPtOffset;

							break;
					}

					switch(endConnectorFacing) {
						case 'south':
							var endX =  endElemXOffset;
							var cpX2 = endX;

							if (startConnectorFacing != 'north') {
								var endY = endElemYOffset;
								var cpY2 = endY + ctrlYPtOffset;
							} else {
								var endY = endElemYOffset + ctrlYPtOffset;
								var cpY2 = endY + ctrlYPtOffset;
							}
							break;
						case 'north':
							var endX = endElemXOffset;
							var cpX2 = endX;
							var endY = ctrlYPtOffset + endElemYOffset;
							var cpY2 = endY - ctrlYPtOffset;
							break;
						case 'west':
							var endX = ctrlXPtOffset + endElemXOffset;
							var cpX2 = endX - ctrlXPtOffset;
							if (startConnectorFacing == 'north') {
								var endY = ctrlYPtOffset + endElemYOffset;
							} else {
								var endY = endElemYOffset;
							}
							var cpY2 = endY;
							break;
						case 'east':
							if(startConnectorFacing == 'west') {
								var endX = endElemXOffset + ctrlXPtOffset;
							} else {
								var endX = endElemXOffset;
							}
							var cpX2 = endX + ctrlXPtOffset;
							if(startConnectorFacing == 'north')
								var endY = ctrlYPtOffset + endElemYOffset;
							else var endY = endElemYOffset;
							var cpY2 = endY;
							break;
					}
				}

				canvasNode.setStyles({
					'top': canvasTop + 'px',
					'left': canvasLeft + 'px'
				});
//TODO: dynamically style the connector, specifically for z-index overlays
//				var canvasClass = connectorType + '-' + ;
				canvasNode.addClass('fullBezier-basic');
				canvasNode.setAttribute('width', canvasActualWidth);
				canvasNode.setAttribute('height', canvasActualHeight);

				// use getContext to use the canvas for drawing
				var ctx = document.getElementById(canvasID).getContext('2d');
				for (var i in this.config.activeConnector) {
					var connectorCfg = this.config.activeConnector[i];
					ctx.beginPath();
					ctx.strokeStyle = connectorCfg.strokeStyle;
					ctx.lineWidth = connectorCfg.lineWidth;
					ctx.lineCap = connectorCfg.lineCap;
					ctx.moveTo(startX, startY);
					ctx.bezierCurveTo(cpX1, cpY1, cpX2, cpY2, endX, endY);
					ctx.stroke();
				}
			},

			/*
			 * renderDragWire currently renders the connector during drag/connect activity
			 * @method renderWire
			 * @param {Node} srcNode
			 * @param {Node} dragNode
			 */
			renderDragWire : function(startElemNode,dragElemNode,portDef) {
				var ctrlPtBaseValue = 100;
				var portsList = workspacePorts;
				var portElemID = startElemNode.get('id');
//				var startPortObj = R8.Workspace.ports[portElemID];
//				var startPortObj = workspacePorts[portElemID];

//				if(typeof(startPortObj) == 'undefined') { console.log('Failed to grab port with ID:'+portElemID); return;}
//				var startElemFacing = startPortObj.location;
				var startElemFacing = portDef.location;

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
							var canvasTop = startElemRegion['top'] - (ctrlYPtOffset+60);

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
							var canvasTop = startElemRegion['top']-60;

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
							var canvasTop = startElemXY[1];

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
							var canvasTop = startElemXY[1];

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
							var canvasLeft = startElemRegion['left'] - 3;
							var canvasTop = startElemRegion['top']-(canvasActualHeight+60) + elemHeightOffset;

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
							var canvasTop = startElemRegion['top'] - ((canvasActualHeight - (ctrlYPtOffset + startElemYOffset))+56);

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
							var canvasTop = dragElemXY[1];

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
							var canvasTop = dragElemXY[1];

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
							var canvasTop = startElemRegion['top'] - (ctrlYPtOffset+60);

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
							var canvasTop = startElemRegion['top']-60;

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
							var canvasTop = startElemXY[1];

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
							var canvasTop = startElemXY[1];

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
							var canvasTop = startElemRegion['top'] - (canvasActualHeight+60) + elemHeightOffset - 3;

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
							var canvasTop = startElemRegion['top'] - ((canvasActualHeight - (ctrlYPtOffset + startElemYOffset))+56);

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
							var canvasTop = dragElemXY[1];

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
							var canvasTop = dragElemXY[1];

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