
if (!R8.ViewSpace2) {

	R8.ViewSpace2 = function(viewSpaceDef) {
		var _def = viewSpaceDef,
			_id = _def['object']['id'],
			_ui = _def.object.ui,
			_uiCookie = {},
			_cookieKey = '_uiCookie-'+_id,

			_type = _def['type'],
			_items = {},
			_node = R8.Utils.Y.one('#'+_def.containerNodeId),
			_updateBackgroundCall = null,

			_draggableItems = {},
			_selectedItems = {},
			_itemPosUpdateList = {},

			_isReady = false,
			_events = {},

//TODO: revisit when implementing user/system settings more
			_userSettings = {showPorts: true,showLinks:true},

			_links = null,
			_links2 = {},
			_linkRenderList = [];

		return {

			init: function() {
				this.setupEvents();
				this.startUpdater();

				YUI().use('cookie','json', function(Y){
					var uiCookieJSON = Y.Cookie.get(_cookieKey);
					_uiCookie = (uiCookieJSON == null) ? {} : Y.JSON.parse(uiCookieJSON);
//					_itemPosUpdateListJSON = Y.Cookie.get("_itemPosUpdateList");
//					_itemPosUpdateList = (_itemPosUpdateListJSON == null) ? {} : Y.JSON.parse(_itemPosUpdateListJSON);
//TODO: cleanup after moving fully to new pos handling
/*
					for(var i in _itemPosUpdateList) {
						_ui.items[i]['top'] = _itemPosUpdateList[i]['pos']['top'];
						_ui.items[i]['left'] = _itemPosUpdateList[i]['pos']['left'];
					}
*/
					for(var i in _uiCookie) {
						_ui.items[i]['top'] = _uiCookie[i]['top'];
						_ui.items[i]['left'] = _uiCookie[i]['left'];
					}
					_isReady = true;
				});
			},

			isReady: function() {
				return _isReady;
			},

			get: function(itemToGet) {
				switch(itemToGet) {
					case "id":
						return _id;
						break;
					case "def":
						return _def;
						break;
					case "node":
						return _node;
						break;
				}
			},
			items: function(itemId) {
				return _items[itemId];
			},
			links: function(linkId) {
				return _links2[linkId];
			},

			setupEvents: function() {

				_events['item_click'] = R8.Utils.Y.delegate('click',this.updateSelectedItems,_node,'.vspace-item',this);
				_events['vspace_click'] = R8.Utils.Y.delegate('click',this.clearSelectedItems,'body','#'+_node.get('id'));

//DEBUG
//TODO: mouse over popup screwed b/c of layout, disabling for now
/*
				_events['port_mover'] = R8.Utils.Y.delegate('mouseover',this.portMover,_node,'.port',this);
				_events['port_mover'] = R8.Utils.Y.delegate('mouseout',this.portMout,_node,'.port',this);
*/
				_events['item_name_dblclick'] = R8.Utils.Y.delegate('dblclick',function(e){
					var itemId = e.currentTarget.getAttribute('data-id'),
						inputWrapperNode = R8.Utils.Y.one('#item-'+itemId+'-name-input-wrapper'),
						inputNode = R8.Utils.Y.one('#item-'+itemId+'-name-input');

					e.currentTarget.setStyle('display','none');
					inputWrapperNode.setStyle('display','block');
					inputNode.focus();

					if(inputNode.getAttribute('data-blursetup') == '') {
						inputNode.on('blur',function(e){
							var itemId = e.currentTarget.getAttribute('data-id'),
								inputWrapperNode = R8.Utils.Y.one('#item-'+itemId+'-name-input-wrapper'),
								nameWrapperNode = R8.Utils.Y.one('#item-'+itemId+'-name-wrapper');

							inputWrapperNode.setStyle('display','none');
							nameWrapperNode.setStyle('display','block');
							e.currentTarget.setAttribute('data-blursetup','true');
						});
					}

				},_node,'.item-name',this);

//				R8.Workspace.events['item_click'] = R8.Utils.Y.delegate('click',function(){console.log('clicked item');},R8.Workspace.viewSpaceNode,'.item, .connector');
//				R8.Workspace.events['vspace_mdown'] = R8.Utils.Y.delegate('mousedown',R8.Workspace.checkMouseDownEvent,'body','#'+_node.get('id'));
			},
/*
			createLink: function() {
				var date = new Date();
				var tempLinkId = 't-'+date.getTime() + '-' + Math.floor(Math.random()*20),
					startPortId = 'port-2147483941',
					endPortId = 'port-2147483744',
					startPortDef = this.getPortDefById(startPortId),
					endPortDef = this.getPortDefById(endPortId);

				var linkDef = {
						'id': tempLinkId,
						'startItem': {
							'parentItemId': startPortDef['parentItemId'],
							'location':startPortDef.location,
							'nodeId':startPortId
						},
						'endItems': [{
							'parentItemId': endPortDef['parentItemId'],
							'location':endPortDef.location,
							'nodeId':endPortId
						}],
						'type': 'fullBezier',
						'style':[
							{'strokeStyle':'#4EF7DE','lineWidth':5,'lineCap':'round'},
							{'strokeStyle':'#FF33FF','lineWidth':3,'lineCap':'round'}
						],
						'port_id': startPortDef.id,
						'other_end_id': endPortDef.id
					};

//TODO: this is temp
				_links[linkDef.id] = linkDef;
				this.addLinkToItems(linkDef);
				R8.Canvas.renderLink(linkDef);
			},
*/
			getLinkDefByPortId: function(portId) {
				for(var l in _links) {
					if(_links[l].port_id ==  portId || _links[l].other_end_id == portId) return _links[l];
				}
			},
			getLinkByPortId: function(portId) {
				for(var l in _links2) {
					if(_links2[l].get('portId') ==  portId || _links2[l].get('otherEndId') == portId) return _links2[l];
				}

				return null;
			},

			mergePorts: function(mergePortNodeId,targetPortNodeId) {
				var mergePortDef = this.getPortDefById(mergePortNodeId),
					targetPortDef = this.getPortDefById(targetPortNodeId),
					mergePortNode = R8.Utils.Y.one('#'+mergePortDef.nodeId),
					targetPortNode = R8.Utils.Y.one('#'+targetPortDef.nodeId),
					link = this.getLinkByPortId(mergePortNodeId.replace('port-',''));
//					linkDef = this.getLinkDefByPortId(mergePortNodeId.replace('port-',''));

//DEBUG
/*
console.log('inside of viewspace.mergeports...');
console.log('mergePortNodeId:'+mergePortNodeId);
console.log(mergePortDef);
console.log('targetPortNodeId:'+targetPortNodeId);
console.log(targetPortDef);
console.log(linkDef);
console.log('----------PARENT TEST--------------');
console.log(_items[mergePortDef.parentItemId]);
*/
				//make sure the merging port animates over the target port
				mergePortNode.setStyle('zIndex','3');
				var that=this;
				YUI().use('anim', function(Y) {
					var pX = targetPortNode.getX(),
						pY = mergePortNode.getY();

				    var portAnim = new Y.Anim({
				        node: '#'+mergePortNodeId,
						to: {
							xy: [targetPortNode.getX(),mergePortNode.getY()]
						},
						duration: 0.5
				    });
					portAnim.on('tween',function(e){
//						_items[mergePortDef.parentItemId].refreshLinks();
						link.render();
					});
				    var linkAnim = new Y.Anim({
				        node: '#'+link.get('canvasNodeId'),
						to: {
							opacity: 0
						},
						duration: 0.3
				    });

					var animOnEnd = function(e) {
							this.setAttrs({
								'to':{opacity: 0},
								duration: 0.3
							});
							this.on('end',function(e){
								linkAnim.run();

								var reflowCallback = function() {
									that.removeLink(link.get('id'));
									_items[mergePortDef.parentItemId].removePort('port-'+mergePortDef.id);
								}
								setTimeout(reflowCallback,200);
							});
							this.run();
						}
					portAnim.once('end',animOnEnd);

					portAnim.run();
				});
			},
/*
//TODO: old, remove after updating link handling for external to l4 merge
			removeLink: function(linkId) {
				delete(_links[linkId]);
			},
*/
			portMout: function(e) {
				R8.Utils.Y.one('#port-modal').remove();
			},

			portMover: function(e) {
				var portNode = e.currentTarget,
					portId = portNode.get('id'),
					portDef = this.getPortDefById(portId),
					left = e.clientX - 240,
					top = e.clientY - 90;

				var modalHTML = '<div id="port-modal" class="port-modal" style="top: '+top+'px; left: '+left+'px;">\
									<div class="l-col">\
										<div class="corner tl"></div>\
										<div class="l-col-body"></div>\
										<div class="corner bl"></div>\
									</div>\
									<div id="port-modal-body" class="body">\
										<div class="header">'+portDef['display_name']+'</div>\
										<div class=".body-content">\
											<div>'+portDef['description']+'</div>\
										</div>\
									</div>\
									<div class="r-col">\
										<div class="corner tr"></div>\
										<div class="r-col-body"></div>\
										<div class="corner br"></div>\
									</div>\
							</div>';
/*
				var modalHTML = '<div id="port-details" style="position:absolute; z-index: 100; width: 200px; height: 50px; border: 1px solid black; background-color: #FFFFFF; top: '+top+'px; left: '+left+'px;">\
									<div style="height: 20px; width: 200px; float: left; position: relative; font-weight: bold">'+portDef['display_name']+'</div>\
									<div style="height: 30px; width: 200px; float: left; position: relative;">'+portDef['description']+'</div>\
								</div>';
*/
				_node.append(modalHTML);
//console.log(portDef);
			},

			items: function(id) {
				return _items[id];
			},

			addItems: function(items) {
				if(_ui == null) _ui = {"items":{}};

				for(i in items) {
					var item = items[i], tpl_callback = item['tpl_callback'];

					switch(items[i]['type']) {
						case "node_group":
							this.addGroup(item);
							break;
						case "node":
							this.addNode(item);
							break;
						case "monitor":
							this.addMonitor(item);
							break;
						case "component":
							this.addComponent(item);
							break;
						default:
							break;
					}
					if(typeof(item['ui']) == 'undefined' || items[i]['type'] == "monitor") continue;

/*					var id = item['object']['id'],
						top = (typeof(_itemPosUpdateList[id]) == 'undefined') ? item['object']['ui'][_id]['top'] : _itemPosUpdateList[id]['pos']['top'],
						left = (typeof(_itemPosUpdateList[id]) == 'undefined') ? item['object']['ui'][_id]['left'] : _itemPosUpdateList[id]['pos']['left'];
*/
					var itemId = item['object']['id'];

//TODO: revisit with UI pos cleanup, using ui params at both item and item.object level
					if(typeof(_ui.items[itemId]) == 'undefined') {
						_ui.items[itemId] = {};
						_ui.items[itemId]['top'] = item['object']['ui'][_id]['top'];
						_ui.items[itemId]['left'] = item['object']['ui'][_id]['left'];
					}

/*					var id = item['object']['id'],
						top = (typeof(_itemPosUpdateList[id]) == 'undefined') ? _ui.items[id]['top'] : _itemPosUpdateList[id]['pos']['top'],
						left = (typeof(_itemPosUpdateList[id]) == 'undefined') ? _ui.items[id]['left'] : _itemPosUpdateList[id]['pos']['left'];
*/
					var id = item['object']['id'],
						top = (typeof(_uiCookie[id]) == 'undefined') ? _ui.items[id]['top'] : _uiCookie[id]['top'],
						left = (typeof(_uiCookie[id]) == 'undefined') ? _ui.items[id]['left'] : _uiCookie[id]['left'];

					_items[id].get('node').setStyles({'top':top,'left':left,'display':'block'});
				}

				this.purgePendingDelete();
//				this.retrieveLinks(items);
//TODO: revisit and have retrieveLinks file a custom callback when complete that renderLinks can sub to
//				if(_userSettings.showLinks == true) {
//					this.renderLinks();
//				}
			},

			itemsReady: function() {
				
			},

			retrieveLinks: function(items) {
				var itemList = [];
				if (typeof(items) == 'undefined') {
					for (var i in _items) {
						if (_items[i].get('model') == 'node') 
							itemList.push({
								'id': _items[i].get('id'),
								'model': _items[i].get('model')
							});
					}
				} else {
					for(var i in items) {
						itemList.push({
							'id': items[i].object.id,
							'model': items[i].model
						});
					}
				}
				var that = this;
				YUI().use('json',function(Y){
					var linkCallback = function(ioId,responseObj) {
						that.setLinks(ioId,responseObj);
//TODO: revisit, need to decouple rendering from retrieval
//						that.renderLinks();
					}
					var params = {
						'callbacks': {
							'io:success':linkCallback
						},
						'cfg': {
//							'data': 'context_list=' + Y.JSON.stringify(itemList)
							'data': 'item_list=' + Y.JSON.stringify(itemList)
						}
					};
//					R8.Ctrl.call('attribute_link/get_under_context_list',params);
					R8.Ctrl.call(_type+'/get_links/'+_id,params);
				});
			},

			setLinks: function(ioId,responseObj) {
				eval("R8.Ctrl.callResults[ioId]['response'] =" + responseObj.responseText);
				var response = R8.Ctrl.callResults[ioId]['response'];
//				var linkList = response['application_attribute_link_get_under_context_list']['content'][0]['data'];
				var linkList = response['application_datacenter_get_links']['content'][0]['data'];
//				var tempLinkList = {};
				for(i in linkList) {
//TODO: revisit when cleaning up actions for retrieving links
					if(linkList[i]['id'] == '' || linkList[i]['hidden'] == true || linkList[i]['type'] == 'internal') continue;

//					tempLinkList['link-'+linkList[i]['id']] = linkList[i];
//					_linkRenderList.push('link-'+linkList[i]['id']);
//DEBUG
					this.addLink(linkList[i]);
//					_links2['link-'+linkList[i]['id']] = new R8.Link(linkList[i],this);
				}
				_links = {};
//				for(var i in tempLinkList) _links[i] = tempLinkList[i];
//				_links = tempLinkList;
//				if(_userSettings.showLinks == true) {
//					this.renderLinks();
//				}
			},

			addLink: function(linkObj) {
				var linkId = 'link-'+linkObj.id;
				_links2[linkId] = new R8.Link(linkObj,this);
				_links2[linkId].init();
				_links2[linkId].render();
			},

			removeLink: function(linkId) {
				this.removeLinkFromItems(linkId);
				_links2[linkId].destroy();
				delete(_links2[linkId]);
			},
			addLinkToItems: function(linkDef) {
//TODO: revisit after implementing many end item links
				_items[linkDef.startItem.parentItemId].addLink(linkDef);
				_items[linkDef.endItems[0].parentItemId].addLink(linkDef);
			},
			removeLinkFromItems: function(linkId) {
//TODO: revisit after implementing many end item links
				var startItemId = _links2[linkId].get('startParentItemId');
				var endItemId = _links2[linkId].get('endParentItemId');
				_items[startItemId].removeLink(linkId);
				_items[endItemId].removeLink(linkId);
			},
			hideLinks: function(fromPorts) {
				for(var l in _links) {
					R8.Utils.Y.one('#link-'+_links[l].id).setStyle('display','none');
				}
				if (typeof(fromPorts) == 'undefined') {
					_userSettings.showLinks = false;
				}
			},
			showLinks: function(fromPorts) {
				if(_userSettings.showPorts == false && typeof(fromPorts) == 'undefined') {
					_userSettings.showLinks = true;
					return;
				}

				for (var l in _links) {
					R8.Utils.Y.one('#link-' + _links[l].id).setStyle('display', 'block');
				}

				_userSettings.showLinks = true;
			},
/*
			renderItemPorts: function(itemId,ports) {
console.log(ports);
			},
*/
			purgePendingDelete: function() {
				var itemChildren = _node.get('children');

				itemChildren.each(function(){
					var dataModel = this.getAttribute('data-model');
					var status = this.getAttribute('data-status');

					if((dataModel == 'node' || dataModel == 'group') && status == 'pending_delete') {
						this.purge(true);
						this.remove();
						delete(this);
					}
				});
			},

			regNewItem : function(item) {
				var itemNodeId = item.get('node_id'),
					itemNode = item.get('node');

				itemNode.setAttribute('data-status','added');

				switch(item.get('type')) {
					case "node":
						itemNode.addClass('vspace-item');
						this.addDrag(item);
						break;
					case "monitor":
						itemNode.addClass('vspace-item');
						break;
				}
			},


			/*
			 * addDrag will make a item drag/droppable on a viewspace
			 * @method addDrag
			 * @param {string} 	item An item object, stored locally in _items
			 */
			addDrag : function(item) {
				var viewSpace = this,
					draggableItems = _draggableItems,
					itemId = item.get('id');

				YUI().use('dd-constrain','dd-drag','dd-plugin',function(Y){
					draggableItems[itemId] = new Y.DD.Drag({
						node: '#'+item.get('node_id')
					}).plug(Y.Plugin.DDConstrained, {
						constrain2node: '#'+_node.get('id')
					});

					//add invalid drag items here.., right now only ports
					draggableItems[itemId].addInvalid('.port');

//TODO: seems to be causing some error
					//setup valid handles
//					draggableItems[itemId].addHandle('.drag-handle');

					draggableItems[itemId].on('drag:start',function(){
						viewSpace.clearSelectedItems();
						viewSpace.addSelectedItem(itemId);
					});
					draggableItems[itemId].on('drag:drag',function(){
						_items[itemId].refreshLinks();
					});
					draggableItems[itemId].on('drag:end',function(e){
						viewSpace.clearSelectedItems();
						viewSpace.touchItems([itemId]);
/*						var node = this.get('node'),
							nodeId = node.get('id'),
							top = node.getStyle('top'),
							left = node.getStyle('left');

						_itemPosUpdateList[itemId] = {
							'model':_items[itemId].get('model'),
							'pos':{'top':top,'left':left}
						};
						_ui.items[itemId]['top'] = top;
						_ui.items[itemId]['left'] = left;

//DEBUG
console.log('Need to update positions...');
console.log(_itemPosUpdateList);
console.log(_ui.items[itemId]);
						YUI().use('json','cookie', function(Y){
							var _itemPosUpdateListJSON = Y.JSON.stringify(_itemPosUpdateList);
							Y.Cookie.set("_itemPosUpdateList", _itemPosUpdateListJSON);
						});
*/
//TODO: revisit after cleanup, currently needed b/c on drag end, margins get updated for dropshadow so links
//are off by several pixels
/*
						var delayedRefresh = function() {
							_items[itemId].refreshLinks();
						}
						setTimeout(delayedRefresh,20);
*/
					});

/*
					R8.Workspace.viewspaces[vsContext]['items'][itemId]['drag'].on('drag:drag',function(){
//TODO: update refreschConnectors with new viewspace object usage
//						R8.Component.refreshConnectors(this.get('node').get('id'));
					});
*/
				});
				item.get('node').setAttribute('data-status','dd-ready');
			},

			touchItems: function(item_list) {
				for(var i in item_list) {
					var itemId = item_list[i],
						itemNode = _items[itemId].get('node');

//					_itemPosUpdateList[itemId] = {
//						'model':_items[itemId].get('model'),
//						'pos':{'top':itemNode.getStyle('top'),'left':itemNode.getStyle('left')}
//					};

					if(typeof(_uiCookie[itemId]) == 'undefined') _uiCookie[itemId] = {};
					_uiCookie[itemId]['top'] = itemNode.getStyle('top');
					_uiCookie[itemId]['left'] = itemNode.getStyle('left');

					var top = itemNode.getStyle('top');
					var left = itemNode.getStyle('left');
					_ui.items[itemId]['top'] = parseInt(top.replace('px',''));
					_ui.items[itemId]['left'] = parseInt(left.replace('px',''));
				}
				YUI().use('json','cookie', function(Y){
					var _uiCookieJSON = Y.JSON.stringify(_uiCookie);
					Y.Cookie.set(_cookieKey, _uiCookieJSON);
				});
			},

			getItemPortDef: function(itemId,portDefId) {
				var pDefs = _items[itemId].get('portDefs');

				return pDefs[portDefId];
			},

			getPortDefById: function(portId) {
				for(itemId in _items) {
					var pDefs = _items[itemId].get('portDefs');
					if(pDefs != null && typeof(pDefs[portId]) != 'undefined') {
						var returnDef = pDefs[portId];

//TODO: temp hack, should probably set parent item id permanently
						returnDef['parentItemId'] = itemId;
						return returnDef;
					}
				}
				return null;
			},

			getItemByPortId: function(portId) {
				for(itemId in _items) {
					var pDefs = _items[itemId].get('portDefs');
					if(pDefs != null && typeof(pDefs[portId]) != 'undefined') {
						var returnDef = pDefs[portId];
						return _items[itemId];
					}
				}
				return null;
			},

			purgeUIData: function(ioId,responseObj) {
				_uiCookie = {};
				YUI().use("cookie",function(Y){
					Y.Cookie.remove(_cookieKey);
				});
			},

			backgroundUpdater: function() {
				var count = 0;
				for(item in _uiCookie) {
					count++;
				}
				var that = this;
				if (count > 0) {
					YUI().use("json", function(Y){
//						var reqParam = 'item_list=' + Y.JSON.stringify(_itemPosUpdateList);
						var reqParam = 'ui=' + Y.JSON.stringify(_ui);

						var params = {
							'cfg': {
								'data': reqParam
							},
							'callbacks': {
								'io:success':that.purgeUIData
							}
						};
						//R8.Ctrl.call('viewspace/update_pos/' + _id, params);
//						R8.Ctrl.call('workspace/update_pos/' + _id, params);
						R8.Ctrl.call('datacenter/update_vspace_ui/' + _id, params);
					});
				}

				var fireBackgroundUpdate = function() {
					that.backgroundUpdater();
				}
				_updateBackgroundCall = setTimeout(fireBackgroundUpdate,5000);
			},

			startUpdater: function() {
				var that = this;
				var fireBackgroundUpdate = function() {
					that.backgroundUpdater();
				}
				_updateBackgroundCall = setTimeout(fireBackgroundUpdate,5000);
			},

			stopUpdater: function() {
				clearTimeout(_updateBackgroundCall);
			},

			getSelectedItem: function(itemId) {
				return _selectedItems[itemId];
			},
			getSelectedItems: function() {
				return _selectedItems;
			},

//TODO: revisit, right now these are only used from notifications panel mouseenter/mouseleave
			itemFocus: function(itemId) {
				this.clearSelectedItems();
				this.addSelectedItem(itemId,{});
			},
			blurItems: function() {
				this.clearSelectedItems();
			},
//-------------------------------------------------------------------------------------------
			addSelectedItem: function(itemId,data) {
				_selectedItems[itemId] = data;
				_items[itemId].get('node').setStyle('zIndex',51);
				_items[itemId].get('node').addClass('focus');
			},

			clearSelectedItems: function(e) {
//DEBUG
/*
if (typeof(e) != 'undefined') {
	console.log('X:' + e.clientX + '   Y:' + e.clientY);
}
*/
				for(itemId in _selectedItems) {
					_items[itemId].get('node').removeClass('focus');
					_items[itemId].get('node').setStyle('zIndex',1);
					delete(_selectedItems[itemId]);
				}
			},

			updateSelectedItems: function(e) {
				var itemNodeId = e.currentTarget.get('id'),
					model = e.currentTarget.getAttribute('data-model'),
					modelId = e.currentTarget.getAttribute('data-id');

				if(e.ctrlKey == false) this.clearSelectedItems();
				this.addSelectedItem(modelId,{'model':model,'id':modelId});

//DEBUG
//TODO: revisit once puting dock into place
				R8.Dock2.focusChange(_selectedItems);

				e.stopImmediatePropagation();
			},

//---------------------------------------------------
//---------------------------------------------------
//------------ PORT METHODS -------------------------
//---------------------------------------------------
//---------------------------------------------------
			hidePorts: function() {
				for(var i in _items) {
					_items[i].hidePorts();
				}

				this.hideLinks(true);
				_userSettings.showPorts = false;
			},

			showPorts: function() {
				for(var i in _items) {
					_items[i].showPorts();
				}
				if(_userSettings.showLinks == true) {
					this.showLinks(true);
				}
				_userSettings.showPorts = true;
			},

//---------------------------------------------------
//---------------------------------------------------
//------------ ITEM METHODS -------------------------
//---------------------------------------------------
//---------------------------------------------------

			addGroup: function(group) {
				var id = group['object']['id'];
				_items[id] = new R8.Group(group,this);
				_node.append(_items[id].render());
				_items[id].init();

				this.regNewItem(_items[id]);
			},

			addNode: function(node) {
				var id = node['object']['id'];
				_items[id] = new R8.Node2(node,this);
				_node.append(_items[id].render());
				_items[id].init();

				this.regNewItem(_items[id]);

				if(_userSettings.showPorts == true) {
					_items[id].renderPorts();
				}
			},

			addMonitor: function(monitor) {
				var id = monitor['object']['id'];
				_items[id] = new R8.Monitor(monitor,this);
				_node.append(_items[id].render());
				_items[id].init();

				this.regNewItem(_items[id]);

				if(_userSettings.showPorts == true) {
					_items[id].renderPorts();
				}
			},

			refreshGroup: function(group) {
				
			},

			addComponent: function(group) {
				
			},

			refreshComponent: function(group) {
				
			},

			focus: function() {
				
			},

			blur: function() {
				
			},

			pushPendingDelete: function(id,def) {
				_pendingDelete[id] = def;
			}
		}
	};
}
