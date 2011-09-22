
if (!R8.IDE.View.target) { R8.IDE.View.target = {}; }

if (!R8.IDE.View.target.editor) {

	R8.IDE.View.target.editor = function(target) {
		var _target = target,
			_idPrefix = 'editor-target-',
			_panel = null,
			_contentWrapperNode = null,
			_contentNode = null,

			_initialized = false,

			_pendingDelete = {},

			_selectedItems = {},

//TODO: maybe put UI updates directly into model, else some central updater
			_ui = _target.get('ui'),
			_uiCookie = {},
			_cookieKey = '_uiCookie-'+_target.get('id'),
			_updateBackgroundCall = null,
			_statusPollerTimeout = null,

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

			//Plugin Bar Related
			_pluginBarNodeId = _idPrefix+_target.get('id')+'-plugin-bar',
			_pluginBarNode = null,
			_pluginContentNodeId = _idPrefix+_target.get('id')+'-plugin-content-wrapper',
			_pluginContentNode = null,
			_pluginContentOpen = false,
			_pluginInputNode = null,
			_activePlugin = '',
			_closedPluginContentHeight = 2,
			_pluginDefs = {
				'node-search': {
					'default_height': 80,
					'resizeable': false,
					'i18n': 'Nodes',
					'loadCallback': 'searchNodes',
					'events': {},
					'data': {},
					'blurCallback': 'searchNodesBlur',
					'renderCallback': 'renderNodeResults',
					'getData': function(key) {
						return this.data[key];
					},
					'setData': function(key,value) {
						this.data[key] = value;
					},
					'purgeData': function(key) {
						if(typeof(this.data[key]) !='undefined')
							delete(this.data[key]);
					}
				},
				'component-search': {
					'default_height': 80,
					'resizeable': false,
					'i18n': 'Components',
					'loadCallback': 'searchComponents',
					'renderCallback': 'renderComponentResults',
					'events': {},
					'data': {},
					'blurCallback': 'searchComponentsBlur',
					'getData': function(key) {
						return this.data[key];
					},
					'setData': function(key,value) {
						this.data[key] = value;
					},
					'purgeData': function(key) {
						if(typeof(this.data[key]) !='undefined')
							delete(this.data[key]);
					}
				},
				'assembly-search': {
					'default_height': 80,
					'resizeable': false,
					'i18n': 'Assemblies',
					'loadCallback': 'searchAssemblies',
					'renderCallback': 'renderAssemblyResults',
					'events': {},
					'data': {},
					'blurCallback': 'searchAssembliesBlur',
					'getData': function(key) {
						return this.data[key];
					},
					'setData': function(key,value) {
						this.data[key] = value;
					},
					'purgeData': function(key) {
						if(typeof(this.data[key]) !='undefined')
							delete(this.data[key]);
					}
				},
				'logging': {
					'default_height': 200,
					'resizeable': false,
					'i18n': 'Logging',
					'loadCallback': 'showLogs',
					'events': {},
					'data': {},
					'blurCallback': 'showLogsBlur',
					'getData': function(key) {
						return this.data[key];
					},
					'setData': function(key,value) {
						this.data[key] = value;
					},
					'purgeData': function(key) {
						if(typeof(this.data[key]) !='undefined')
							delete(this.data[key]);
					}
				},
				'notifications': {
					'default_height': 125,
					'resizeable': false,
					'i18n': 'Dependencies',
					'loadCallback': 'showNotifications',
					'events': {},
					'data': {},
					'blurCallback': 'showNotificationsBlur',
					'getData': function(key) {
						return this.data[key];
					},
					'setData': function(key,value) {
						this.data[key] = value;
					},
					'purgeData': function(key) {
						if(typeof(this.data[key]) !='undefined')
							delete(this.data[key]);
					}
				}
			},
			_plugins = {},

			_events = {};

		return {
			init: function() {
				_contentNode = R8.Utils.Y.one('#'+this.get('id'));
				_contentWrapperNode = R8.Utils.Y.one('#'+this.get('id')+'-wrapper');

				var editorContentRegion = R8.Utils.Y.one('#editor-panel-content').get('region');
				_contentNode.setStyles({'height':editorContentRegion.height,'width':editorContentRegion.width});

				_pluginBarNode = R8.Utils.Y.one('#'+_pluginBarNodeId);
				_pluginContentNode = R8.Utils.Y.one('#'+_pluginContentNodeId);

				_pluginInputNode = R8.Utils.Y.one('#'+this.get('id')+'-plugin-input');

				for(var p in _pluginDefs) {
					_plugins[p] = _pluginDefs[p];
					_plugins[p].node = R8.Utils.Y.one('#'+this.get('id')+'-plugin-'+p);
				}

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
/*
				var cmdbarDef = {
					'containerNode': _contentNode,
					'panel': _panel,
					'viewSpace': this
				};
				_cmdBar = new R8.Cmdbar2(cmdbarDef);
				_cmdBar.init();
*/

				this.startStatusPoller();
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

				_contentTpl = '<div id="'+id+'-wrapper" style="">\
									<div id="'+id+'" class="target-viewspace editor-target" data-id="'+_target.get('id')+'">\
									</div>\
									<div id="'+id+'-plugin-content-wrapper" class="plugin-content-wrapper">\
										<div id="node-list-container">\
											<div id="list-l-arrow-wrapper">\
												<div id="list-l-arrow"></div>\
											</div>\
											<div id="list-body-wrapper">\
												<div id="list-body">\
													<div id="component-foo" class="component-result selected">\
														<div class="body">\
															<div class="main-content">\
																<div class="php-icon"></div>\
																<div class="icon-divider"></div>\
																<div class="name-wrapper" title="PHP v5.3.8">PHP v5.3.8</div>\
															</div>\
															<div class="right-bar">\
																<div class="plus"></div>\
																<div class="implementations">\
																	<div class="chef"></div>\
																	<div class="puppet"></div>\
																</div>\
															</div>\
														</div>\
													</div>\
													<div id="component-bar" class="component-result">\
														<div class="body">\
															<div class="main-content">\
																<div class="rabbitmq-icon"></div>\
																<div class="icon-divider"></div>\
																<div class="name-wrapper" title="RabbitMQ Edge">RabbitMQ Edge</div>\
															</div>\
															<div class="right-bar">\
																<div class="plus"></div>\
																<div class="implementations">\
																	<div class="chef"></div>\
																	<div class="puppet"></div>\
																</div>\
															</div>\
														</div>\
													</div>\
												</div>\
											</div>\
											<div id="list-r-arrow-wrapper">\
												<div id="list-r-arrow"></div>\
											</div>\
										</div>\
									</div>\
									<div id="'+id+'-plugin-bar" class="plugin-bar">\
										<div id="'+id+'-plugin-input-content" class="input-content">\
											<div id="'+id+'-plugin-input-wrapper" class="plugin-input-wrapper">\
												<input id="'+id+'-plugin-input" name="plugin-input" type="text" class="plugin-input"/>\
											</div>\
										</div>\
										<div id="" class="divider"></div>\
										<div id="'+id+'-plugin-component-search" class="item-wrapper plugin">\
											<div id="" class="item">Components</div>\
										</div>\
										<div id="" class="divider"></div>\
										<div id="'+id+'-plugin-node-search" class="item-wrapper plugin">\
											<div id="" class="item">Nodes</div>\
										</div>\
										<div id="" class="divider"></div>\
										<div id="'+id+'-plugin-assembly-search" class="item-wrapper plugin">\
											<div id="" class="item">Assemblies</div>\
										</div>\
										<div id="'+id+'-plugin-logging" class="item-wrapper plugin">\
											<div id="" class="item">Logging</div>\
										</div>\
										<div id="'+id+'-plugin-notifications" class="item-wrapper plugin">\
											<div id="" class="item">Notifications</div>\
										</div>\
										<div id="" class="divider"></div>\
									</div>\
							</div>';

				_contentTpl = '<div id="'+id+'-wrapper" style="">\
									<div id="'+id+'" class="target-viewspace editor-target" data-id="'+_target.get('id')+'">\
									</div>\
									<div id="'+id+'-plugin-content-wrapper" class="plugin-content-wrapper">\
									</div>\
									<div id="'+id+'-plugin-bar" class="plugin-bar">\
										<div id="'+id+'-plugin-input-content" class="input-content">\
											<div id="'+id+'-plugin-input-wrapper" class="plugin-input-wrapper">\
												<form id="'+id+'-plugin-input-form">\
												<input id="'+id+'-plugin-input" name="plugin-input" type="text" class="plugin-input"/>\
												</form>\
											</div>\
										</div>\
										<div id="" class="divider"></div>\
										<div id="'+id+'-plugin-component-search" class="item-wrapper plugin">\
											<div id="" class="item">Components</div>\
										</div>\
										<div id="" class="divider"></div>\
										<div id="'+id+'-plugin-node-search" class="item-wrapper plugin">\
											<div id="" class="item">Nodes</div>\
										</div>\
										<div id="" class="divider"></div>\
										<div id="'+id+'-plugin-assembly-search" class="item-wrapper plugin">\
											<div id="" class="item">Assemblies</div>\
										</div>\
										<div id="" class="divider"></div>\
										<div id="'+id+'-plugin-logging" class="item-wrapper plugin">\
											<div id="" class="item">Logging</div>\
										</div>\
										<div id="" class="divider"></div>\
										<div id="'+id+'-plugin-notifications" class="item-wrapper plugin">\
											<div id="" class="item">Notifications</div>\
										</div>\
										<div id="" class="divider"></div>\
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

//DEBUG
//Temp hack b/c of issues with assembly node position
				if(typeof(nodePos) == 'undefined') {
					nodePos = {'top':50,'left':50};
				}
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
			swapNewNode: function(tempId,newId) {
				_items[newId] = _items[tempId];
				delete(_items[tempId]);
			},
			/*
			 * addDrag will make a item drag/droppable on a viewspace
			 * @method addDrag
			 * @param {string} An item id object, stored locally in _items
			 */
			addDrag: function(itemId) {
//DEBUG
//console.log('going to add drag to itemId:'+itemId);
//console.log(_items);
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
			setupPluginInputEvents: function() {

			},
			tearDownPluginInputEvents: function() {
				
			},
			setupEvents: function() {
				_events['item_click'] = R8.Utils.Y.delegate('click',this.updateSelectedItems,_contentNode,'.node',this);
//				_events['item_click'] = R8.Utils.Y.delegate('click',this.updateSelectedItems,_contentNode,'editor-target.item',this);
				_events['vspace_click'] = R8.Utils.Y.delegate('click',this.clearSelectedItems,'body','#'+_contentNode.get('id'));

				_events['port_mover'] = R8.Utils.Y.delegate('mouseover',this.portMover,_contentNode,'.port',this);
				_events['port_mout'] = R8.Utils.Y.delegate('mouseout',this.portMout,_contentNode,'.port',this);

				_events['plugin_click'] = R8.Utils.Y.delegate('click',this.pluginClick,'#'+this.get('id')+'-plugin-bar','.plugin',this);

				_events['editorResize'] = R8.IDE.on('editorResize',this.editorResize,this);

				_events['pluginInputFocus'] = _pluginInputNode.on('focus',function(e){

				},this);

				_events['pluginInputBlur'] = _pluginInputNode.on('blur',function(e){

				},this);

				_events['pluginInputFormSubmit'] = R8.Utils.Y.one('#'+this.get('id')+'-plugin-input-form').on('submit',function(e){
					var inputValue = _pluginInputNode.get('value');
					if (_activePlugin != '') {
						var item_list = _plugins[_activePlugin].getData('itemList');
						var match_list = [];
						for(var i in item_list) {
							if(R8.Utils.stringStartsWith(item_list[i].i18n,inputValue)) {
								match_list.push(item_list[i]);
							}
						}
						_plugins[_activePlugin].setData('renderList',match_list);
						this[_plugins[_activePlugin].renderCallback]();
					}

					_pluginInputNode.set('value','');
					e.halt();
					return false;
				},this);
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
			editorResize: function(e) {
				_contentNode.setStyles({'height':e.contentRegion.height,'width':e.contentRegion.width});

				var itemListContainerNode = R8.Utils.Y.one('#node-list-container');
				if(itemListContainerNode == null) return;

				var targetRegion = this.get('node').get('region');
				var targetWidth = targetRegion.width;
				itemListContainerNode.setStyle('width',targetWidth);
				R8.Utils.Y.one('#list-body-wrapper').setStyle('width',(targetWidth-80));

				var id=this.get('id');
				var resultListNode = R8.Utils.Y.one('#'+id+'-list-body');
				var resultListWidth = resultListNode.get('region').width;
				var limit = Math.floor(resultListWidth/138)+1;
				resultListNode.setStyle('width',((limit+1)*138));
			},
			portMout: function(e) {
				R8.Utils.Y.one('#port-modal').remove();
			},
			portMover: function(e) {
				var portNode = e.currentTarget,
					portNodeId = portNode.get('id'),
					portId = portNodeId.replace('port-',''),
					port = _target.get('port',portId),
					left = e.clientX - 240,
					top = e.clientY - 90;

				var modalHTML = '<div id="port-modal" class="port-modal" style="top: 0px; right: 0px;">\
									<div class="l-col">\
										<div class="corner tl"></div>\
										<div class="l-col-body"></div>\
										<div class="corner bl"></div>\
									</div>\
									<div id="port-modal-body" class="body">\
										<div class="header">'+port.get('name')+'</div>\
										<div class=".body-content">\
											<div>'+port.get('description')+'</div>\
										</div>\
									</div>\
									<div class="r-col">\
										<div class="corner tr"></div>\
										<div class="r-col-body"></div>\
										<div class="corner br"></div>\
									</div>\
							</div>';

				_contentNode.append(modalHTML);
			},

			addSelectedItem: function(itemId,data) {
				_selectedItems[itemId] = data;
				_items[itemId].get('node').setStyle('zIndex',51);
				_items[itemId].get('node').addClass('focus');
//				_items[itemId].get('node').addClass('hover');
			},
			clearSelectedItems: function(e) {
				for(itemId in _selectedItems) {
//					_items[itemId].get('node').removeClass('hover');
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

			startStatusPoller: function() {
				var _this = this;
				var fireStatusPoller = function() {
					_this.pollNodesStatus();
				}
				_statusPollerTimeout = setTimeout(fireStatusPoller,7500);
			},
			pollNodesStatus: function() {
				var _this=this;
				var fireStatusPoller = function() {
					_this.pollNodesStatus();
				}
				_statusPollerTimeout = setTimeout(fireStatusPoller,7500);

				if(_target.get('numNodes') == 0) return;

				var successCallback = function(ioId,responseObj) {
					eval("var response =" + responseObj.responseText);
					var nodesStatusList = response.application_target_get_nodes_status.content[0].data;
					_target.updateNodesStatus(nodesStatusList);
				}
				var params = {
					'cfg': {
						'data': ''
					},
					'callbacks': {
						'io:success': successCallback
					}
				};
				R8.Ctrl.call('target/get_nodes_status/'+_target.get('id'),params);
			},
			stopStatusPoller: function() {
				clearTimeout(_statusPollerTimeout);
				_statusPollerTimeout = null;
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
//DEBUG
console.log('inside of touchItems...');
console.log(item_list);
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
				return _selectedItems;
//				return _viewSpaces[_currentViewSpace].getSelectedItems();
			},
//---------------------------------------------
//Plugin Bar Related
//---------------------------------------------
			pluginClick: function(e) {
				var nodeId = e.currentTarget.get('id'),
					pluginId = nodeId.replace(this.get('id')+'-plugin-','');

				if(_pluginContentOpen && _activePlugin==pluginId) {
					_pluginContentNode.setStyles({'height':_closedPluginContentHeight+'px'});
					_pluginContentOpen = false;
					_plugins[pluginId].node.removeClass('active');
					return;
				} else {
					for(var p in _plugins) {
						_plugins[p].node.removeClass('active');
					}
				}

				if(_activePlugin != '') {
					var blurFunc = _plugins[_activePlugin].blurCallback;
					this[blurFunc]();
				}
//TODO: revisit, should be a plugin object with ref to target editor object
				var loadCallback = _plugins[pluginId].loadCallback;
				this[loadCallback]();

				_activePlugin = pluginId;
				var contentHeight = _plugins[pluginId].default_height;
				_pluginContentNode.setStyles({'height':contentHeight+'px'});
				_pluginContentOpen = true;

				_plugins[pluginId].node.addClass('active');
			},
			searchNodes: function() {
				this.searchNodesFocus();

				var _this=this;
				var successCallback = function(ioId,responseObj) {
					_this.setNodeSearchResults(ioId,responseObj);
				}
				var callbacks = {
//					'io:start' : cmdbar.loadedTabs[tabIndex].startSearch,
//					'io:end' : cmdbar.loadedTabs[tabIndex].endSearch,
//					'io:renderComplete' : renderCompleteCallback,
					'io:success': successCallback
				};
				var params = {
					'cfg':{
						'data': ''
					},
					'callbacks':callbacks
				}

				R8.Ctrl.call('node/search',params);
			},
			searchAssemblies: function() {
				this.searchAssembliesFocus();

				var _this=this;
				var successCallback = function(ioId,responseObj) {
					_this.setAssemblySearchResults(ioId,responseObj);
				}
				var callbacks = {
//					'io:start' : cmdbar.loadedTabs[tabIndex].startSearch,
//					'io:end' : cmdbar.loadedTabs[tabIndex].endSearch,
//					'io:renderComplete' : renderCompleteCallback,
					'io:success': successCallback
				};
				var params = {
					'cfg':{
						'data': ''
					},
					'callbacks':callbacks
				}

				R8.Ctrl.call('assembly/search',params);
			},
			searchComponents: function() {
//				var renderCompleteCallback = function() {
//					cmdbar.loadedTabs[tabIndex].initSlider(cmdbar.loadedTabs[tabIndex].name,cmdbar);
//				}
				this.searchComponentsFocus();

				var _this=this;
				var successCallback = function(ioId,responseObj) {
					_this.setComponentSearchResults(ioId,responseObj);
				}
				var callbacks = {
//					'io:start' : cmdbar.loadedTabs[tabIndex].startSearch,
//					'io:end' : cmdbar.loadedTabs[tabIndex].endSearch,
//					'io:renderComplete' : renderCompleteCallback,
					'io:success': successCallback
				};
				var params = {
					'cfg':{
						'data': ''
					},
					'callbacks':callbacks
				}

				R8.Ctrl.call('component/search',params);
			},
			searchComponentsBlur: function() {
				_plugins['component-search']['events']['key_press'].detach();
				delete(_plugins['component-search']['events']['key_press']);
				_pluginContentNode.set('innerHTML','');
				_plugins['component-search'].getData('compDDel').destroy();
				_plugins['component-search'].purgeData('compDDel');
			},
			searchComponentsFocus: function() {
				_pluginInputNode.focus();

				var id=this.get('id');
				var targetRegion = this.get('node').get('region');
				var targetWidth = targetRegion.width;
				var listTpl = '<div id="node-list-container" style="width:'+targetWidth+'px;">\
								 <div id="list-l-arrow-wrapper">\
									<div id="list-l-arrow"></div>\
								 </div>\
								<div id="list-body-wrapper" style="width:'+(targetWidth-80)+'px;">\
									<div id="'+id+'-list-body" style="width:'+(targetWidth-80)+'px;">\
									</div>\
								</div>\
								<div id="list-r-arrow-wrapper">\
									<div id="list-r-arrow"></div>\
								</div>\
							</div>';

				_pluginContentNode.set('innerHTML',listTpl);
				var _this=this;
				YUI().use("node", function(Y){
					_plugins['component-search']['events']['key_press'] = Y.one('document').on("keypress", function(e){
						if (e.keyCode == 37) {
							var selectedIndex = _plugins['component-search'].getData('selectedIndex');
							_plugins['component-search'].setData('oldSelectedIndex',selectedIndex);
							selectedIndex = (selectedIndex==0) ? 0 : selectedIndex=selectedIndex-1;
							_plugins['component-search'].setData('selectedIndex',selectedIndex);
							this.renderComponentResults();
							e.halt();
						}
						else if (e.keyCode == 39) {
							var selectedIndex = _plugins['component-search'].getData('selectedIndex');
							var maxIndex = _plugins['component-search'].getData('renderList').length-1;

							if ((selectedIndex + 1) > maxIndex) {
								e.halt();
								return;
							}
							selectedIndex = (selectedIndex==maxIndex) ? maxIndex : selectedIndex=selectedIndex+1;
							_plugins['component-search'].setData('selectedIndex',selectedIndex);
							this.renderComponentResults();
							e.halt();
						} else if(e.keyCode == 35) {
							var maxIndex = _plugins['component-search'].getData('renderList').length-1;
							_plugins['component-search'].setData('selectedIndex',maxIndex);
							this.renderComponentResults();
						} else if(e.keyCode == 36) {
							_plugins['component-search'].setData('selectedIndex',0);
							this.renderComponentResults();
						}
					},_this);
				});
				this.setupSearchComponentDD();
			},
			searchNodesBlur: function() {
				_plugins['node-search']['events']['key_press'].detach();
				delete(_plugins['node-search']['events']['key_press']);
				_pluginContentNode.set('innerHTML','');
				_plugins['node-search'].getData('nodeDDel').destroy();
				_plugins['node-search'].purgeData('nodeDDel');
			},
			searchNodesFocus: function() {
				_pluginInputNode.focus();

				var id=this.get('id');
				var listTpl = '<div id="node-list-container">\
								 <div id="list-l-arrow-wrapper">\
									<div id="list-l-arrow"></div>\
								 </div>\
								<div id="list-body-wrapper">\
									<div id="'+id+'-list-body">\
									</div>\
								</div>\
								<div id="list-r-arrow-wrapper">\
									<div id="list-r-arrow"></div>\
								</div>\
							</div>';

				_pluginContentNode.set('innerHTML',listTpl);
				var _this=this;
				YUI().use("node", function(Y){
					_plugins['node-search']['events']['key_press'] = Y.one('document').on("keypress", function(e){
						if (e.keyCode == 37) {
							var selectedIndex = _plugins['node-search'].getData('selectedIndex');
							_plugins['node-search'].setData('oldSelectedIndex',selectedIndex);
							selectedIndex = (selectedIndex==0) ? 0 : selectedIndex=selectedIndex-1;
							_plugins['node-search'].setData('selectedIndex',selectedIndex);
							this.renderNodeResults();
							e.halt();
						}
						else if (e.keyCode == 39) {
							var selectedIndex = _plugins['node-search'].getData('selectedIndex');
							var maxIndex = _plugins['node-search'].getData('renderList').length-1;

							if ((selectedIndex + 1) > maxIndex) {
								e.halt();
								return;
							}
							selectedIndex = (selectedIndex==maxIndex) ? maxIndex : selectedIndex=selectedIndex+1;
							_plugins['node-search'].setData('selectedIndex',selectedIndex);
							this.renderNodeResults();
							e.halt();
						} else if(e.keyCode == 35) {
							var maxIndex = _plugins['node-search'].getData('renderList').length-1;
							_plugins['node-search'].setData('selectedIndex',maxIndex);
							this.renderNodeResults();
						} else if(e.keyCode == 36) {
							_plugins['node-search'].setData('selectedIndex',0);
							this.renderNodeResults();
						}
					},_this);
				});
				this.setupSearchNodeDD();
			},
			searchAssembliesBlur: function() {
				_plugins['assembly-search']['events']['key_press'].detach();
				delete(_plugins['assembly-search']['events']['key_press']);
				_pluginContentNode.set('innerHTML','');
				_plugins['assembly-search'].getData('assemblyDDel').destroy();
				_plugins['assembly-search'].purgeData('assemblyDDel');
			},
			searchAssembliesFocus: function() {
				_pluginInputNode.focus();

				var id=this.get('id');
				var targetRegion = this.get('node').get('region');
				var listTpl = '<div id="node-list-container">\
								 <div id="list-l-arrow-wrapper">\
									<div id="list-l-arrow"></div>\
								 </div>\
								<div id="list-body-wrapper">\
									<div id="'+id+'-list-body">\
									</div>\
								</div>\
								<div id="list-r-arrow-wrapper">\
									<div id="list-r-arrow"></div>\
								</div>\
							</div>';

				_pluginContentNode.set('innerHTML',listTpl);
				var _this=this;
				YUI().use("node", function(Y){
					_plugins['assembly-search']['events']['key_press'] = Y.one('document').on("keypress", function(e){
						if (e.keyCode == 37) {
							var selectedIndex = _plugins['assembly-search'].getData('selectedIndex');
							_plugins['assembly-search'].setData('oldSelectedIndex',selectedIndex);
							selectedIndex = (selectedIndex==0) ? 0 : selectedIndex=selectedIndex-1;
							_plugins['assembly-search'].setData('selectedIndex',selectedIndex);
							this.renderAssemblyResults();
							e.halt();
						}
						else if (e.keyCode == 39) {
							var selectedIndex = _plugins['assembly-search'].getData('selectedIndex');
							var maxIndex = _plugins['assembly-search'].getData('renderList').length-1;

							if ((selectedIndex + 1) > maxIndex) {
								e.halt();
								return;
							}
							selectedIndex = (selectedIndex==maxIndex) ? maxIndex : selectedIndex=selectedIndex+1;
							_plugins['assembly-search'].setData('selectedIndex',selectedIndex);
							this.renderAssemblyResults();
							e.halt();
						} else if(e.keyCode == 35) {
							var maxIndex = _plugins['assembly-search'].getData('renderList').length-1;
							_plugins['assembly-search'].setData('selectedIndex',maxIndex);
							this.renderComponentResults();
						} else if(e.keyCode == 36) {
							_plugins['assembly-search'].setData('selectedIndex',0);
							this.renderAssemblyResults();
						}
					},_this);
				});
				this.setupSearchAssembliesDD();
			},
			setComponentSearchResults: function(ioId,responseObj) {
				eval("var response =" + responseObj.responseText);
				var component_list = response.application_component_search.content[0].data;

				var id=this.get('id');
				var resultListNode = R8.Utils.Y.one('#'+id+'-list-body');
				var tmpStr = resultListNode.getStyle('width');
				var resultListWidth = tmpStr.replace('px','');
				var limit = Math.floor(resultListWidth/138)+1;

				resultListNode.setStyle('width',((limit+1)*138));

				_plugins['component-search'].setData('renderList',component_list);
				_plugins['component-search'].setData('itemList',component_list);
				_plugins['component-search'].setData('selectedIndex',0);
				_plugins['component-search'].setData('oldSelectedIndex',0);
				_plugins['component-search'].setData('renderLimit',limit);

				this.renderComponentResults();
			},
			setNodeSearchResults: function(ioId,responseObj) {
				eval("var response =" + responseObj.responseText);
				var node_list = response.application_node_search.content[0].data;

				var id=this.get('id');
				var resultListNode = R8.Utils.Y.one('#'+id+'-list-body');
				var tmpStr = resultListNode.getStyle('width');
				var resultListWidth = tmpStr.replace('px','');
				var limit = Math.floor(resultListWidth/138)+1;

				resultListNode.setStyle('width',((limit+1)*138));

				_plugins['node-search'].setData('renderList',node_list);
				_plugins['node-search'].setData('itemList',node_list);
				_plugins['node-search'].setData('selectedIndex',0);
				_plugins['node-search'].setData('oldSelectedIndex',0);
				_plugins['node-search'].setData('renderLimit',limit);

				this.renderNodeResults();
			},
			setAssemblySearchResults: function(ioId,responseObj) {
				eval("var response =" + responseObj.responseText);
				var assembly_list = response.application_assembly_search.content[0].data;

				var id=this.get('id');
				var resultListNode = R8.Utils.Y.one('#'+id+'-list-body');
				var tmpStr = resultListNode.getStyle('width');
				var resultListWidth = tmpStr.replace('px','');
				var limit = Math.floor(resultListWidth/138)+1;

				resultListNode.setStyle('width',((limit+1)*138));

				_plugins['assembly-search'].setData('renderList',assembly_list);
				_plugins['assembly-search'].setData('itemList',assembly_list);
				_plugins['assembly-search'].setData('selectedIndex',0);
				_plugins['assembly-search'].setData('oldSelectedIndex',0);
				_plugins['assembly-search'].setData('renderLimit',limit);

				this.renderAssemblyResults();
			},
			renderComponentResults: function() {
				var id=this.get('id');
				var resultListNode = R8.Utils.Y.one('#'+id+'-list-body');

				var itemList = _plugins['component-search'].getData('renderList');
				if (itemList.length == 0) {
					resultListNode.set('innerHTML','');
					return;
				}

				var selectedIndex = _plugins['component-search'].getData('selectedIndex');
				var renderLimit = _plugins['component-search'].getData('renderLimit');
				var renderStartIndex = selectedIndex - (renderLimit-2);
				renderStartIndex = (renderStartIndex < 0) ? 0 : renderStartIndex;
				var renderEndIndex = (renderLimit) + renderStartIndex;

/*
				if(!this.componentSearchShiftNeeded()) {
					resultListNode.get('children').item(oldSelectedIndex).removeClass('selected');
					resultListNode.get('children').item(selectedIndex).addClass('selected');
					return;
				}
*/
				resultListNode.set('innerHTML','');
				for(var i=renderStartIndex; i < renderEndIndex; i++) {
					if(typeof(itemList[i]) == 'undefined') continue;
					resultListNode.append(R8.Rtpl['component_library_search']({'component':itemList[i]}));
				}
				resultListNode.get('children').item((selectedIndex - renderStartIndex)).addClass('selected');
			},
			renderNodeResults: function() {
				var id=this.get('id');
				var resultListNode = R8.Utils.Y.one('#'+id+'-list-body');

				var itemList = _plugins['node-search'].getData('renderList');
				if (itemList.length == 0) {
					resultListNode.set('innerHTML','');
					return;
				}

				var selectedIndex = _plugins['node-search'].getData('selectedIndex');
				var renderLimit = _plugins['node-search'].getData('renderLimit');
				var renderStartIndex = selectedIndex - (renderLimit-2);
				renderStartIndex = (renderStartIndex < 0) ? 0 : renderStartIndex;
				var renderEndIndex = (renderLimit) + renderStartIndex;

				resultListNode.set('innerHTML','');
				for(var i=renderStartIndex; i < renderEndIndex; i++) {
					if(typeof(itemList[i]) == 'undefined') continue;
					resultListNode.append(R8.Rtpl['node_library_search']({'node':itemList[i]}));
				}
				resultListNode.get('children').item((selectedIndex - renderStartIndex)).addClass('selected');
			},
			renderAssemblyResults: function() {
				var id=this.get('id');
				var resultListNode = R8.Utils.Y.one('#'+id+'-list-body');

				var itemList = _plugins['assembly-search'].getData('renderList');
				if (itemList.length == 0) {
					resultListNode.set('innerHTML','');
					return;
				}

				var selectedIndex = _plugins['assembly-search'].getData('selectedIndex');
				var renderLimit = _plugins['assembly-search'].getData('renderLimit');
				var renderStartIndex = selectedIndex - (renderLimit-2);
				renderStartIndex = (renderStartIndex < 0) ? 0 : renderStartIndex;
				var renderEndIndex = (renderLimit) + renderStartIndex;

				resultListNode.set('innerHTML','');
				for(var i=renderStartIndex; i < renderEndIndex; i++) {
					if(typeof(itemList[i]) == 'undefined') continue;
					resultListNode.append(R8.Rtpl['assembly_library_search']({'assembly':itemList[i]}));
				}
				resultListNode.get('children').item((selectedIndex - renderStartIndex)).addClass('selected');
			},
			setupSearchComponentDD: function(){
				var id=this.get('id');
				YUI().use('dd-delegate', 'dd-proxy', 'node', 'dd-drop-plugin', function(Y){
					var compDDel = new Y.DD.Delegate({
						cont: '#'+id+'-list-body',
						nodes: 'div.component-result',
					});
					_plugins['component-search'].setData('compDDel',compDDel);
					_plugins['component-search'].getData('compDDel').dd.plug(Y.Plugin.DDProxy, {
						moveOnEnd: false,
						borderStyle: false,
					});

					_plugins['component-search'].getData('compDDel').on('drag:mouseDown', function(e){
						var componentType = this.get('currentNode').get('children').item(0).getAttribute('data-type');
						componentType='component';
						var targetNode = Y.one('#'+id);

						if(componentType == 'composite') {
							var dropGroup = 'dg-node-assembly';
							if(!vspaceNode.hasClass('yui3-dd-drop')) {
								var drop = new Y.DD.Drop({node:vspaceNode});
								drop.addToGroup([dropGroup]);
								drop.on('drop:enter',function(e){
								});
								drop.on('drop:hit',function(e){
									var dropNode = e.drop.get('node');
									var compNode = e.drag.get('dragNode').get('children').item(0);
									var componentId = compNode.getAttribute('data-id');

									var panelOffset = cmdbar.get('viewSpace').get('node').get('region').left;
									var assemblyLeftPos = e.drag.get('dragNode').get('region').left-panelOffset;
//DEBUG
//									R8.Workspace.addAssemblyToViewspace(componentId,'node',assemblyLeftPos,dropNode);
//									cmdbar.get('viewSpace').addAssemblyToViewspace(componentId,'node',assemblyLeftPos,dropNode);
								});
							}
						} else {
							var dropGroup = 'dg-component';
							var dropList = Y.all('#'+targetNode.get('id')+' div.'+dropGroup);

							dropList.each(function(){
								if(!this.hasClass('yui3-dd-drop')) {
									var drop = new Y.DD.Drop({node:this});
									drop.addToGroup([dropGroup]);
									drop.on('drop:enter',function(e){
									});
									drop.on('drop:hit',function(e){
										var dropNode = e.drop.get('node');
										var compNode = e.drag.get('dragNode').get('children').item(0);
										var componentId = compNode.getAttribute('data-id');

										//DEBUG
										var tempId = Y.guid();
										var newComponentDef = {
											'id': tempId,
											'node_id': dropNode.getAttribute('data-id'),
											'component_id': componentId,
											'ui': {}
										};
										var e = {
											'componentDef': newComponentDef
										};
										R8.IDE.fire('node-'+newComponentDef.node_id+'-component-add',e);
//DEBUG
//console.log(e);
									});
								}
							});
						}
					});

					_plugins['component-search'].getData('compDDel').on('drag:start', function(e){
						var drag = this.get('dragNode'), c = this.get('currentNode');
						drag.set('innerHTML',c.get('innerHTML'));
						drag.setAttribute('class', c.getAttribute('class')+' selected');
						this.dd.addToGroup('dg-component');
						drag.setStyles({
							opacity: .5,
						});
					});
				});
			},
			setupSearchNodeDD: function() {
				var id=this.get('id');
				YUI().use('dd-delegate', 'dd-proxy', 'dd-drop', 'dd-drop-plugin', 'node', function(Y){
					var nodeDDel = new Y.DD.Delegate({
						cont: '#'+id+'-list-body',
						nodes: 'div.component-result',
					});
					_plugins['node-search'].setData('nodeDDel',nodeDDel);

					_plugins['node-search'].getData('nodeDDel').dd.plug(Y.Plugin.DDProxy, {
						moveOnEnd: false,
						borderStyle: false,
					});

					_plugins['node-search'].getData('nodeDDel').on('drag:start', function(e){
						var drag = this.get('dragNode'), c = this.get('currentNode');
						drag.set('innerHTML',c.get('innerHTML'));
						drag.setAttribute('class', c.getAttribute('class')+' selected');
						this.dd.addToGroup('viewspace_drop');
						drag.setStyles({
							opacity: .5,
							zIndex: 1000
						});
					});

					_plugins['node-search'].getData('nodeDDel').on('drag:mouseDown', function(e){
						var dropGroup = 'dg-node';

						var targetViewNode = Y.one('#'+id);
						if (!targetViewNode.hasClass('yui3-dd-drop')) {
							var targetNodeDrop = new Y.DD.Drop({
								node: targetViewNode
							});
							targetNodeDrop.addToGroup([dropGroup]);

							targetNodeDrop.on('drop:enter', function(e){
							});
							targetNodeDrop.on('drop:hit', function(e){
								var drop = e.drop.get('node');
								var dragClone = e.drag.get('dragNode').get('children').item(0);
//								var dragClone = e.drag.get('dragNode');
								var itemNodeId = dragClone.get('id');
								var tempId = Y.guid();
								dragClone.set('id', tempId);

								var contentXY = _contentNode.getXY();
								var dragXY = dragClone.getXY();
								var dragRegion = dragClone.get('region');
								var dragLeft = dragXY[0] - (contentXY[0]);
								var dragTop = dragXY[1] - (contentXY[1]);

								dragClone.setStyles({
									'top': dragTop + 'px',
									'left': dragLeft + 'px'
								});

								var newNodeDef = {
									'id': tempId,
								//	'id': dragClone.getAttribute('data-id'),
									'status': 'temp',
									'is_deployed': false,
									'node_id': dragClone.getAttribute('data-id'),
									'data-model': 'node',
									'name': dragClone.getAttribute('data-name'),
									'target': drop.getAttribute('data-id'),
									'os_type': dragClone.getAttribute('data-os-type'),
									'components': [],
									'ui': {}
								};
								newNodeDef.ui['target-'+drop.getAttribute('data-id')] = {
									'top': dragTop + 'px',
									'left': dragLeft + 'px'
								};
								var e = {
									'nodeDef': newNodeDef
								};
								R8.IDE.fire('target-'+newNodeDef.target+'-node-add',e);
							});
						}
					});
				});
			},
			setupSearchAssembliesDD: function(){
				var id=this.get('id');
				YUI().use('dd-delegate', 'dd-proxy', 'node', 'dd-drop-plugin', function(Y){
					var assemblyDDel = new Y.DD.Delegate({
						cont: '#'+id+'-list-body',
						nodes: 'div.component-result',
					});
					_plugins['assembly-search'].setData('assemblyDDel',assemblyDDel);
					_plugins['assembly-search'].getData('assemblyDDel').dd.plug(Y.Plugin.DDProxy, {
						moveOnEnd: false,
						borderStyle: false,
					});

					_plugins['assembly-search'].getData('assemblyDDel').on('drag:mouseDown', function(e){
						var componentType = this.get('currentNode').get('children').item(0).getAttribute('data-type');
						componentType='composite';
						var targetNode = Y.one('#'+id);

						if(componentType == 'composite') {
							var dropGroup = 'dg-node-assembly';
							if(!targetNode.hasClass('yui3-dd-drop')) {
								var drop = new Y.DD.Drop({node:targetNode});
								drop.addToGroup([dropGroup]);
								drop.on('drop:enter',function(e){
								});
								drop.on('drop:hit',function(e){
									var dropNode = e.drop.get('node');
									var compNode = e.drag.get('dragNode').get('children').item(0);
									var componentId = compNode.getAttribute('data-id');

//									var panelOffset = cmdbar.get('viewSpace').get('node').get('region').left;
									var panelOffset = targetNode.get('region').left;
									var assemblyLeftPos = e.drag.get('dragNode').get('region').left-panelOffset;

									//DEBUG
									var tempId = Y.guid();
/*
									var newComponentDef = {
										'id': tempId,
										'node_id': dropNode.getAttribute('data-id'),
										'component_id': componentId,
										'ui': {}
									};
*/
									var e = {
										'componentId': componentId,
//										'componentDef': newComponentDef,
										'assemblyLeftPos': assemblyLeftPos
									};
									R8.IDE.fire('target-'+_target.get('id')+'-assembly-add',e);
//DEBUG
//console.log(e);
//DEBUG
//									R8.Workspace.addAssemblyToViewspace(componentId,'node',assemblyLeftPos,dropNode);
//									cmdbar.get('viewSpace').addAssemblyToViewspace(componentId,'node',assemblyLeftPos,dropNode);
								});
							}
						} else {
							var dropGroup = 'dg-component';
							var dropList = Y.all('#'+targetNode.get('id')+' div.'+dropGroup);

							dropList.each(function(){
								if(!this.hasClass('yui3-dd-drop')) {
									var drop = new Y.DD.Drop({node:this});
									drop.addToGroup([dropGroup]);
									drop.on('drop:enter',function(e){
									});
									drop.on('drop:hit',function(e){
										var dropNode = e.drop.get('node');
										var compNode = e.drag.get('dragNode').get('children').item(0);
										var componentId = compNode.getAttribute('data-id');

										//DEBUG
										var tempId = Y.guid();
										var newComponentDef = {
											'id': tempId,
											'node_id': dropNode.getAttribute('data-id'),
											'component_id': componentId,
											'ui': {}
										};
										var e = {
											'componentDef': newComponentDef
										};
										R8.IDE.fire('node-'+newComponentDef.node_id+'-component-add',e);
//DEBUG
//console.log(e);
									});
								}
							});
						}
					});

					_plugins['assembly-search'].getData('assemblyDDel').on('drag:start', function(e){
						var drag = this.get('dragNode'), c = this.get('currentNode');
						drag.set('innerHTML',c.get('innerHTML'));
						drag.setAttribute('class', c.getAttribute('class')+' selected');
						this.dd.addToGroup('dg-node-assembly');
						drag.setStyles({
							opacity: .5,
						});
					});
				});
			},
			showLogsBlur: function() {
				this.stopLogPoller();
			},
			showLogs: function() {
				var id=this.get('id');
				var targetRegion = this.get('node').get('region');
				var targetWidth = targetRegion.width;
				var listTpl = '<div id="node-list-container" style="width:'+targetWidth+'px;">\
								 <div id="list-l-arrow-wrapper">\
									<div id="list-l-arrow"></div>\
								 </div>\
								<div id="list-body-wrapper" style="width:'+(targetWidth-80)+'px;">\
									<div id="'+id+'-list-body" style="width:'+(targetWidth-80)+'px;">\
									</div>\
								</div>\
								<div id="list-r-arrow-wrapper">\
									<div id="list-r-arrow"></div>\
								</div>\
							</div>';

				var contentTpl = '<div id="'+id+'-logger-wrapper" style="width:'+targetWidth+'px; height: 197px; margin-top: 3px; background-color: #D8DBE3">\
									<div id="'+id+'-logging-header" class="view-header">\
										<select id="'+id+'-logging-available-nodes" name="'+id+'-logger-available-nodes">\
											<option value="">-Node List-</option>\
										</select>\
									</div>\
									<div id="'+id+'-logging-content" style="overflow-y: scroll; background-color: #FFFFFF; height: 173px;">\
									</div>\
								</div>';

				_pluginContentNode.set('innerHTML',contentTpl);

				_plugins['logging'].setData('nodeSelect',document.getElementById(id+'-logging-available-nodes'));
				_plugins['logging'].setData('nodeSelectYUI',R8.Utils.Y.one('#'+id+'-logging-available-nodes'));

				var node_list = _target.get('nodes');
				var optionsStr = '';
				for(var n in node_list) {
					optionsStr = optionsStr + '<option value="'+node_list[n].get('id')+'">'+node_list[n].get('name')+'</option>';
				}
				_plugins['logging'].getData('nodeSelectYUI').append(optionsStr);

				var _this = this;
				_plugins['logging'].getData('nodeSelect').onchange = function() {
					_this.changeLogFocus(this.options[this.selectedIndex].value);
				}

				if(typeof(_plugins['logging'].getData('logContent')) == 'undefined')
					_plugins['logging'].setData('logContent',{});

				this.startLogPoller();
			},
			changeLogFocus: function(nodeId) {
				_plugins['logging'].setData('pluginActiveLogId',nodeId);
			},
			startLogPoller: function() {
				var _this = this;
				var fireLogPoller = function() {
					_this.pollLog();
				}
				_plugins['logging'].setData('logPollerTimeout',setTimeout(fireLogPoller,2000));
			},
			pollLog: function() {
				var _this=this;
				var fireLogPoller = function() {
					_this.pollLog();
				}
				_plugins['logging'].setData('logPollerTimeout',setTimeout(fireLogPoller,2500));

				var currentNodeId = _plugins['logging'].getData('pluginActiveLogId');

				if(currentNodeId == '' || currentNodeId == null) return;

				var setLogsCallback = function(ioId,responseObj) {
					eval("var response =" + responseObj.responseText);
					var logContent = response.application_task_get_logs.content[0].data;

					_this.setLogContent(logContent);
//					contentNode.set('innerHTML',log_content);
//					contentNode.append(log_content);
				}
				var params = {
					'cfg': {
						'data': 'node_id='+currentNodeId
					},
					'callbacks': {
						'io:success': setLogsCallback
					}
				};
				R8.Ctrl.call('task/get_logs',params);
			},
			stopLogPoller: function() {
				clearTimeout(_plugins['logging'].getData('logPollerTimeout'));
				_plugins['logging'].setData('logPollerTimeout',null);
			},
			setLogContent: function(logContents) {
				var logContent = _plugins['logging'].getData('logContent');
				for(var l in logContents) {
					logContent[l] = logContents[l];
				}
				_plugins['logging'].setData('logContent',logContent);

				var currentNodeId = _plugins['logging'].getData('pluginActiveLogId');
				this.renderLogContents(currentNodeId);

				if(typeof(logContent[currentNodeId]) == 'undefined' || logContent[currentNodeId].complete == true) this.stopLogPoller();
			},
			renderLogContents: function(nodeId) {
				var logContent = _plugins['logging'].getData('logContent');
				var currentNodeId = _plugins['logging'].getData('pluginActiveLogId');
				if(typeof(logContent[currentNodeId]) == 'undefined') return;

				var logContentNode = R8.Utils.Y.one('#'+this.get('id')+'-logging-content');

				for(var i in logContent[currentNodeId]['log_segments']) {
					var logSegment = logContent[currentNodeId]['log_segments'][i];

					switch(logSegment.type) {
						case "debug":
						case "info":
							var logTpl = '<div style="width: 100%; height: 17px; white-space: nowrap>'+logSegment.line+'</div>';
							break;
						case "error":
							if(typeof(logSegment.error_file_ref) == 'undefined' || logSegment.error_file_ref == null || logSegment.error_file_ref == '') {
								var logTpl = '<div style="color: red; width: 100%; height: 17px; white-space: nowrap">'+logSegment.error_detail+'</div>';
							} else {
/*
							R8.IDE.openFile({
								'id': leafObjectId,
								'name': leafLabel,
								'type': 'file'
							});
*/
//								var logTpl = '<div style="color: red; width: 100%; height: 17px; white-space: nowrap">'+logSegment.error_detail+' in file <a href="javascript:R8.IDE.openFile({id:\''+logSegment.error_file_ref.file_id+'\',name:\''+logSegment.error_file_ref.file_name+'\',type:\'file\',\'line\':'+logSegment.error_file_ref.error_line_num+'});">'+logSegment.error_file_ref.file_name+'</a></div>';
								var logTpl = '<div style="color: red; width: 100%; height: 17px; white-space: nowrap">'+logSegment.error_detail+' in file <a href="javascript:R8.IDE.openFile({id:\''+logSegment.error_file_ref.file_id+'\',name:\''+logSegment.error_file_ref.file_name+'\',type:\'file\'});">'+logSegment.error_file_ref.file_name+'</a></div>';
							}

							break;
					}
					logContentNode.append(logTpl);
				}
				var contentDiv = document.getElementById(logContentNode.get('id'));
				contentDiv.scrollTop = contentDiv.scrollHeight;
			},
			showNotifications: function() {
				var id=this.get('id');
				var targetRegion = this.get('node').get('region');
				var targetWidth = targetRegion.width;

				var contentTpl = '<div id="'+id+'-notifications-wrapper" style="width:'+targetWidth+'px; height: 122px; margin-top: 3px; background-color: #D8DBE3">\
									<div id="'+id+'-notifications-header" class="view-header">\
									</div>\
									<div id="'+id+'-notifications-content" class="notification-content" style="overflow-y: scroll; background-color: #FFFFFF; height: 98px;">\
									</div>\
								</div>';

				_pluginContentNode.set('innerHTML',contentTpl);
				_plugins['notifications'].setData('notificationContentNode',R8.Utils.Y.one('#'+this.get('id')+'-notifications-content'));
				this.getNotifications();
			},
			showNotificationsFocus: function() {
				_plugins['notifications'].setData(
					'itemMouseEnter',
					R8.Utils.Y.delegate(
						'mouseenter',
						this.notificationMouseEnter,
						_plugins['notifications'].getData('notificationContentNode'),
						'.item',
						this
					)
				);
				_plugins['notifications'].setData(
					'itemMouseLeave',
					R8.Utils.Y.delegate(
						'mouseleave',
						this.notificationMouseLeave,
						_plugins['notifications'].getData('notificationContentNode'),
						'.item',
						this
					)
				);
				
			},
			showNotificationsBlur: function() {
				_plugins['notifications'].getData('itemMouseLeave').detach();
				_plugins['notifications'].purgeData('itemMouseLeave');
				_plugins['notifications'].getData('itemMouseEnter').detach();
				_plugins['notifications'].purgeData('itemMouseEnter');
			},
			notificationMouseLeave: function(e) {
				var nodeId = e.currentTarget.getAttribute('data-node-id');
				_items[nodeId].get('node').removeClass('focus');
			},
			notificationMouseEnter: function(e) {
				var nodeId = e.currentTarget.getAttribute('data-node-id');
				_items[nodeId].get('node').addClass('focus');
			},
			getNotifications: function() {
				this.showNotificationsFocus();
				var _this=this;
				var	successCallback = function(ioId,responseObj) {
						eval("var response =" + responseObj.responseText);
						//TODO: revisit once controllers are reworked for cleaner result package
						var notification_content = response['application_target_get_warnings']['content'][0]['data'];

						_plugins['notifications'].setData('notificationContent',notification_content);
						_plugins['notifications'].setData('renderContent',notification_content);
						_this.renderNotifications();
					}
				var params = {
					'callbacks': {
						'io:success':successCallback
					}
				};
				R8.Ctrl.call('target/get_warnings/'+_target.get('id'),params);
			},
			renderNotifications: function() {
				var notifcationContent = _plugins['notifications'].getData('renderContent');
				var notificationContentNode = _plugins['notifications'].getData('notificationContentNode');
				notificationContentNode.set('innerHTML','');
				notificationContentNode.append(R8.Rtpl.notification_list_ide({'notification_list':notifcationContent}));
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