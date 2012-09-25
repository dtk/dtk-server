

if(!R8.Link) {

	R8.Link = function(linkDef,target) {
		//defines for starting quadrant for connector rendering in relation to end point
		var UPPER_LEFT = 3;
		var UPPER_RIGHT = 0;
		var BOTTOM_RIGHT = 1;
		var BOTTOM_LEFT = 2;

//TODO: cleanup linkObj, linkDef, still a mish mosh from old days like ports
		var _def = linkDef,
			_initialized = false,
			_target = target,

			_idPrefix = 'link-',
			_canvasNodeId = _idPrefix+_def.id,

			_fullBezierClass = ['link','full-bezier'],
			_fullBezierDef = null,
			_halfBezierDef = null,
			_hangerDef = null,

//			_portId = _def.start_id,
//			_itemId = _def.item_id,

//			_startNode = null,
//			_startNodeId = 'port-'+_portId,
			_inputPort = _target.get('port',_def.input_id),

//			_endNode = null,
//			_otherEndId = _def.end_id,
//			_endNodeId = 'port-'+_def.end_id,
			_outputPort = _target.get('port',_def.output_id),

			_proxyNode = null,
			_proxyId = _def.end_id,
			_proxyNodeId = 'port-'+_def.end_id,
			_proxyPortDef = null,
			_proxyPortLocation = '?',

			//render related vars
			_bzCtrlPtBaseValue = 100;
/*
			if(typeof(_def.ui.style) == 'undefined') {
				_def.ui.style = [
					{'strokeStyle':'#25A3FC','lineWidth':3,'lineCap':'round'},
					{'strokeStyle':'#000000','lineWidth':1,'lineCap':'round'}
//					{'strokeStyle':'#63E4FF','lineWidth':1,'lineCap':'round'}
				];
			}
			_monitorDefaultStyle = [
					{'strokeStyle':'#5BF300','lineWidth':3,'lineCap':'round'},
					{'strokeStyle':'#25A3FC','lineWidth':1,'lineCap':'round'}
			];
*/
		return {
			init: function() {
//				_inputPort = _viewSpace.getPortDefById('port-'+_portId,true);
//				_outputPort = _viewSpace.getPortDefById('port-'+_linkObj.other_end_id,true);

//				_inputPort = _target.get('port',this.get('startPortId'));
//				_outputPort = _target.get('port',this.get('endPortId'));


				if(_inputPort == null || _outputPort == null) {
					var _this = this;
					var portsNotReadyCallback = function() {
						_this.init();
					}
					setTimeout(portsNotReadyCallback,50);
					return;
				}

/*
				_linkDef = {
					'id': _id,
					'type': 'fullBezier',
					'startItem': {
						'parentItemId': _itemId,
						'location': _inputPort.get('location'),
						'nodeId': _startNodeId
					},
					'endItems': [{
						'parentItemId': _outputPort.get('node').get('id'),
						'location': _outputPort.get('location'),
						'nodeId': _endNodeId
					}],
					'style':_linkObj.style
				};
*/
//TODO: revisit after fully implementing link types and new meta
				if (this.isTypeOf('monitor')) {
					_linkDef.type = 'monitor';
					_linkDef.style = _monitorDefaultStyle;
				}

//				_startNode = R8.Utils.Y.one('#'+_startNodeId);
//				_endNode = R8.Utils.Y.one('#'+_endNodeId);

//				_viewSpace.addLinkToItems(_linkDef);
				_target.addLinkToItems(this);
				_initialized = true;
			},
			isTypeOf: function(typeStr) {
//TODO: revisit when turning back on monitor types
return false;
				if(_viewSpace.items(_linkDef.startItem.parentItemId).get('type') == typeStr ||
				_viewSpace.items(_linkDef.endItems[0].parentItemId).get('type') == typeStr) {
					return true;
				}
				return false;
			},
			render: function() {
				if (_initialized == false) {
					var _this = this;
					var notReadyCallback = function(){
						_this.render();
					}
					setTimeout(notReadyCallback, 50);
					return;
				}

				switch(this.get('type')) {
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
						R8.Canvas.renderHanger(_linkDef,_outputPort);

						var proxyNode = R8.Utils.Y.one('#port-proxy-'+_outputPort.id);
						if (proxyNode == null) {
							var portNodeID = 'port-proxy-' + _outputPort.id,
								portClass = 'monitor-port available',
								proxyNode = new R8.Utils.Y.Node.create('<div>');
						
							proxyNode.addClass(portClass);
						
							var temp = _endNode.getStyle('left');
							var pLeft = temp.replace('px', '');
						//	var cLeft = (pLeft - 39) + 'px';
							var cLeft = (pLeft - 25) + 'px';
							temp = _endNode.getStyle('top');
							var pTop = temp.replace('px', '');
							var cTop = (pTop-6) + 'px';
						//	var cTop = (parseInt(pTop)+1) + 'px';
							proxyNode.setStyles({
								'top': cTop,
								'left': cLeft
							});
						
							R8.Utils.Y.one('#item-' + _linkDef.endItems[0].parentItemId).append(proxyNode);

							proxyNode.on('mouseenter',function(e){
								R8.Canvas.renderLine(_linkDef,_outputPort);
							},this);
							proxyNode.on('mouseleave',function(e){
						console.log('left proxy node.., should delete temp link');
							},this);
						}
/*
var monitorNode = R8.Utils.Y.one('#link-'+_id+'-hangerPort');
if (monitorNode == null) {
	monitorNode = R8.Utils.Y.one('#monitor-' + _linkDef.startItem.parentItemId);
	var cloneNode = monitorNode.cloneNode(true);
	cloneNode.set('id', 'link-' + _id + '-hangerPort');
	
	var temp = _endNode.getStyle('left');
	var pLeft = temp.replace('px', '');
	var cLeft = (pLeft - (20 + 40)) + 'px';
	temp = _endNode.getStyle('top');
	var pTop = temp.replace('px', '');
	var cTop = (pTop - 14) + 'px';
	cloneNode.setStyles({
		'top': cTop,
		'left': cLeft
	});
	R8.Utils.Y.one('#item-' + _linkDef.endItems[0].parentItemId).append(cloneNode);
}
*/
						break;
				}
/*
				_startNode.removeClass('available');
				_startNode.addClass('connected');
				_endNode.removeClass('available');
				_endNode.addClass('connected');
*/
				_inputPort.getView('editor_target').get('node').removeClass('available');
				_inputPort.getView('editor_target').get('node').addClass('connected');
				_outputPort.getView('editor_target').get('node').removeClass('available');
				_outputPort.getView('editor_target').get('node').addClass('connected');
			},
			get: function(key,value) {
				switch(key) {
					case "id":
						return _def.id;
						break;
					case "def":
						return _def;
						break;
					case "type":
						return _def.ui.type;
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
//DEBUG
return foopa;
						return _linkDef.endItems[0].nodeId;
						break;
					case "inputPort":
						return _inputPort;
						break;
					case "startPortId":
//DEBUG
return foopa;
						return _def.start_id;
						break;
					case "outputPort":
						return _outputPort;
						break;
					case "EndPortId":
//DEBUG
return foopa;
						return _def.end_id;
						break;
					case "style":
//DEBUG
//console.log(_def.ui.style);
						return _def.ui.style;
						break;
					case "view":
						if(typeof(_views[value]) == 'undefined') this.requireView(value);
		
						return _views[value];
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


				_inputPort.getView('editor_target').get('node').removeClass('connected');
				_inputPort.getView('editor_target').get('node').addClass('available');
				_outputPort.getView('editor_target').get('node').removeClass('connected');
				_outputPort.getView('editor_target').get('node').addClass('available');
			},

//-------------------------------------------------------
//RENDERING RELATED UTILITIES
//-------------------------------------------------------
			setFullBezierDef: function() {
//TODO: revisit when making viewspaces more extensible, dont use viewspace for node id
				var vspaceXY = _target.get('view','editor').get('node').getXY();
				var tempXY = _inputPort.get('view','editor_target').get('node').getXY();
				var startNodeXY = [(tempXY[0]-vspaceXY[0]),(tempXY[1]-vspaceXY[1])];
				var tempXY = _outputPort.get('view','editor_target').get('node').getXY();
				var endNodeXY = [(tempXY[0]-vspaceXY[0]),(tempXY[1]-vspaceXY[1])];
				//get offset for 1/2 start and end node height/widths
				var startNodeRegion = _inputPort.get('view','editor_target').get('node').get('region');
				var startNodeXOffset = Math.floor((startNodeRegion['right'] - startNodeRegion['left']) / 2);
				var startNodeYOffset = Math.floor((startNodeRegion['bottom'] - startNodeRegion['top']) / 2);

				var endNodeRegion = _outputPort.get('view','editor_target').get('node').get('region');
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

					if((_inputPort.get('location') == 'north' || _inputPort.get('location') == 'south') && (_outputPort.get('location') == 'north' || _outputPort.get('location') == 'south')) {
						if (canvasBaseDiagonal > _bzCtrlPtBaseValue) {
							var ctrlYPtOffset = _bzCtrlPtBaseValue;
							var ctrlXPtOffset = _bzCtrlPtBaseValue;
						}
						else {
							var ctrlYPtOffset = canvasBaseDiagonal / 2;
							var ctrlXPtOffset = ctrlYPtOffset;
						}
					} else if((_inputPort.get('location') == 'west' || _inputPort.get('location') == 'east') && (_outputPort.get('location') == 'west' || _outputPort.get('location') == 'east')) {
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

					switch(_inputPort.get('location')) {
						case 'south':
							if(_outputPort.get('location') =='east')
								var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
							else
								var canvasActualWidth = canvasBaseWidth;

							if(_outputPort.get('location') != 'north')
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
							else
								var canvasActualHeight = canvasBaseHeight + (2*ctrlYPtOffset);

							var startX = startNodeXOffset;
							var cpX1 = startX;
							var canvasLeft = startNodeXY[0];
							if(_outputPort.get('location') == 'south') {
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

							if(_outputPort.get('location') == 'south') var canvasActualHeight = canvasBaseHeight + (2*ctrlYPtOffset);
							else var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;

							if(_outputPort.get('location') == 'east')
								var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
							else var canvasActualWidth = canvasBaseWidth;

							var canvasTop = startNodeXY[1] - ctrlYPtOffset;
							if(_outputPort.get('location') != 'south') {
								var startY = startNodeYOffset + ctrlYPtOffset;
								var cpY1 = startY - ctrlYPtOffset;
							} else {
								var startY = startNodeYOffset + ctrlYPtOffset;
								var cpY1 = startY - (2*ctrlYPtOffset);
							}
							break;
						case 'west':
							if(_outputPort.get('location') == 'east') var canvasActualWidth = canvasBaseWidth + (2*ctrlXPtOffset);
							else var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;

							if (_outputPort.get('location') != 'east') {
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
							} else {
								var canvasActualHeight = canvasBaseHeight + (2 * ctrlYPtOffset);
							}
							var canvasTop = startNodeXY[1] - ctrlYPtOffset;
							var startY = startNodeYOffset + ctrlYPtOffset;
							var cpY1 = startY;

							if (_outputPort.get('location') != 'east') {
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

							if(_outputPort.get('location') == 'east')
								var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
							else var canvasActualWidth = canvasBaseWidth;

							if(_outputPort.get('location') == 'south')
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
							else var canvasActualHeight = canvasBaseHeight;

							if(_outputPort.get('location') != 'west') {
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

					switch(_outputPort.get('location')) {
						case 'south':
							var endX = canvasActualWidth - endNodeXOffset;
							var endY = canvasActualHeight - (ctrlYPtOffset + endNodeYOffset);

							var cpX2 = endX;
							var cpY2 = endY + ctrlYPtOffset;
							break;
						case 'north':
							var endX = canvasActualWidth - endNodeXOffset;
							var cpX2 = endX;
							if(_inputPort.get('location') == 'south') {
								var endY = canvasActualHeight - (ctrlYPtOffset + endNodeYOffset);
								var cpY2 = endY - ctrlYPtOffset;
							} else {
								var endY = canvasActualHeight - endNodeYOffset;
								var cpY2 = endY - ctrlYPtOffset;
							}
							break;
						case 'west':
							if (_inputPort.get('location') != 'east') {
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
							if(_inputPort.get('location') != 'west')
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

					if((_inputPort.get('location') == 'north' || _inputPort.get('location') == 'south') && (_outputPort.get('location') == 'north' || _outputPort.get('location') == 'south')) {
						if (canvasBaseDiagonal > _bzCtrlPtBaseValue) {
							var ctrlYPtOffset = _bzCtrlPtBaseValue;
							var ctrlXPtOffset = _bzCtrlPtBaseValue;
						}
						else {
							var ctrlYPtOffset = canvasBaseDiagonal / 2;
							var ctrlXPtOffset = ctrlYPtOffset;
						}
					} else if((_inputPort.get('location') == 'west' || _inputPort.get('location') == 'east') && (_outputPort.get('location') == 'west' || _outputPort.get('location') == 'east')) {
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

					switch(_inputPort.get('location')) {
						case 'south':
							if(_outputPort.get('location') =='east')
								var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
							else
								var canvasActualWidth = canvasBaseWidth;

							if(_outputPort.get('location') == 'south')
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
							else if(_outputPort.get('location') == 'north')
								var canvasActualHeight = canvasBaseHeight + (2*ctrlYPtOffset);
							else
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;

							var startX = startNodeXOffset;
							var cpX1 = startX;
							var canvasLeft = startNodeXY[0];
							if(_outputPort.get('location') != 'north') {
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

							if(_outputPort.get('location') == 'east')
								var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
							else var canvasActualWidth = canvasBaseWidth;

							if (_outputPort.get('location') == 'north') {
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
								var canvasTop = endNodeXY[1] - ctrlYPtOffset;
								var startY = canvasActualHeight - startNodeYOffset;
								var cpY1 = startY - ctrlYPtOffset;
							} else if(_outputPort.get('location') == 'south') {
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
							if(_outputPort.get('location') == 'east') var canvasActualWidth = canvasBaseWidth + (2*ctrlXPtOffset);
							else var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;

							if (_outputPort.get('location') == 'south' || _outputPort.get('location') == 'north') {
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
								var canvasTop = endNodeXY[1] - ctrlYPtOffset;
							} else {
								var canvasActualHeight = canvasBaseHeight;
								var canvasTop = endNodeXY[1];
							}

							var startY = canvasActualHeight - startNodeYOffset;
							var cpY1 = startY;

							if (_outputPort.get('location') != 'east') {
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

							if(_outputPort.get('location') == 'west')
								var canvasActualWidth = canvasBaseWidth + (2*ctrlXPtOffset);
							else if(_outputPort.get('location') == 'east')
								var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
							else var canvasActualWidth = canvasBaseWidth;

							if(_outputPort.get('location') == 'north') {
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

							if(_outputPort.get('location') != 'west') {
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

					switch(_outputPort.get('location')) {
						case 'south':
							var endX = canvasActualWidth - endNodeXOffset;
							var cpX2 = endX;

							if(_inputPort.get('location') == 'north') {
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
							if (_inputPort.get('location') != 'east') {
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

					if((_inputPort.get('location') == 'north' || _inputPort.get('location') == 'south') && (_outputPort.get('location') == 'north' || _outputPort.get('location') == 'south')) {
						if (canvasBaseDiagonal > _bzCtrlPtBaseValue) {
							var ctrlYPtOffset = _bzCtrlPtBaseValue;
							var ctrlXPtOffset = _bzCtrlPtBaseValue;
						}
						else {
							var ctrlYPtOffset = canvasBaseDiagonal / 2;
							var ctrlXPtOffset = ctrlYPtOffset;
						}
					} else if((_inputPort.get('location') == 'west' || _inputPort.get('location') == 'east') && (_outputPort.get('location') == 'west' || _outputPort.get('location') == 'east')) {
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

					switch(_inputPort.get('location')) {
						case 'south':
							if(_outputPort.get('location') == 'west') {
								var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
								var canvasLeft = endNodeXY[0] - ctrlXPtOffset;
							} else {
								var canvasActualWidth = canvasBaseWidth;
								var canvasLeft = endNodeXY[0];
							}
							if(_outputPort.get('location') == 'south')
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
							else if(_outputPort.get('location') == 'north')
								var canvasActualHeight = canvasBaseHeight + (2*ctrlYPtOffset);
							else
								var canvasActualHeight = canvasBaseHeight;

							var startX = canvasActualWidth - endNodeXOffset;
							var cpX1 = startX;
							if(_outputPort.get('location') != 'north') {
								var startY = endNodeYOffset;
								var canvasTop = startNodeXY[1];
							} else {
								var startY = endNodeYOffset + ctrlYPtOffset;
								var canvasTop = startNodeXY[1] - ctrlYPtOffset;
							}
							var cpY1 = startY + ctrlYPtOffset;
							break;
						case 'north':
							if(_outputPort.get('location') == 'west') {
								var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
								var canvasLeft = endNodeXY[0] - ctrlXPtOffset;
							} else {
								var canvasActualWidth = canvasBaseWidth;
								var canvasLeft = endNodeXY[0];
							}
							var startX = canvasActualWidth - startNodeXOffset;
							var cpX1 = startX;

							if (_outputPort.get('location') == 'north') {
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
							} else if(_outputPort.get('location') == 'south') {
								var canvasActualHeight = canvasBaseHeight + (2*ctrlYPtOffset);
							} else {
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
							}
							var startY = startNodeYOffset + ctrlYPtOffset;
							var cpY1 = startY - ctrlYPtOffset;
							var canvasTop = startNodeXY[1] - ctrlYPtOffset;
							break;
						case 'west':
							if(_outputPort.get('location') == 'east') {
								var canvasActualWidth = canvasBaseWidth + (2 * ctrlXPtOffset);
								var canvasLeft = endNodeXY[0] - ctrlXPtOffset;
								var startX = canvasActualWidth - (ctrlXPtOffset + endNodeXOffset);
							} else if (_outputPort.get('location') == 'west') {
								var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
								var canvasLeft = endNodeXY[0] - ctrlXPtOffset;
								var startX = canvasActualWidth - endNodeXOffset;
							} else {
								var canvasActualWidth = canvasBaseWidth;
								var canvasLeft = endNodeXY[0];
								var startX = canvasActualWidth - endNodeXOffset;
							}
							var cpX1 = startX - ctrlXPtOffset;

							if(_outputPort.get('location') == 'south') {
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

							if (_outputPort.get('location') == 'west') {
								var canvasActualWidth = canvasBaseWidth + (2 * ctrlXPtOffset);
								var canvasLeft = endNodeXY[0] - ctrlXPtOffset;
							} else {
								var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
								var canvasLeft = endNodeXY[0];
							}
							var startX = canvasActualWidth - (ctrlXPtOffset + startNodeXOffset);
							var cpX1 = startX + ctrlXPtOffset;

							if(_outputPort.get('location') == 'south')
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
							else var canvasActualHeight = canvasBaseHeight;

							break;
					}

					switch(_outputPort.get('location')) {
						case 'south':
							var endX =  endNodeXOffset;
							var cpX2 = endX;

							var endY = canvasActualHeight - (ctrlYPtOffset + endNodeYOffset);
							var cpY2 = endY + ctrlYPtOffset;
							break;
						case 'north':
							var endX = endNodeXOffset;
							var cpX2 = endX;
							if(_inputPort.get('location') == 'south') {
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
							if(_inputPort.get('location') == 'west') {
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

					if((_inputPort.get('location') == 'north' || _inputPort.get('location') == 'south') && (_outputPort.get('location') == 'north' || _outputPort.get('location') == 'south')) {
						if (canvasBaseDiagonal > _bzCtrlPtBaseValue) {
							var ctrlYPtOffset = _bzCtrlPtBaseValue;
							var ctrlXPtOffset = _bzCtrlPtBaseValue;
						}
						else {
							var ctrlYPtOffset = canvasBaseDiagonal / 2;
							var ctrlXPtOffset = ctrlYPtOffset;
						}
					} else if((_inputPort.get('location') == 'west' || _inputPort.get('location') == 'east') && (_outputPort.get('location') == 'west' || _outputPort.get('location') == 'east')) {
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

					switch(_inputPort.get('location')) {
						case 'south':
							if(_outputPort.get('location') == 'west') {
								var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
								var canvasLeft = endNodeXY[0] - ctrlXPtOffset;
							} else {
								var canvasActualWidth = canvasBaseWidth;
								var canvasLeft = endNodeXY[0];
							}
							if(_outputPort.get('location') == 'north')
								var canvasActualHeight = canvasBaseHeight + (2*ctrlYPtOffset);
							else
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;

							var startX = canvasActualWidth - endNodeXOffset;
							var cpX1 = startX;
							if(_outputPort.get('location') != 'north') {
								var canvasTop = endNodeXY[1];
							} else {
								var canvasTop = endNodeXY[1] - ctrlYPtOffset;
							}
							var startY = canvasActualHeight - (startNodeYOffset + ctrlYPtOffset);
							var cpY1 = startY + ctrlYPtOffset;
							break;
						case 'north':
							if(_outputPort.get('location') == 'west') {
								var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
								var canvasLeft = endNodeXY[0] - ctrlXPtOffset;
							} else {
								var canvasActualWidth = canvasBaseWidth;
								var canvasLeft = endNodeXY[0];
							}
							var startX = canvasActualWidth - startNodeXOffset;
							var cpX1 = startX;

							if (_outputPort.get('location') == 'north') {
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
								var startY = canvasActualHeight - startNodeYOffset;
								var canvasTop = endNodeXY[1] - ctrlYPtOffset;
							} else if(_outputPort.get('location') == 'south') {
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
							if(_outputPort.get('location') == 'east') {
								var canvasActualWidth = canvasBaseWidth + (2 * ctrlXPtOffset);
								var canvasLeft = endNodeXY[0] - ctrlXPtOffset;
								var startX = canvasActualWidth - (ctrlXPtOffset + endNodeXOffset);
							} else if (_outputPort.get('location') == 'west') {
								var canvasActualWidth = canvasBaseWidth + ctrlXPtOffset;
								var canvasLeft = endNodeXY[0] - ctrlXPtOffset;
								var startX = canvasActualWidth - endNodeXOffset;
							} else {
								var canvasActualWidth = canvasBaseWidth;
								var canvasLeft = endNodeXY[0];
								var startX = canvasActualWidth - endNodeXOffset;
							}
							var cpX1 = startX - ctrlXPtOffset;

							if(_outputPort.get('location') == 'south') {
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
								var canvasTop = endNodeXY[1];
								var startY = canvasActualHeight - (ctrlYPtOffset + endNodeYOffset);
							} else if (_outputPort.get('location') == 'north') {
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
							if(_outputPort.get('location') == 'north') {
								var canvasActualHeight = canvasBaseHeight + ctrlYPtOffset;
							} else {
								var canvasActualHeight = canvasBaseHeight;
							}
							var startY = canvasActualHeight - startNodeYOffset;
							var cpY1 = startY;

							if (_outputPort.get('location') == 'west') {
								var canvasActualWidth = canvasBaseWidth + (2 * ctrlXPtOffset);
								var canvasLeft = endNodeXY[0] - ctrlXPtOffset;
								var canvasTop = endNodeXY[1];
							} else if(_outputPort.get('location') == 'north'){
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

					switch(_outputPort.get('location')) {
						case 'south':
							var endX =  endNodeXOffset;
							var cpX2 = endX;

							if (_inputPort.get('location') != 'north') {
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
							if (_inputPort.get('location') == 'north') {
								var endY = ctrlYPtOffset + endNodeYOffset;
							} else {
								var endY = endNodeYOffset;
							}
							var cpY2 = endY;
							break;
						case 'east':
							if(_inputPort.get('location') == 'west') {
								var endX = endNodeXOffset + ctrlXPtOffset;
							} else {
								var endX = endNodeXOffset;
							}
							var cpX2 = endX + ctrlXPtOffset;
							if(_inputPort.get('location') == 'north')
								var endY = ctrlYPtOffset + endNodeYOffset;
							else var endY = endNodeYOffset;
							var cpY2 = endY;
							break;
					}
				}

				_fullBezierDef = {
					'canvasNodeId': _canvasNodeId,
					'parentNode': _target.getView('editor').get('node'),
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
					'style': this.get('style')
				};
			},
		}
	}
}
