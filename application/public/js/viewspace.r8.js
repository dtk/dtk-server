
if (!R8.ViewSpace) {

	R8.ViewSpace = function(viewSpaceDef) {
		var _def = viewSpaceDef,
			_id = _def['object']['id'],
			_type = _def['type'],
			_items = {},
			_node = R8.Utils.Y.one('#viewspace'),
			_updateBackgroundCall = null,

			_draggableItems = {},
			_selectedItems = {},
			_itemPosUpdateList = {},

			_isReady = false,
			_events = {},

//TODO: revisit when implementing user/system settings more
			_userSettings = {showPorts: true,showLinks:true},

			_links = null,
			_linkRenderList = [];

		return {

			init: function() {
				this.setupEvents();
				this.startUpdater();

				YUI().use('cookie','json', function(Y){
					_itemPosUpdateListJSON = Y.Cookie.get("_itemPosUpdateList");
					_itemPosUpdateList = (_itemPosUpdateListJSON == null) ? {} : Y.JSON.parse(_itemPosUpdateListJSON);
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
				}
			},

			setupEvents: function() {

				_events['item_click'] = R8.Utils.Y.delegate('click',this.updateSelectedItems,_node,'.vspace-item',this);
				_events['vspace_click'] = R8.Utils.Y.delegate('click',this.clearSelectedItems,'body','#viewspace');
				_events['port_mover'] = R8.Utils.Y.delegate('mouseover',this.portMover,_node,'.port',this);
				_events['port_mover'] = R8.Utils.Y.delegate('mouseout',this.portMout,_node,'.port',this);

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
//				R8.Workspace.events['vspace_mdown'] = R8.Utils.Y.delegate('mousedown',R8.Workspace.checkMouseDownEvent,'body','#viewspace');
			},

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
				for(i in items) {
					var item = items[i], tpl_callback = item['tpl_callback'];

					switch(items[i]['type']) {
						case "node_group":
							this.addGroup(item);
							break;
						case "node":
							this.addNode(item);
							break;
						case "component":
							this.addComponent(item);
							break;
						default:
							break;
					}
					if(typeof(item['ui']) == 'undefined') continue;

					var id = item['object']['id'],
						top = (typeof(_itemPosUpdateList[id]) == 'undefined') ? item['object']['ui'][_id]['top'] : _itemPosUpdateList[id]['pos']['top'],
						left = (typeof(_itemPosUpdateList[id]) == 'undefined') ? item['object']['ui'][_id]['left'] : _itemPosUpdateList[id]['pos']['left'];

					_items[id].get('node').setStyles({'top':top,'left':left,'display':'block'});
				}

				this.purgePendingDelete();
				this.retrieveLinks();

				if(_userSettings.showLinks == true) {
					this.renderLinks();
				}
			},

			itemsReady: function() {
				
			},

			retrieveLinks: function() {
				var itemList = [];
				for(i in _items) {
					if(_items[i].get('model') == 'node')
						itemList.push({'id':_items[i].get('id'),'model':_items[i].get('model')});
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
							'data': 'context_list=' + Y.JSON.stringify(itemList)
						}
					};
					R8.Ctrl.call('attribute_link/get_under_context_list',params);
				});
			},

			setLinks: function(ioId,responseObj) {
				eval("R8.Ctrl.callResults[ioId]['response'] =" + responseObj.responseText);
				var response = R8.Ctrl.callResults[ioId]['response'];
				var linkList = response['application_attribute_link_get_under_context_list']['content'][0]['data'];
				var tempLinkList = {}
				for(i in linkList) {
//TODO: revisit when cleaning up actions for retrieving links
					if(linkList[i]['id'] == '' || linkList[i]['hidden'] == true || linkList[i]['type'] == 'internal') continue;

					tempLinkList['link-'+linkList[i]['id']] = linkList[i];
					_linkRenderList.push('link-'+linkList[i]['id']);
				}
				_links = tempLinkList;
			},

			renderLinks: function() {
				if(_links == null) {
					var that = this;
					var recall = function() {
						that.renderLinks();
					}
					setTimeout(recall,300);
					return;
				}

				var pendingRemoval = [];
				if(_linkRenderList.length == 0) return;

				for(var i=_linkRenderList.length-1; i >=0; i--) {
//TODO: decide how best to manage item/port id's, currently using id for items, and port-<id> for ports
					var linkId = _linkRenderList[i],
						portId = _links[linkId]['port_id'],
						itemId = _links[linkId]['item_id'],
						startNodeId = 'port-'+portId,
						endNodeId = 'port-'+_links[linkId]['other_end_id'],
						startPortDef = this.getItemPortDef(itemId,'port-'+portId),
						endPortDef = this.getPortDefById('port-'+_links[linkId]['other_end_id']);

					if (typeof(startPortDef) != 'undefined' && endPortDef != null) {
						var linkDef = {
								'id': linkId,
								'startItemId':itemId,
								'endItemId': endPortDef['parentItemId'],
								'type': 'fullBezier',
								'startElement': {
									'elemID': '?',
									'location':startPortDef.location,
									'connectElemID':startNodeId
								},
								'endElements': [{
									'elemID':'?',
									'location':endPortDef.location,
									'connectElemID':endNodeId
								}]
							};

						this.addLinkToItems(linkId,linkDef);

						R8.Canvas.renderLink(linkDef);
						var startNode = R8.Utils.Y.one('#'+startNodeId);
						var endNode = R8.Utils.Y.one('#'+endNodeId);
						startNode.removeClass('available');
						startNode.addClass('connected');
						endNode.removeClass('available');
						endNode.addClass('connected');

						R8.Utils.arrayRemove(_linkRenderList,i);
//						delete(_linkRenderList.pop());
					}
				}

				if(_linkRenderList.length > 0) {
					var that = this;
					var callback = function() {
						that.renderLinks();
					}
					setTimeout(callback,20);
					return;
				}
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
				itemNode.addClass('vspace-item');
				this.addDrag(item);
//				this.addDrop(itemId);
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

				YUI().use('dd-drag','dd-plugin',function(Y){
					draggableItems[itemId] = new Y.DD.Drag({
						node: '#'+item.get('node_id')
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
console.log('should have refreshed link....');
					});
					draggableItems[itemId].on('drag:end',function(e){
						viewSpace.clearSelectedItems();
						var node = this.get('node'),
							nodeId = node.get('id'),
							top = node.getStyle('top'),
							left = node.getStyle('left');

						_itemPosUpdateList[itemId] = {
							'model':_items[itemId].get('model'),
							'pos':{'top':top,'left':left}
						};
						YUI().use('json','cookie', function(Y){
							var _itemPosUpdateListJSON = Y.JSON.stringify(_itemPosUpdateList);
							Y.Cookie.set("_itemPosUpdateList", _itemPosUpdateListJSON);
						});
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

			setLink: function(id,def) {
				_links[id] = def;

				_items[_links[id]['startItemId']].addLink(id,def);
				_items[_links[id]['endItemId']].addLink(id,def);
			},

			addLinkToItems: function(id,def) {
				_items[def['startItemId']].addLink(id,def);
				_items[def['endItemId']].addLink(id,def);
			},

			purgeUIData: function(ioId,responseObj) {
				_itemPosUpdateList = {};
				YUI().use("cookie",function(Y){
					Y.Cookie.remove('_itemPosUpdateList');
				});
			},

			backgroundUpdater: function() {
				var count = 0;
				for(item in _itemPosUpdateList) {
					count++;
				}
				var that = this;
				if (count > 0) {
					YUI().use("json", function(Y){
						var reqParam = 'item_list=' + Y.JSON.stringify(_itemPosUpdateList);
						var params = {
							'cfg': {
								'data': reqParam
							},
							'callbacks': {
								'io:success':that.purgeUIData
							}
						};
						//R8.Ctrl.call('viewspace/update_pos/' + _id, params);
						R8.Ctrl.call('workspace/update_pos/' + _id, params);
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

				R8.Dock.focusChange(_selectedItems);

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
				_items[id] = new R8.Node(node,this);
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
