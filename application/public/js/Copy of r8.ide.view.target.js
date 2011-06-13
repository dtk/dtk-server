
if (!R8.IDE.View.target) {

	R8.IDE.View.target = function(view) {
		var _view = view,
			_id = _view.id,
			_panel = _view.panel,

			_contentTpl = '<div id="'+_panel.get('id')+'-'+_view.id+'" class="target-viewspace"></div>',
			_contentNode = null,

			_initialized = false,


			_workspaceDef = null,
			//from old file
			_ui = _def.object.ui,
			_uiCookie = {},
			_cookieKey = '_uiCookie-'+_id,
			_updateBackgroundCall = null,

//			_type = _def['type'],
//			_node = R8.Utils.Y.one('#viewspace'),   //now contentNode

			_items = {},

			_draggableItems = {},
			_selectedItems = {},
			_itemPosUpdateList = {},

			_isWorkspaceReady = false,

//TODO: revisit when implementing user/system settings more
			_userSettings = {showPorts: true,showLinks:true},

			_links = null,
			_links2 = {},
			_linkRenderList = [],

			_events = {};

		return {
			init: function() {
				_contentNode = R8.Utils.Y.one('#'+_panel.get('id')+'-'+_view.id);

				this.getWorkspaceDef();

				_initialized = true;
			},
			render: function() {
				return _contentTpl;
			},
			resize: function() {
				if(!_initialized) return;

/*
				var contentHeight = _node.get('region').height - _headerNode.get('region').height;
				_contentNode.setStyles({'height':contentHeight,'width':_node.get('region').width,'backgroundColor':'#FFFFFF'});
*/
			},
			get: function(key) {
				switch(key) {
					case "name":
						return _view.name;
						break;
					case "type":
						return _view.type;
						break;
				}
			},
			focus: function() {
				this.resize();
				_contentNode.setStyle('display','block');
			},
			blur: function() {
				_contentNode.setStyle('display','none');
			},
			close: function() {
				_contentNode.purge(true);
				_contentNode.remove();
			},

//------------------------------------------------------
//these are target view specific functions
//------------------------------------------------------
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
					var workspaceDef = response.application_target_get_view_items.content[0].data;

					that.initWorkspace(workspaceDef);
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
				R8.Ctrl.call('target/get_view_items/'+_view.id,params);
			},
			initWorkspace: function(workspaceDef) {
				_workspaceDef = workspaceDef;

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
					_isWorkspaceReady = true;
				});

				if(typeof(_workspaceDef.items) != 'undefined') {
					this.addItems();
					this.retrieveLinks(_workspaceDef.items);
				}

				this.refreshNotifications();

			},
			isWorkspaceReady: function() {
				return _isWorkspaceReady;
			},
			setupEvents: function() {

				_events['item_click'] = R8.Utils.Y.delegate('click',this.updateSelectedItems,_contentNode,'.vspace-item',this);
				_events['vspace_click'] = R8.Utils.Y.delegate('click',this.clearSelectedItems,'body','#viewspace');
				_events['port_mover'] = R8.Utils.Y.delegate('mouseover',this.portMover,_contentNode,'.port',this);
				_events['port_mover'] = R8.Utils.Y.delegate('mouseout',this.portMout,_contentNode,'.port',this);

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

				},_contentNode,'.item-name',this);

//				R8.Workspace.events['item_click'] = R8.Utils.Y.delegate('click',function(){console.log('clicked item');},R8.Workspace.viewSpaceNode,'.item, .connector');
//				R8.Workspace.events['vspace_mdown'] = R8.Utils.Y.delegate('mousedown',R8.Workspace.checkMouseDownEvent,'body','#viewspace');
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
			addItems: function() {
				if(_ui == null) _ui = {"items":{}};

				var items = _workspaceDef.items;
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

					var itemId = item['object']['id'];

//TODO: revisit with UI pos cleanup, using ui params at both item and item.object level
					if(typeof(_ui.items[itemId]) == 'undefined') {
						_ui.items[itemId] = {};
						_ui.items[itemId]['top'] = item['object']['ui'][_id]['top'];
						_ui.items[itemId]['left'] = item['object']['ui'][_id]['left'];
					}
					var id = item['object']['id'],
						top = (typeof(_uiCookie[id]) == 'undefined') ? _ui.items[id]['top'] : _uiCookie[id]['top'],
						left = (typeof(_uiCookie[id]) == 'undefined') ? _ui.items[id]['left'] : _uiCookie[id]['left'];

					_items[id].get('node').setStyles({'top':top,'left':left,'display':'block'});
				}
				this.purgePendingDelete();
			},
			getSelectedItem: function(itemId) {
				return _selectedItems[itemId];
			},
			getSelectedItems: function() {
				return _selectedItems;
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
			itemFocus: function(itemId) {
				this.clearSelectedItems();
				this.addSelectedItem(itemId,{});
			},
			blurItems: function() {
				this.clearSelectedItems();
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