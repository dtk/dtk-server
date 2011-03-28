

if(!R8.Link) {

	R8.Link = function(linkObj,viewSpace) {
		//defines for starting quadrant for connector rendering in relation to end point
		var UPPER_LEFT = 3;
		var UPPER_RIGHT = 0;
		var BOTTOM_RIGHT = 1;
		var BOTTOM_LEFT = 2;

		var _linkObj = linkObj,
			_linkDef = null,
			_readyState = false,
			_viewSpace = viewSpace,

			_id = 'link-'+_linkObj.id,
			_canvasNodeId = _id,
			_fullBezierClass = ['link','full-bezier'],
			_fullBezierDef = null,
			_halfBezierDef = null,
			_hangerDef = null,

			_portId = _linkObj.port_id,
			_itemId = _linkObj.item_id,

			_startNode = null,
			_startNodeId = 'port-'+_portId,
			_startPortDef = null,
			_startPortLocation = '?',

			_endNode = null,
			_otherEndId = _linkObj.other_end_id,
			_endNodeId = 'port-'+_linkObj.other_end_id,
			_endPortDef = null,
			_endPortLocation = '?',

			//render related vars
			_bzCtrlPtBaseValue = 200;

			if(typeof(_linkObj.style) == 'undefined') {
				_linkObj.style = [
					{'strokeStyle':'#25A3FC','lineWidth':3,'lineCap':'round'},
					{'strokeStyle':'#63E4FF','lineWidth':1,'lineCap':'round'}
				];
			}

		return {
			init: function() {
				_startPortDef = _viewSpace.getPortDefById('port-'+_portId,true);
				_endPortDef = _viewSpace.getPortDefById('port-'+_linkObj.other_end_id,true);

				if(_startPortDef == null || _endPortDef == null) {
					var that = this;
					var portsNotReadyCallback = function() {
						that.init();
					}
					setTimeout(portsNotReadyCallback,50);
					return;
				}

				_startPortLocation = _startPortDef.location;
				_endPortLocation = _endPortDef.location;

				_linkDef = {
					'id': _id,
					'type': 'fullBezier',
					'startItem': {
						'parentItemId': _itemId,
						'location': _startPortDef.location,
						'nodeId': _startNodeId
					},
					'endItems': [{
						'parentItemId': _endPortDef.parentItemId,
						'location': _endPortDef.location,
						'nodeId': _endNodeId
					}],
					'style':_linkObj.style
				};
				_startNode = R8.Utils.Y.one('#'+_startNodeId);
				_endNode = R8.Utils.Y.one('#'+_endNodeId);

				_viewSpace.addLinkToItems(_linkDef);
				_readyState = true;
			},
			isTypeOf: function(typeStr) {
				if(_viewSpace.items(_linkDef.startItem.parentItemId).get('type') == typeStr ||
				_viewSpace.items(_linkDef.endItems[0].parentItemId).get('type') == typeStr) {
					return true;
				}
				return false;
			},
			render: function() {
				if (_readyState == false) {
					var that = this;
					var notReadyCallback = function(){
						that.render();
					}
					setTimeout(notReadyCallback, 50);
					return;
				}


				if(this.isTypeOf('monitor')) var linkType = 'monitor';
				else var linkType = _linkDef.type;

				switch(linkType) {
					case "fullBezier":
						this.setFullBezierDef();
						R8.Canvas.drawFullBezier(_fullBezierDef);
//						R8.Canvas.renderLink(_linkDef);
						break;
					case "monitor":
//						var startPortDef = this.getPortDefById(_linkDef.startItem.nodeId);
//						if(startPortDef.direction == "input") {
//							startPortDef = this.getPortDefById(_linkDef.endItems[0].nodeId);
//						}
						R8.Canvas.renderHanger(_linkDef,_endPortDef);
var monitorNode = R8.Utils.Y.one('#monitor-'+_linkDef.startItem.parentItemId);
var cloneNode = monitorNode.cloneNode(true);
cloneNode.set('id','link-'+_id+'-hangerPort');

var temp = _endNode.getStyle('left');
var pLeft = temp.replace('px','');
var cLeft = (pLeft-(20+40))+'px';
temp = _endNode.getStyle('top');
var pTop = temp.replace('px','');
var cTop = (pTop-14)+'px';
cloneNode.setStyles({'top': cTop,'left': cLeft});
R8.Utils.Y.one('#item-'+_linkDef.endItems[0].parentItemId).append(cloneNode);
						break;
				}

				_startNode.removeClass('available');
				_startNode.addClass('connected');
				_endNode.removeClass('available');
				_endNode.addClass('connected');
			},
			get: function(key) {
				switch(key) {
					case "id":
						return _id;
						break;
					case "canvasNodeId":
						return _canvasNodeId;
						break;
					case "portId":
						return _portId;
						break;
					case "otherEndId":
						return _otherEndId;
						break;
					case "startParentItemId":
						return _linkDef.startItem.parentItemId;
						break;
					case "startNodeId":
						return _linkDef.startItem.nodeId;
						break;
					case "endParentItemId":
						return _linkDef.endItems[0].parentItemId;
						break;
					case "endNodeId":
						return _linkDef.endItems[0].nodeId;
						break;
				}
			},
			set: function(key,value) {
				switch(key) {
					case "startItemNodeId":
						_linkDef.startItem.nodeId = value;
						break;
					case "endItemNodeId":
						_linkDef.endItems[0].nodeId = value;
						break;
					case "startNode":
						_startNode = value;
						break;
					case "endNode":
						_endNode = value;
						break;
				}
			},

			hide: function() {
				
			},
			show: function() {
				
			},
			destroy: function() {
				var canvasNode = R8.Utils.Y.one('#'+_canvasNodeId);
				canvasNode.purge();
				canvasNode.remove();
				delete(canvasNode);

				_startNode.removeClass('connected');
				_startNode.addClass('available');
				_endNode.removeClass('connected');
				_endNode.addClass('available');
			},

//-------------------------------------------------------
//RENDERING RELATED UTILITIES
//-------------------------------------------------------
			setFullBezierDef: function() {
//TODO: revisit when making viewspaces more extensible, dont use viewspace for node id
				var vspaceXY = _viewSpace.get('node').getXY();

				var tempXY = _startNode.getXY();
				var startNodeXY = [(tempXY[0]-vspaceXY[0]),(tempXY[1]-vspaceXY[1])];
				var tempXY = _endNode.getXY();
				var endNodeXY = [(tempXY[0]-vspaceXY[0]),(tempXY[1]-vspaceXY[1])];

				//get offset for 1/2 start and end node height/widths
				var startNodeRegion = _startNode.get('region');
				var startNodeXOffset = Math.floor((startNodeRegion['right'] - startNodeRegion['left']) / 2);
				var startNodeYOffset = Math.floor((startNodeRegion['bottom'] - startNodeRegion['top']) / 2);

				var endNodeRegion = _endNode.get('region');
				var endNodeXOffset = Math.floor((endNodeRegion['right'] - endNodeRegion['left']) / 2);
				var endNodeYOffset = Math.floor((endNodeRegion['bottom'] - endNodeRegion['top']) / 2);

				//check to see the positioning of the source and target objects in relation to eachother
				var startQuadrant = UPPER_RIGHT; //UPPER_RIGHT == 0 == start is above & to right of end target
				if ((startNodeXY[0] <= endNodeXY[0]) && (startNodeXY[1] <= endNodeXY[1])) 
					var startQuadrant = UPPER_LEFT;
				else if ((startNodeXY[0] >= endNodeXY[0]) && (startNodeXY[1] <= endNodeXY[1])) 
					var startQuadrant = UPPER_RIGHT;
				else if ((startNodeXY[0] >= endNodeXY[0]) && (startNodeXY[1] >= endNodeXY[1])) 
					var startQuadrant = BOTTOM_RIGHT;
				else if ((startNodeXY[0] <= endNodeXY[0]) && (startNodeXY[1] >= endNodeXY[1])) 
					var startQuadrant = BOTTOM_LEFT;

				//StartNode is top left of EndNode
				if (startQuadrant == UPPER_LEFT) {
					var offsetRegion = endNodeRegion;
					var nodeWidthOffset = offsetRegion['right'] - offsetRegion['left'];
					var nodeHeightOffset = offsetRegion['bottom'] - offsetRegion['top'];

					//get height/width of the base canvas bounding box to surround startNode and endNodes
					var canvasBaseWidth = nodeWidthOffset + Math.sqrt(Math.pow((startNodeXY[0] - endNodeXY[0]), 2));
					var canvasBaseHeight = nodeHeightOffset + Math.sqrt(Math.pow((startNodeXY[1] - endNodeXY[1]), 2));

					//calculate bezier control point size here
					var canvasBaseDiagonal = Math.sqrt(Math.pow(canvasBaseHeight, 2) + Math.pow(canvasBaseWidth, 2));

					if((_startPortLocation == 'north' || _startPortLocation == 'south') && (_endPortLocation == 'north' || _endPortLocation == 'south')) {
						if (canvasBaseDiagonal > _bzCtrlPtBaseValue) {
							var ctrlYPtOffset = _bzCtrlPtBaseValue;
							var ctrlXPtOffset = _bzCtrlPtBaseValue;
						}
						else {
							var ctrlYPtOffset = canvasBaseDiagonal / 2;
							var ctrlXPtOffset = ctrlYPtOffset;
						}
					} else if((_startPortLocation == 'west' || _startPortLocation == 'east') && (_endPortLocation == 'west' || _endPortLocation == 'east')) {
						if (canvasBaseDiagonal > _bzCtrlPtBaseValue) {
							var ctrlYPtOffset = _bzCtrlPtBaseValue;
							var ctrlXPtOffset = _bzCtrlPtBaseValue;
						}
						else {
							var ctrlYPtOffset = canvasBaseDiagonal / 2;
							var ctrlXPtOffset = ctrlYPtOffset;
						}
					} else {
						if (canvasBaseWidth > _bzCtrlPtBaseValue) var ctrlXPtOffset = _bzCtrlPtBaseValue;
						else var ctrlXPtOffset = canvasBaseWidth;
	
						if (canvasBaseHeight > _bzCtrlPtBaseValue) var ctrlYPtOffset = _bzCtrlPtBaseValue;
						else var ctrlYPtOffset = canvasBaseHeight;
					}

					switch(_startPortLocation) {
						case 'south':
							if(_endPortLocation =='east')
								var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
							else
								var canvasActualWidth = canvasBaseWidth;

							if(_endPortLocation != 'north')
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
							else
								var canvasActualHeight = canvasBaseHeight + (2*ctrlYPtOffset);

							var startX = startNodeXOffset;
							var cpX1 = startX;
							var canvasLeft = startNodeXY[0];
							if(_endPortLocation == 'south') {
								var canvasTop = startNodeXY[1];
								var startY = startNodeYOffset;
								var cpY1 = startNodeYOffset + ctrlYPtOffset;
							} else {
								var canvasTop = startNodeXY[1] - ctrlYPtOffset;
								var startY = startNodeYOffset + ctrlYPtOffset;
								var cpY1 = startNodeYOffset + (2 * ctrlYPtOffset);
							}

							break;
						case 'north':
							var startX = startNodeXOffset;
							var cpX1 = startX;
							var canvasLeft = startNodeXY[0];

							if(_endPortLocation == 'south') var canvasActualHeight = canvasBaseHeight + (2*ctrlYPtOffset);
							else var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;

							if(_endPortLocation == 'east')
								var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
							else var canvasActualWidth = canvasBaseWidth;

							var canvasTop = startNodeXY[1] - ctrlYPtOffset;
							if(_endPortLocation != 'south') {
								var startY = startNodeYOffset + ctrlYPtOffset;
								var cpY1 = startY - ctrlYPtOffset;
							} else {
								var startY = startNodeYOffset + ctrlYPtOffset;
								var cpY1 = startY - (2*ctrlYPtOffset);
							}
							break;
						case 'west':
							if(_endPortLocation == 'east') var canvasActualWidth = canvasBaseWidth + (2*ctrlXPtOffset);
							else var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;

							if (_endPortLocation != 'east') {
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
							} else {
								var canvasActualHeight = canvasBaseHeight + (2 * ctrlYPtOffset);
							}
							var canvasTop = startNodeXY[1] - ctrlYPtOffset;
							var startY = startNodeYOffset + ctrlYPtOffset;
							var cpY1 = startY;

							if (_endPortLocation != 'east') {
								var canvasLeft = startNodeXY[0] - ctrlXPtOffset;
								var startX = startNodeXOffset + ctrlXPtOffset;
								var cpX1 = startX - ctrlXPtOffset;
							}
							else {
								var canvasLeft = startNodeXY[0] - ctrlXPtOffset;
								var startX = startNodeXOffset + ctrlXPtOffset;
								var cpX1 = startX - ctrlXPtOffset;
							}
							break;
						case 'east':
							var startY = startNodeYOffset;
							var cpY1 = startY;
							var canvasTop = startNodeXY[1];

							if(_endPortLocation == 'east')
								var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
							else var canvasActualWidth = canvasBaseWidth;

							if(_endPortLocation == 'south')
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
							else var canvasActualHeight = canvasBaseHeight;

							if(_endPortLocation != 'west') {
								var canvasLeft = startNodeXY[0];
								var startX = startNodeXOffset;
								var cpX1 = startX + ctrlXPtOffset;
							} else {
								var canvasLeft = startNodeXY[0];
								var startX = startNodeXOffset;
								var cpX1 = startX + ctrlXPtOffset;
							}
							break;
					}

					switch(_endPortLocation) {
						case 'south':
							var endX = canvasActualWidth - endNodeXOffset;
							var endY = canvasActualHeight - (ctrlYPtOffset + endNodeYOffset);

							var cpX2 = endX;
							var cpY2 = endY + ctrlYPtOffset;
							break;
						case 'north':
							var endX = canvasActualWidth - endNodeXOffset;
							var cpX2 = endX;
							if(_startPortLocation == 'south') {
								var endY = canvasActualHeight - (ctrlYPtOffset + endNodeYOffset);
								var cpY2 = endY - ctrlYPtOffset;
							} else {
								var endY = canvasActualHeight - endNodeYOffset;
								var cpY2 = endY - ctrlYPtOffset;
							}
							break;
						case 'west':
							if (_startPortLocation != 'east') {
								var endX = canvasActualWidth - endNodeXOffset;
								var cpX2 = endX - ctrlXPtOffset;
							} else {
								var endX = canvasActualWidth - endNodeXOffset;
								var cpX2 = endX - ctrlXPtOffset;
							}
							var endY = canvasActualHeight - endNodeYOffset;
							var cpY2 = endY;
							break;
						case 'east':
							var endX = canvasActualWidth - (ctrlXPtOffset + endNodeXOffset);
							var cpX2 = endX + ctrlXPtOffset;
							if(_startPortLocation != 'west')
								var endY = canvasActualHeight - endNodeYOffset;
							else var endY = canvasActualHeight - (ctrlYPtOffset + endNodeYOffset);
							var cpY2 = endY;
							break;
					}
				}
				//StartNode is bottom left of EndNode
				else if (startQuadrant == BOTTOM_LEFT) {
					var offsetRegion = endNodeRegion;
					var nodeWidthOffset = offsetRegion['right'] - offsetRegion['left'];
					var nodeHeightOffset = offsetRegion['bottom'] - offsetRegion['top'];

					//get height/width of the base canvas bounding box to surround startNode and endNodes
					var canvasBaseWidth = nodeWidthOffset + Math.sqrt(Math.pow((startNodeXY[0] - endNodeXY[0]), 2));
					var canvasBaseHeight = nodeHeightOffset + Math.sqrt(Math.pow((startNodeXY[1] - endNodeXY[1]), 2));

					//calculate bezier control point size here
					var canvasBaseDiagonal = Math.sqrt(Math.pow(canvasBaseHeight, 2) + Math.pow(canvasBaseWidth, 2));

					if((_startPortLocation == 'north' || _startPortLocation == 'south') && (_endPortLocation == 'north' || _endPortLocation == 'south')) {
						if (canvasBaseDiagonal > _bzCtrlPtBaseValue) {
							var ctrlYPtOffset = _bzCtrlPtBaseValue;
							var ctrlXPtOffset = _bzCtrlPtBaseValue;
						}
						else {
							var ctrlYPtOffset = canvasBaseDiagonal / 2;
							var ctrlXPtOffset = ctrlYPtOffset;
						}
					} else if((_startPortLocation == 'west' || _startPortLocation == 'east') && (_endPortLocation == 'west' || _endPortLocation == 'east')) {
						if (canvasBaseDiagonal > _bzCtrlPtBaseValue) {
							var ctrlYPtOffset = _bzCtrlPtBaseValue;
							var ctrlXPtOffset = _bzCtrlPtBaseValue;
						}
						else {
							var ctrlYPtOffset = canvasBaseDiagonal / 2;
							var ctrlXPtOffset = ctrlYPtOffset;
						}
					} else {
						if (canvasBaseWidth > _bzCtrlPtBaseValue) var ctrlXPtOffset = _bzCtrlPtBaseValue;
						else var ctrlXPtOffset = canvasBaseWidth;
	
						if (canvasBaseHeight > _bzCtrlPtBaseValue) var ctrlYPtOffset = _bzCtrlPtBaseValue;
						else var ctrlYPtOffset = canvasBaseHeight;
					}

					switch(_startPortLocation) {
						case 'south':
							if(_endPortLocation =='east')
								var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
							else
								var canvasActualWidth = canvasBaseWidth;

							if(_endPortLocation == 'south')
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
							else if(_endPortLocation == 'north')
								var canvasActualHeight = canvasBaseHeight + (2*ctrlYPtOffset);
							else
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;

							var startX = startNodeXOffset;
							var cpX1 = startX;
							var canvasLeft = startNodeXY[0];
							if(_endPortLocation != 'north') {
								var canvasTop = endNodeXY[1];
								var startY = canvasActualHeight - (ctrlYPtOffset + startNodeYOffset);
								var cpY1 = startY + ctrlYPtOffset;
							} else {
								var canvasTop = endNodeXY[1] - ctrlYPtOffset;
								var startY = canvasActualHeight - (endNodeYOffset + ctrlYPtOffset);
								var cpY1 = startY + ctrlYPtOffset;
							}
							break;
						case 'north':
							var startX = startNodeXOffset;
							var cpX1 = startX;
							var canvasLeft = startNodeXY[0];

							if(_endPortLocation == 'east')
								var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
							else var canvasActualWidth = canvasBaseWidth;

							if (_endPortLocation == 'north') {
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
								var canvasTop = endNodeXY[1] - ctrlYPtOffset;
								var startY = canvasActualHeight - startNodeYOffset;
								var cpY1 = startY - ctrlYPtOffset;
							} else if(_endPortLocation == 'south') {
								var canvasTop = endNodeXY[1] - ctrlYPtOffset;
								var canvasActualHeight = canvasBaseHeight + (2*ctrlYPtOffset);
								var startY = canvasActualHeight - (ctrlYPtOffset + startNodeYOffset);
								var cpY1 = startY - ctrlYPtOffset;
							} else {
								var canvasActualHeight = canvasBaseHeight;
								var canvasTop = endNodeXY[1];
								var startY = canvasActualHeight - startNodeYOffset;
								var cpY1 = startY - ctrlYPtOffset;
							}
							break;
						case 'west':
							if(_endPortLocation == 'east') var canvasActualWidth = canvasBaseWidth + (2*ctrlXPtOffset);
							else var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;

							if (_endPortLocation == 'south' || _endPortLocation == 'north') {
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
								var canvasTop = endNodeXY[1] - ctrlYPtOffset;
							} else {
								var canvasActualHeight = canvasBaseHeight;
								var canvasTop = endNodeXY[1];
							}

							var startY = canvasActualHeight - startNodeYOffset;
							var cpY1 = startY;

							if (_endPortLocation != 'east') {
								var canvasLeft = startNodeXY[0] - ctrlXPtOffset;
								var startX = startNodeXOffset + ctrlXPtOffset;
								var cpX1 = startX - ctrlXPtOffset;
							}
							else {
								var canvasLeft = startNodeXY[0] - ctrlXPtOffset;
								var startX = startNodeXOffset + ctrlXPtOffset;
								var cpX1 = startX - ctrlXPtOffset;
							}
							break;
						case 'east':

							if(_endPortLocation == 'west')
								var canvasActualWidth = canvasBaseWidth + (2*ctrlXPtOffset);
							else if(_endPortLocation == 'east')
								var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
							else var canvasActualWidth = canvasBaseWidth;

							if(_endPortLocation == 'north') {
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
								var canvasTop = endNodeXY[1] - ctrlYPtOffset;
								var startY = canvasActualHeight - startNodeYOffset;
								var cpY1 = startY - ctrlYPtOffset;
							} else {
								var canvasActualHeight = canvasBaseHeight;
								var canvasTop = endNodeXY[1];
								var startY = canvasActualHeight - startNodeYOffset;
								var cpY1 = startY;
							}

							if(_endPortLocation != 'west') {
								var canvasLeft = startNodeXY[0];
								var startX = startNodeXOffset;
								var cpX1 = startX + ctrlXPtOffset;
							} else {
								var canvasLeft = startNodeXY[0] - ctrlXPtOffset;
								var startX = ctrlXPtOffset + startNodeXOffset;
								var cpX1 = startX + ctrlXPtOffset;
							}
							break;
					}

					switch(_endPortLocation) {
						case 'south':
							var endX = canvasActualWidth - endNodeXOffset;
							var cpX2 = endX;

							if(_startPortLocation == 'north') {
								var endY = ctrlYPtOffset + endNodeYOffset;
								var cpY2 = endY + ctrlYPtOffset;
							} else {
								var endY = endNodeYOffset;
								var cpY2 = endY + ctrlYPtOffset;
							}
							break;
						case 'north':
							var endX = canvasActualWidth - endNodeXOffset;
							var cpX2 = endX;
							var endY = (ctrlYPtOffset + endNodeYOffset);
							var cpY2 = endY - ctrlYPtOffset;
							break;
						case 'west':
							if (_startPortLocation != 'east') {
								var endX = canvasActualWidth - endNodeXOffset;
								var cpX2 = endX - ctrlXPtOffset;
								var endY = endNodeYOffset;
								var cpY2 = endY;
							} else {
								var endX = canvasActualWidth - (ctrlXPtOffset + endNodeXOffset);
								var cpX2 = endX - ctrlXPtOffset;
								var endY = endNodeYOffset;
								var cpY2 = endY;
							}
							break;
						case 'east':
							var endX = canvasActualWidth - (ctrlXPtOffset + endNodeXOffset);
							var cpX2 = endX + ctrlXPtOffset;
							var endY = endNodeYOffset;
							var cpY2 = endY;
							break;
					}
				}
				//StartNode is top right of EndNode
				else if (startQuadrant == UPPER_RIGHT) {
					var offsetRegion = startNodeRegion;
					var nodeWidthOffset = offsetRegion['right'] - offsetRegion['left'];
					var nodeHeightOffset = offsetRegion['bottom'] - offsetRegion['top'];

					//get height/width of the base canvas bounding box to surround startNode and endNodes
					var canvasBaseWidth = nodeWidthOffset + Math.sqrt(Math.pow((startNodeXY[0] - endNodeXY[0]), 2));
					var canvasBaseHeight = nodeHeightOffset + Math.sqrt(Math.pow((startNodeXY[1] - endNodeXY[1]), 2));

					//calculate bezier control point size here
					var canvasBaseDiagonal = Math.sqrt(Math.pow(canvasBaseHeight, 2) + Math.pow(canvasBaseWidth, 2));

					if((_startPortLocation == 'north' || _startPortLocation == 'south') && (_endPortLocation == 'north' || _endPortLocation == 'south')) {
						if (canvasBaseDiagonal > _bzCtrlPtBaseValue) {
							var ctrlYPtOffset = _bzCtrlPtBaseValue;
							var ctrlXPtOffset = _bzCtrlPtBaseValue;
						}
						else {
							var ctrlYPtOffset = canvasBaseDiagonal / 2;
							var ctrlXPtOffset = ctrlYPtOffset;
						}
					} else if((_startPortLocation == 'west' || _startPortLocation == 'east') && (_endPortLocation == 'west' || _endPortLocation == 'east')) {
						if (canvasBaseDiagonal > _bzCtrlPtBaseValue) {
							var ctrlYPtOffset = _bzCtrlPtBaseValue;
							var ctrlXPtOffset = _bzCtrlPtBaseValue;
						}
						else {
							var ctrlYPtOffset = canvasBaseDiagonal / 2;
							var ctrlXPtOffset = ctrlYPtOffset;
						}
					} else {
						if (canvasBaseWidth > _bzCtrlPtBaseValue) var ctrlXPtOffset = _bzCtrlPtBaseValue;
						else var ctrlXPtOffset = canvasBaseWidth;
	
						if (canvasBaseHeight > _bzCtrlPtBaseValue) var ctrlYPtOffset = _bzCtrlPtBaseValue;
						else var ctrlYPtOffset = canvasBaseHeight;
					}

					switch(_startPortLocation) {
						case 'south':
							if(_endPortLocation == 'west') {
								var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
								var canvasLeft = endNodeXY[0] - ctrlXPtOffset;
							} else {
								var canvasActualWidth = canvasBaseWidth;
								var canvasLeft = endNodeXY[0];
							}
							if(_endPortLocation == 'south')
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
							else if(_endPortLocation == 'north')
								var canvasActualHeight = canvasBaseHeight + (2*ctrlYPtOffset);
							else
								var canvasActualHeight = canvasBaseHeight;

							var startX = canvasActualWidth - endNodeXOffset;
							var cpX1 = startX;
							if(_endPortLocation != 'north') {
								var startY = endNodeYOffset;
								var canvasTop = startNodeXY[1];
							} else {
								var startY = endNodeYOffset + ctrlYPtOffset;
								var canvasTop = startNodeXY[1] - ctrlYPtOffset;
							}
							var cpY1 = startY + ctrlYPtOffset;
							break;
						case 'north':
							if(_endPortLocation == 'west') {
								var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
								var canvasLeft = endNodeXY[0] - ctrlXPtOffset;
							} else {
								var canvasActualWidth = canvasBaseWidth;
								var canvasLeft = endNodeXY[0];
							}
							var startX = canvasActualWidth - startNodeXOffset;
							var cpX1 = startX;

							if (_endPortLocation == 'north') {
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
							} else if(_endPortLocation == 'south') {
								var canvasActualHeight = canvasBaseHeight + (2*ctrlYPtOffset);
							} else {
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
							}
							var startY = startNodeYOffset + ctrlYPtOffset;
							var cpY1 = startY - ctrlYPtOffset;
							var canvasTop = startNodeXY[1] - ctrlYPtOffset;
							break;
						case 'west':
							if(_endPortLocation == 'east') {
								var canvasActualWidth = canvasBaseWidth + (2 * ctrlXPtOffset);
								var canvasLeft = endNodeXY[0] - ctrlXPtOffset;
								var startX = canvasActualWidth - (ctrlXPtOffset + endNodeXOffset);
							} else if (_endPortLocation == 'west') {
								var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
								var canvasLeft = endNodeXY[0] - ctrlXPtOffset;
								var startX = canvasActualWidth - endNodeXOffset;
							} else {
								var canvasActualWidth = canvasBaseWidth;
								var canvasLeft = endNodeXY[0];
								var startX = canvasActualWidth - endNodeXOffset;
							}
							var cpX1 = startX - ctrlXPtOffset;

							if(_endPortLocation == 'south') {
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
								var startY = endNodeYOffset;
								var cpY1 = startY;
								var canvasTop = startNodeXY[1];
							} else {
								var canvasActualHeight = canvasBaseHeight;
								var startY = startNodeYOffset;
								var cpY1 = startY;
								var canvasTop = startNodeXY[1];
							}
							break;
						case 'east':
							var startY = startNodeYOffset;
							var cpY1 = startY;
							var canvasTop = startNodeXY[1];

							if (_endPortLocation == 'west') {
								var canvasActualWidth = canvasBaseWidth + (2 * ctrlXPtOffset);
								var canvasLeft = endNodeXY[0] - ctrlXPtOffset;
							} else {
								var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
								var canvasLeft = endNodeXY[0];
							}
							var startX = canvasActualWidth - (ctrlXPtOffset + startNodeXOffset);
							var cpX1 = startX + ctrlXPtOffset;

							if(_endPortLocation == 'south')
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
							else var canvasActualHeight = canvasBaseHeight;

							break;
					}

					switch(_endPortLocation) {
						case 'south':
							var endX =  endNodeXOffset;
							var cpX2 = endX;

							var endY = canvasActualHeight - (ctrlYPtOffset + endNodeYOffset);
							var cpY2 = endY + ctrlYPtOffset;
							break;
						case 'north':
							var endX = endNodeXOffset;
							var cpX2 = endX;
							if(_startPortLocation == 'south') {
								var endY = canvasActualHeight - (ctrlYPtOffset + endNodeYOffset);
							} else {
								var endY = canvasActualHeight - endNodeYOffset;
							}

							var cpY2 = endY - ctrlYPtOffset;
							break;
						case 'west':
							var endX = ctrlXPtOffset + endNodeXOffset;
							var cpX2 = endX - ctrlXPtOffset;
							var endY = canvasActualHeight - endNodeYOffset;
							var cpY2 = endY;
							break;
						case 'east':
							if(_startPortLocation == 'west') {
								var endX = endNodeXOffset + ctrlXPtOffset;
							} else {
								var endX = endNodeXOffset;
							}
							var cpX2 = endX + ctrlXPtOffset;
							var endY = canvasActualHeight - endNodeYOffset;
							var cpY2 = endY;
							break;
					}
				}
				//StartNode is bottom right to EndNode
				else if (startQuadrant == BOTTOM_RIGHT) {
					var offsetRegion = startNodeRegion;
					var nodeWidthOffset = offsetRegion['right'] - offsetRegion['left'];
					var nodeHeightOffset = offsetRegion['bottom'] - offsetRegion['top'];

					//get height/width of the base canvas bounding box to surround startNode and endNodes
					var canvasBaseWidth = nodeWidthOffset + Math.sqrt(Math.pow((startNodeXY[0] - endNodeXY[0]), 2));
					var canvasBaseHeight = nodeHeightOffset + Math.sqrt(Math.pow((startNodeXY[1] - endNodeXY[1]), 2));

					//calculate bezier control point size here
					var canvasBaseDiagonal = Math.sqrt(Math.pow(canvasBaseHeight, 2) + Math.pow(canvasBaseWidth, 2));

					if((_startPortLocation == 'north' || _startPortLocation == 'south') && (_endPortLocation == 'north' || _endPortLocation == 'south')) {
						if (canvasBaseDiagonal > _bzCtrlPtBaseValue) {
							var ctrlYPtOffset = _bzCtrlPtBaseValue;
							var ctrlXPtOffset = _bzCtrlPtBaseValue;
						}
						else {
							var ctrlYPtOffset = canvasBaseDiagonal / 2;
							var ctrlXPtOffset = ctrlYPtOffset;
						}
					} else if((_startPortLocation == 'west' || _startPortLocation == 'east') && (_endPortLocation == 'west' || _endPortLocation == 'east')) {
						if (canvasBaseDiagonal > _bzCtrlPtBaseValue) {
							var ctrlYPtOffset = _bzCtrlPtBaseValue;
							var ctrlXPtOffset = _bzCtrlPtBaseValue;
						}
						else {
							var ctrlYPtOffset = canvasBaseDiagonal / 2;
							var ctrlXPtOffset = ctrlYPtOffset;
						}
					} else {
						if (canvasBaseWidth > _bzCtrlPtBaseValue) var ctrlXPtOffset = _bzCtrlPtBaseValue;
						else var ctrlXPtOffset = canvasBaseWidth;
	
						if (canvasBaseHeight > _bzCtrlPtBaseValue) var ctrlYPtOffset = _bzCtrlPtBaseValue;
						else var ctrlYPtOffset = canvasBaseHeight;
					}

					switch(_startPortLocation) {
						case 'south':
							if(_endPortLocation == 'west') {
								var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
								var canvasLeft = endNodeXY[0] - ctrlXPtOffset;
							} else {
								var canvasActualWidth = canvasBaseWidth;
								var canvasLeft = endNodeXY[0];
							}
							if(_endPortLocation == 'north')
								var canvasActualHeight = canvasBaseHeight + (2*ctrlYPtOffset);
							else
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;

							var startX = canvasActualWidth - endNodeXOffset;
							var cpX1 = startX;
							if(_endPortLocation != 'north') {
								var canvasTop = endNodeXY[1];
							} else {
								var canvasTop = endNodeXY[1] - ctrlYPtOffset;
							}
							var startY = canvasActualHeight - (startNodeYOffset + ctrlYPtOffset);
							var cpY1 = startY + ctrlYPtOffset;
							break;
						case 'north':
							if(_endPortLocation == 'west') {
								var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
								var canvasLeft = endNodeXY[0] - ctrlXPtOffset;
							} else {
								var canvasActualWidth = canvasBaseWidth;
								var canvasLeft = endNodeXY[0];
							}
							var startX = canvasActualWidth - startNodeXOffset;
							var cpX1 = startX;

							if (_endPortLocation == 'north') {
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
								var startY = canvasActualHeight - startNodeYOffset;
								var canvasTop = endNodeXY[1] - ctrlYPtOffset;
							} else if(_endPortLocation == 'south') {
								var canvasActualHeight = canvasBaseHeight + (2*ctrlYPtOffset);
								var startY = canvasActualHeight - (ctrlYPtOffset + startNodeYOffset);
								var canvasTop = endNodeXY[1] - ctrlYPtOffset;
							} else {
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
								var startY = canvasActualHeight - startNodeYOffset;
								var canvasTop = endNodeXY[1] - ctrlYPtOffset;
							}
							var cpY1 = startY - ctrlYPtOffset;
							break;
						case 'west':
							if(_endPortLocation == 'east') {
								var canvasActualWidth = canvasBaseWidth + (2 * ctrlXPtOffset);
								var canvasLeft = endNodeXY[0] - ctrlXPtOffset;
								var startX = canvasActualWidth - (ctrlXPtOffset + endNodeXOffset);
							} else if (_endPortLocation == 'west') {
								var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
								var canvasLeft = endNodeXY[0] - ctrlXPtOffset;
								var startX = canvasActualWidth - endNodeXOffset;
							} else {
								var canvasActualWidth = canvasBaseWidth;
								var canvasLeft = endNodeXY[0];
								var startX = canvasActualWidth - endNodeXOffset;
							}
							var cpX1 = startX - ctrlXPtOffset;

							if(_endPortLocation == 'south') {
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
								var canvasTop = endNodeXY[1];
								var startY = canvasActualHeight - (ctrlYPtOffset + endNodeYOffset);
							} else if (_endPortLocation == 'north') {
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
								var canvasTop = endNodeXY[1] - ctrlYPtOffset;
								var startY = canvasActualHeight - endNodeYOffset;
							}
							else {
								var canvasActualHeight = canvasBaseHeight;
								var canvasTop = endNodeXY[1];								
								var startY = canvasActualHeight - endNodeYOffset;
							}
							var cpY1 = startY;
							break;
						case 'east':
							if(_endPortLocation == 'north') {
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
							} else {
								var canvasActualHeight = canvasBaseHeight;
							}
							var startY = canvasActualHeight - startNodeYOffset;
							var cpY1 = startY;

							if (_endPortLocation == 'west') {
								var canvasActualWidth = canvasBaseWidth + (2 * ctrlXPtOffset);
								var canvasLeft = endNodeXY[0] - ctrlXPtOffset;
								var canvasTop = endNodeXY[1];
							} else if(_endPortLocation == 'north'){
								var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
								var canvasLeft = endNodeXY[0];
								var canvasTop = endNodeXY[1] - ctrlYPtOffset;
							} else {
								var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
								var canvasLeft = endNodeXY[0];
								var canvasTop = endNodeXY[1];
							}
							var startX = canvasActualWidth - (ctrlXPtOffset + startNodeXOffset);
							var cpX1 = startX + ctrlXPtOffset;

							break;
					}

					switch(_endPortLocation) {
						case 'south':
							var endX =  endNodeXOffset;
							var cpX2 = endX;

							if (_startPortLocation != 'north') {
								var endY = endNodeYOffset;
								var cpY2 = endY + ctrlYPtOffset;
							} else {
								var endY = endNodeYOffset + ctrlYPtOffset;
								var cpY2 = endY + ctrlYPtOffset;
							}
							break;
						case 'north':
							var endX = endNodeXOffset;
							var cpX2 = endX;
							var endY = ctrlYPtOffset + endNodeYOffset;
							var cpY2 = endY - ctrlYPtOffset;
							break;
						case 'west':
							var endX = ctrlXPtOffset + endNodeXOffset;
							var cpX2 = endX - ctrlXPtOffset;
							if (_startPortLocation == 'north') {
								var endY = ctrlYPtOffset + endNodeYOffset;
							} else {
								var endY = endNodeYOffset;
							}
							var cpY2 = endY;
							break;
						case 'east':
							if(_startPortLocation == 'west') {
								var endX = endNodeXOffset + ctrlXPtOffset;
							} else {
								var endX = endNodeXOffset;
							}
							var cpX2 = endX + ctrlXPtOffset;
							if(_startPortLocation == 'north')
								var endY = ctrlYPtOffset + endNodeYOffset;
							else var endY = endNodeYOffset;
							var cpY2 = endY;
							break;
					}
				}

				_fullBezierDef = {
					'canvasNodeId': _canvasNodeId,
					'parentNode': _viewSpace.get('node'),
					'canvasTop': canvasTop,
					'canvasLeft': canvasLeft,
					'canvasWidth': canvasActualWidth,
					'canvasHeight': canvasActualHeight,
					'canvasClass': _fullBezierClass,
					'startX': startX,
					'startY': startY,
					'cpX1': cpX1,
					'cpY1': cpY1,
					'cpX2': cpX2,
					'cpY2': cpY2,
					'endX': endX,
					'endY': endY,
					'style': _linkDef.style
				};
			},
		}
	}
}
