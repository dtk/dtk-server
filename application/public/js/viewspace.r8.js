
if (!R8.ViewSpace) {

	R8.ViewSpace = function(viewSpaceDef) {
		var _def = viewSpaceDef,
			_id = _def['object']['id'],
			_type = _def['type'],
			_items = {},
			_node = R8.Utils.Y.one('#viewspace'),
			_updateBackgroundCall = null;

			_draggableItems = {},
			_selectedItems = {},
			_itemPosUpdateList = {},

			_isReady = false,
			_events = {},

			_links = {},
			_linkRenderQueue = {};

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
//				R8.Workspace.events['item_click'] = R8.Utils.Y.delegate('click',function(){console.log('clicked item');},R8.Workspace.viewSpaceNode,'.item, .connector');
//				R8.Workspace.events['vspace_mdown'] = R8.Utils.Y.delegate('mousedown',R8.Workspace.checkMouseDownEvent,'body','#viewspace');
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
						top = (typeof(_itemPosUpdateList[id]) == 'undefined') ? item['ui']['top'] : _itemPosUpdateList[id]['pos']['top'],
						left = (typeof(_itemPosUpdateList[id]) == 'undefined') ? item['ui']['left'] : _itemPosUpdateList[id]['pos']['left'];

					_items[id].get('node').setStyles({'top':top,'left':left});
				}

				this.purgePendingDelete();
				this.retrieveLinks();

			},

			itemsReady: function() {
				
			},

			retrieveLinks:function() {
				var itemList = [];
				for(i in _items) {
					if(_items[i].get('model') == 'node')
						itemList.push({'id':_items[i].get('id'),'model':_items[i].get('model')});
				}
				var that = this;
				YUI().use('json',function(Y){
					var params = {
						'callbacks': {
							'io:success':that.setLinks
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
				for(i in linkList) {
					if(linkList[i]['id'] == '' || linkList[i]['hidden'] == true || linkList[i]['type'] == 'internal') continue;

					_links[linkList[i]['id']] = linkList[i];
				}
console.log(_links);
			},

			renderLinks: function() {
				if(_linkRenderQueue.length == 0) return;

				for(i in _linkRenderQueue) {
console.log(_linkRenderQueue[i]);
				}
			},

			renderItemPorts: function(itemId,ports) {
console.log(ports);
			},

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
						var delayedRefresh = function() {
							_items[itemId].refreshLinks();
						}
						setTimeout(delayedRefresh,20);
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

			setLink: function(id,def) {
				_links[id] = def;

				_items[_links[id]['startItemId']].addLink(id,def);
				_items[_links[id]['endItemId']].addLink(id,def);
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
//DEBUG
//console.log(count);
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
			//DEBUG return;
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
if (typeof(e) != 'undefined') {
	console.log('X:' + e.clientX + '   Y:' + e.clientY);
}

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

				e.stopImmediatePropagation();
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
				_items[id].renderPorts();
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
