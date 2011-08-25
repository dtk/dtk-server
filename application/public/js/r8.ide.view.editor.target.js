
if (!R8.IDE.View.editor) { R8.IDE.View.editor = {}; }

if (!R8.IDE.View.editor.target) {

	R8.IDE.View.editor.target = function(target) {
		var _target = target,
			_idPrefix = 'editor-target-',
			_panel = null,
			_contentWrapperNode = null,
			_contentNode = null,

			_initialized = false,

			_pendingDelete = {},

//TODO: maybe put UI updates directly into model, else some central updater
			_ui = _target.get('ui'),
			_uiCookie = {},
			_cookieKey = '_uiCookie-'+_target.get('id'),
			_updateBackgroundCall = null,

			_modalNode = null,
			_modalNodeId = 'target-'+_target.get('id')+'-modal',
			_shimNodeId = null,
			_shimNode = null,

			_alertNode = null,
			_alertNodeId = null,

			_items = {},
			_draggableItems = {},
//DEBUG
//			_contentTpl = '<div id="'+_panel.get('id')+'-'+_view.id+'" class="target-viewspace"></div>',
/*

			_contentTpl = '<div id="'+_panel.get('id')+'-'+_view.id+'-wrapper" style="">\
								<div id="'+_panel.get('id')+'-'+_view.id+'" class="target-viewspace">\
									<div id="cmdbar-tabcontainer" style="bottom: 40px;">\
										<div id="cmdbar-tabs-wrapper">\
											<div id="cmdbar-tabs">\
											</div>\
										</div>\
										<div id="cmdbar-tab-content-wrapper"></div>\
									</div>\
									<div id="cmdbar">\
										<div class="cmdbar-input-wrapper">\
											<form id="cmdbar_input_form" name="cmdbar_input_form" onsubmit="R8.Cmdbar2.submit(); return false;">\
												<input type="text" value="" id="cmd" name="cmd" title="Enter Command"/>\
											</form>\
										</div>\
									</div>\
								</div>\
						</div>',
*/

			//FROM WORKSPACE
			_viewSpaces = {},
			_viewSpaceStack = [],
			_currentViewSpace = null,
			_viewContext = 'node',

			_cmdBar = null,

			_events = {};

		return {
			init: function() {
				_contentNode = R8.Utils.Y.one('#'+this.get('id'));
				_contentWrapperNode = R8.Utils.Y.one('#'+this.get('id')+'-wrapper');

				if(_ui == null) _ui = {"items":{}};
				var nodes = _target.get('nodes');

				for(var n in nodes) {
					this.addNode(nodes[n]);
					this.addDrag(n);
				}

//TODO: revisit.., links need to be like other models and views, right now rendering is in target model
				var links = _target.get('loadedLinks');
				for(var l in links) {
					_target.addLink(links[l]);
				}

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
//					_isReady = true;
				});

//DEBUG
//this is old
//				this.getWorkspaceDef();

				var cmdbarDef = {
					'containerNode': _contentNode,
					'panel': _panel,
					'viewSpace': this
				};
				_cmdBar = new R8.Cmdbar2(cmdbarDef);
				_cmdBar.init();
return;
				document.getElementById('cmdbar_input_form').onsubmit = function() {
					_cmdBar.submit();
					return false;
				};

//				_contentNode.append(R8.Dock.render({'display':'block','top':_topbarNode.get('region').bottom}));
//				_contentNode.append(R8.Dock2.render({'display':'block','top':_contentNode.get('region').top}));
				_contentNode.append(R8.Dock2.render({'display':'block','top':40}));
				R8.Dock2.init(_contentNode.get('id'));

				_initialized = true;

				return _initialized;
			},
			render: function() {
				var id=this.get('id');
				_contentTpl = '<div id="'+id+'-wrapper" style="">\
									<div id="'+id+'" class="target-viewspace editor-target" data-id="'+_target.get('id')+'">\
										<div id="cmdbar-tabcontainer" style="bottom: 40px;">\
											<div id="cmdbar-tabs-wrapper">\
												<div id="cmdbar-tabs">\
												</div>\
											</div>\
											<div id="cmdbar-tab-content-wrapper"></div>\
										</div>\
										<div id="cmdbar">\
											<div class="cmdbar-input-wrapper">\
												<form id="'+id+'-cmdbar-form" name="'+id+'-cmdbar-form" onsubmit="return false;">\
													<input type="text" value="" id="'+id+'-cmd" name="'+id+'-cmd" title="Enter Command"/>\
												</form>\
											</div>\
										</div>\
									</div>\
							</div>';

				return _contentTpl;

//				_contentWrapperNode = R8.Utils.Y.Node.create(_contentTpl);
//				_contentNode = _contentWrapperNode.get('children').item(0);

				if(_ui == null) _ui = {"items":{}};
				var nodes = _target.get('nodes');

				for(var n in nodes) {
					this.addItem(nodes[n]);
					this.addDrag(n);
				}
				return _contentWrapperNode;
			},
			resize: function() {
				if(!_initialized) return;

				var pRegion = _panel.get('node').get('region');
				_contentWrapperNode.setStyles({'height':pRegion.height-6,'width':pRegion.width-6});

				R8.Dock2.realign();
/*
				var contentHeight = _node.get('region').height - _headerNode.get('region').height;
				_contentNode.setStyles({'height':contentHeight,'width':_node.get('region').width,'backgroundColor':'#FFFFFF'});
*/
			},
			get: function(key) {
				switch(key) {
					case "id":
						return _idPrefix+_target.get('id');
//						return _target.get('id');
						break;
					case "name":
						return _target.get('name');
						break;
					case "type":
						return _target.get('type');
						break;
					case "node":
//						return _contentWrapperNode;
						return _contentNode;
						break;
					case "items":
						return _viewSpaces[_currentViewSpace].get('items');
						break;
				}
			},
			set: function(key,value) {
				switch(key) {
					case "panel":
						_panel = value;
						break;
				}
			},
			focus: function() {
				this.resize();
				_contentWrapperNode.setStyle('display','block');
			},
			blur: function() {
				_contentWrapperNode.setStyle('display','none');
			},
			close: function() {
				_contentWrapperNode.purge(true);
				_contentWrapperNode.remove();
			},

//--------------------------------------
//TARGET VIEW FUNCTIONS
//--------------------------------------
			addNode: function(item) {
				var itemId = item.get('id');
				item.requireView('editor_target');
				var nodePos = _target.get('ui').items[itemId];

				_items[itemId] = item.getView('editor_target');
				_items[itemId].setParent(this);
				var itemNode = R8.Utils.Y.Node.create(_items[itemId].render());
				itemNode.setStyles({'top':nodePos.top,'left':nodePos.left});
				_contentNode.append(itemNode);

				_items[itemId].init();
			},
//TODO: make remove evented like add using IDE event framework
			removeNode: function(nodeRemoveId) {
				this.removeItem(nodeRemoveId);
			},
			removeItem: function(itemRemoveId) {
				_contentNode.get('children').each(function() {
					var itemNodeId = this.get('id');
					var itemNodeId = itemNodeId.replace('node-','');
//TODO: keep an eye out for leaks from this action.., lots going on with ports and links inside of nodes
					if(itemNodeId == itemRemoveId) {
						this.purge(true);						
						this.remove();
						delete(_items[itemRemoveId]);
					}
				});
			},
			/*
			 * addDrag will make a item drag/droppable on a viewspace
			 * @method addDrag
			 * @param {string} An item id object, stored locally in _items
			 */
			addDrag: function(itemId) {
				var draggableItems = _draggableItems, that=this;

				YUI().use('dd-constrain','dd-drag','dd-plugin',function(Y){
					draggableItems[itemId] = new Y.DD.Drag({
						node: '#'+_items[itemId].get('id')
					}).plug(Y.Plugin.DDConstrained, {
						constrain2node: '#'+_contentNode.get('id')
					});

					//add invalid drag items here.., right now only ports
					draggableItems[itemId].addInvalid('.port');

//TODO: seems to be causing some error
					//setup valid handles
//					draggableItems[itemId].addHandle('.drag-handle');

					draggableItems[itemId].on('drag:start',function(){
						that.clearSelectedItems();
						that.addSelectedItem(itemId);
					});
					draggableItems[itemId].on('drag:drag',function(){
						_items[itemId].refreshLinks();
//						var foo = _items[itemId].get('view','editor_target');
//						var foo = _items[itemId].get('type');
//						console.log(foo);
					});
					draggableItems[itemId].on('drag:end',function(e){
						that.clearSelectedItems();
						that.touchItems([itemId]);
					});
				});
				_items[itemId].get('node').setAttribute('data-status','dd-ready');
			},

			setupEvents: function() {
				_events['item_click'] = R8.Utils.Y.delegate('click',this.updateSelectedItems,_contentNode,'editor-target.item',this);
				_events['vspace_click'] = R8.Utils.Y.delegate('click',this.clearSelectedItems,'body','#'+_contentNode.get('id'));

//DEBUG
//TODO: mouse over popup screwed b/c of layout, disabling for now
/*
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
*/

//				R8.Workspace.events['item_click'] = R8.Utils.Y.delegate('click',function(){console.log('clicked item');},R8.Workspace.viewSpaceNode,'.item, .connector');
//				R8.Workspace.events['vspace_mdown'] = R8.Utils.Y.delegate('mousedown',R8.Workspace.checkMouseDownEvent,'body','#'+_node.get('id'));
			},

			addSelectedItem: function(itemId,data) {
//				_selectedItems[itemId] = data;
//				_items[itemId].get('node').setStyle('zIndex',51);
//				_items[itemId].get('node').addClass('focus');
			},
			clearSelectedItems: function(e) {
/*
				for(itemId in _selectedItems) {
					_items[itemId].get('node').removeClass('focus');
					_items[itemId].get('node').setStyle('zIndex',1);
					delete(_selectedItems[itemId]);
				}
*/
			},
			updateSelectedItems: function(e) {
/*
				var itemNodeId = e.currentTarget.get('id'),
					model = e.currentTarget.getAttribute('data-model'),
					modelId = e.currentTarget.getAttribute('data-id');

				if(e.ctrlKey == false) this.clearSelectedItems();
				this.addSelectedItem(modelId,{'model':model,'id':modelId});
*/

//DEBUG
//TODO: revisit once puting dock into place
//				R8.Dock2.focusChange(_selectedItems);

				e.stopImmediatePropagation();
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
						R8.Ctrl.call('datacenter/update_vspace_ui/' + _target.get('id'), params);
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


/*
				var contextTpl = '<span class="context-span">'+viewSpaceDef.i18n+' > '+viewSpaceDef.object.display_name+'</span>';
				_contextBarNode.append(contextTpl);

				if(typeof(viewSpaceDef.items) != 'undefined') {
					this.addItems(viewSpaceDef.items, id);
					_viewSpaces[id].retrieveLinks(viewSpaceDef.items);
				}
*/
			getWorkspaceDef: function() {
				var that = this;
				var callback = function(ioId,responseObj) {
					eval("var response =" + responseObj.responseText);
					var targetViewDef = response.application_target_get_view_items.content[0].data;

					that.pushViewSpace(targetViewDef);
				}
				var params = {
					'cfg' : {
						method: 'POST',
						'data': ''
					},
					'callbacks': {
						'io:success':callback
					}
				};
				R8.Ctrl.call('target/get_view_items/'+_target.get('id'),params);
			},
			pushViewSpace: function(viewSpaceDef) {
				if(_initialized == false) {
					var that=this;
					var initWaitCallback = function() {
						that.pushViewSpace(viewSpaceDef);
					}
					setTimeout(initWaitCallback,20);
					return;
				}

//DEBUG
//console.log(viewSpaceDef);
				viewSpaceDef.containerNodeId = _contentNode.get('id');

				var id = viewSpaceDef['object']['id'];
				_viewSpaces[id] = new R8.ViewSpace2(viewSpaceDef);
				_viewSpaces[id].init();
				_viewSpaceStack.push(id);
				_currentViewSpace = id;

//				var contextTpl = '<span class="context-span">'+viewSpaceDef.i18n+' > '+viewSpaceDef.object.display_name+'</span>';
//				_contextBarNode.append(contextTpl);

				if(typeof(viewSpaceDef.items) != 'undefined') {
					this.addItems(viewSpaceDef.items, id);
					_viewSpaces[id].retrieveLinks(viewSpaceDef.items);
				}

//				this.refreshNotifications();
			},
			retrieveLinks: function(items,viewSpaceId) {
				var vSpaceId = (typeof(viewSpaceId) == 'undefined') ? _currentViewSpace : viewSpaceId;
				if(!_viewSpaces[vSpaceId].isReady()) {
					var that = this;
					var addItemsCallAgain = function() {
						that.retrieveLinks(items,viewSpaceId);
					}
					setTimeout(addItemsCallAgain,20);
					return;
				}
				_viewSpaces[vSpaceId].retrieveLinks(items);
			},
			addItems: function(items,viewSpaceId) {
				var vSpaceId = (typeof(viewSpaceId) == 'undefined') ? _currentViewSpace : viewSpaceId;
				if(!_viewSpaces[vSpaceId].isReady()) {
					var that = this;
					var addItemsCallAgain = function() {
						that.addItems(items,viewSpaceId);
					}
					setTimeout(addItemsCallAgain,20);
					return;
				}
				_viewSpaces[vSpaceId].addItems(items);

//TODO: move to more event based handling
				R8.IDE.targetItemsAdd(items);
			},
			addItemToViewSpace : function(clonedNode,viewSpaceId) {
				var cleanupId = clonedNode.get('id'),
					modelName = clonedNode.getAttribute('data-model'),
					modelId = clonedNode.getAttribute('data-id'),
					top = clonedNode.getStyle('top'),
					left = clonedNode.getStyle('left'),
					vspaceId = (typeof(viewSpaceId) == 'undefined') ? _currentViewSpace: viewSpaceId;
					vspaceDef = _viewSpaces[vspaceId].get('def'),
					vspaceId = _viewSpaces[vspaceId].get('id'),
					vspaceType = vspaceDef['type'];

				top = parseInt(top.replace('px',''));
				left = parseInt(left.replace('px',''));

				var ui = {};
				var contextUIKey = (typeof(viewSpaceId) == 'undefined') ? _currentViewSpace : viewSpaceId;
				ui[contextUIKey] = {'top':top,'left':left};

				var that=this;
				var addEventParams = {
					'targetId':_target.get('id'),
					'viewSpaceId':viewSpaceId,
					'node':clonedNode
				};
				YUI().use("json", function(Y) {
					var uiStr = Y.JSON.stringify(ui);
					var queryParams = 'ui='+uiStr+'&id='+modelId+'&model='+modelName;
					queryParams += '&model_redirect='+modelName+'&action_redirect=wspace_display_ide&id_redirect=*id';

					var successCallback = function(ioId,responseObj){
						eval("var response =" + responseObj.responseText);
						var newItems = response['application_node_wspace_display_ide']['content'][0]['data'];

						that.addItems(newItems);
						that.setupNewItems();
						addEventParams.newItems = newItems;
						R8.IDE.fire('node-add',addEventParams);
					}
					var callbacks = {
						'io:success' : successCallback
					};

					var params = {
						'callbacks': callbacks,
						'cfg': {
							'data': queryParams
						}
					}
//					R8.Ctrl.call(modelName+'/clone/'+modelId,params);
					R8.Ctrl.call(vspaceType+'/add_item/'+vspaceId,params);
				});
			},
			touchItems: function(item_list) {
				for(var i in item_list) {
					var itemId = item_list[i],
						itemNode = _items[itemId].get('node');

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
			setupNewItems: function() {
				var viewspaceNode = R8.Utils.Y.one('#'+_contentNode.get('id'));
				var itemChildren = viewspaceNode.get('children');
				itemChildren.each(function(){
					var dataModel = this.getAttribute('data-model');
					var status = this.getAttribute('data-status');

					if(status == 'pending_delete') {
						_pendingDelete[this.get('id')] = {
							'top':this.getStyle('top'),
							'left':this.getStyle('left')
						}
					}
					if((dataModel == 'node' || dataModel == 'group') && status == 'pending_setup') {
						var top = this.getStyle('top');
						var left = this.getStyle('left');
						for(item in _pendingDelete) {
							if(_pendingDelete[item]['top'] == top && _pendingDelete[item]['left'] == left) {
								var cleanupNode = R8.Utils.Y.one('#'+item);
								cleanupNode.purge(true);
								cleanupNode.remove();
								delete(cleanupNode);
								delete(_pendingDelete[item]);
							}
						}
					}
				});
			},
			addComponentToContainer : function(componentId,containerNode) {
				var modelName = containerNode.getAttribute('data-model');
				var modelId = containerNode.getAttribute('data-id');

				var queryParams = 'target_model_name='+modelName+'&target_id='+modelId;
				queryParams += '&model_redirect='+modelName+'&action_redirect=added_component_conf_ide&id_redirect='+modelId;

				var that=this;
				var successCallback = function(ioId, responseObj) {
						eval("var response =" + responseObj.responseText);
						var alertStr = response['application_node_added_component_conf_ide']['content'][0]['data'];

						that.refreshItem(modelId);
						that.showAlert(alertStr);
						R8.IDE.triggerCompilation();
//DEBUG
//TODO: revisit when fixing up console debugger
//					R8.Workspace.refreshNotifications();
				}
				var callbacks = {
					'io:success' : successCallback
				};

				R8.Ctrl.call('component/clone/'+componentId,{
					'callbacks': callbacks,
					'cfg': {
						'data': queryParams
					}
				});
			},
			addAssemblyToViewspace: function(componentId,assemblyContext,assemblyLeftPos,containerNode) {
				if(_viewContext == assemblyContext) {
					var queryParams = 'target_model_name=datacenter&target_id='+_currentViewSpace;
					queryParams += '&model_redirect=component&action_redirect=add_assembly_items_ide&id_redirect=*id';
					queryParams += '&parent_id='+_currentViewSpace+'&assembly_left_pos='+assemblyLeftPos

					var that=this;
					var successCallback = function(ioId, responseObj) {
							eval("var response =" + responseObj.responseText);
							var retObj = response['application_component_add_assembly_items_ide']['content'][0]['data'];
	
							that.addItems(retObj.items);
							that.touchItems(retObj.touch_items);
							that.retrieveLinks(retObj.items);
	//DEBUG
	//TODO: revisit when fixing up console debugger
	//					R8.Workspace.refreshNotifications();
					}
					var callbacks = {
						'io:success' : successCallback
					};
					R8.Ctrl.call('component/clone/'+componentId,{
						'callbacks': callbacks,
						'cfg': {
							'data': queryParams
						}
					});
				} else {

				}
			},
			refreshItem: function(itemId){
				_viewSpaces[_currentViewSpace].items(itemId).refresh();
			},
			getSelectedItems: function() {
				return _viewSpaces[_currentViewSpace].getSelectedItems();
			},
			updateItemName: function(id) {
				var nameInputId = 'item-'+id+'-name-input',
					nameWrapperId = 'item-'+id+'-name-wrapper',
					nameInputWrapperId = 'item-'+id+'-name-input-wrapper',
					inputNode = R8.Utils.Y.one('#'+nameInputId),
					nameWrapperNode = R8.Utils.Y.one('#'+nameWrapperId),
					model = nameWrapperNode.getAttribute('data-model'),
					nameInputWrapperNode = R8.Utils.Y.one('#'+nameInputWrapperId),
					newName = inputNode.get('value');

				nameWrapperNode.set('innerHTML',newName);
				nameInputWrapperNode.setStyle('display','none');
				nameWrapperNode.setStyle('display','block');

				var params = {
					'cfg': {
						'data': 'model='+model+'&id='+id+'&display_name='+newName+'&redirect=false'
					}
				};
				R8.Ctrl.call('node/save',params);
//console.log('gettin to wspace func to update name:'+id);
				return newName;
			},
//---------------------------------------------
//alert/notification related
//---------------------------------------------
			showAlert: function(alertStr) {
				_alertNodeId = R8.Utils.Y.guid();

				var alertTpl = '<div id="'+_alertNodeId+'" class="modal-alert-wrapper">\
									<div class="l-cap"></div>\
									<div class="body"><b>'+alertStr+'</b></div>\
									<div class="r-cap"></div>\
								</div>',

					nodeRegion = _contentNode.get('region'),
					height = nodeRegion.bottom - nodeRegion.top,
					width = nodeRegion.right - nodeRegion.left,
					aTop = 0,
					aLeft = Math.floor((width-250)/2);

//				containerNode.append(alertTpl);
				_contentNode.append(alertTpl);
				_alertNode = R8.Utils.Y.one('#'+_alertNodeId);
				_alertNode.setStyles({'top':aTop,'left':aLeft,'display':'block'});
//return;
				YUI().use('anim', function(Y) {
					var anim = new Y.Anim({
						node: '#'+_alertNodeId,
						to: { opacity: 0 },
						duration: .7
					});
					anim.on('end', function(e) {
						var node = this.get('node');
						node.get('parentNode').removeChild(node);
					});
					var delayAnimRun = function(){
							anim.run();
						}
					setTimeout(delayAnimRun,2000);
				});
//				alert(alertStr);
			},

			shimify: function(nodeId) {
				var node = R8.Utils.Y.one('#'+nodeId),
					_shimNodeId = R8.Utils.Y.guid(),
					nodeRegion = node.get('region'),
					height = nodeRegion.bottom - nodeRegion.top,
					width = nodeRegion.right - nodeRegion.left;

				node.append('<div id="'+_shimNodeId+'" class="wspace-shim" style="height:'+height+'; width:'+width+'"></div>');
				_shimNode = R8.Utils.Y.one('#'+_shimNodeId);
				_shimNode.setStyle('opacity','0.8');
				var that=this;
				_shimNode.on('click',function(Y){
					that.destroyShim();
				});
			},
			destroyShim: function() {
				_modalNode.purge(true);
				_modalNode.remove();
				_modalNode = null,

				_shimNode.purge(true);
				_shimNode.remove();
				_shimId = null;
				_shimNode = null;
			}

		}
	};
}