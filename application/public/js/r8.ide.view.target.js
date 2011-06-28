
if (!R8.IDE.View.target) {

	R8.IDE.View.target = function(view) {
		var _view = view,
			_id = _view.id,
			_panel = _view.panel,
			_pendingDelete = {},

			_modalNoe = null,
			_modalNodeId = 'target-'+_id+'-modal',
			_shimNodeId = null,
			_shimNode = null,

			_alertNode = null,
			_alertNodeId = null,

//DEBUG
//			_contentTpl = '<div id="'+_panel.get('id')+'-'+_view.id+'" class="target-viewspace"></div>',
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

			_contentWrapperNode = null,
			_contentNode = null,

			_initialized = false,

			//FROM WORKSPACE
			_viewSpaces = {},
			_viewSpaceStack = [],
			_currentViewSpace = null,
			_viewContext = 'node',

			_cmdBar = null,

			_events = {};

		return {
			init: function() {
				_contentNode = R8.Utils.Y.one('#'+_panel.get('id')+'-'+_view.id);
				_contentWrapperNode = R8.Utils.Y.one('#'+_panel.get('id')+'-'+_view.id+'-wrapper');

				this.getWorkspaceDef();

				var cmdbarDef = {
					'containerNode': _contentNode,
					'panel': _panel,
					'viewSpace': this
				};
				_cmdBar = new R8.Cmdbar2(cmdbarDef);
				_cmdBar.init();

				document.getElementById('cmdbar_input_form').onsubmit = function() {
					_cmdBar.submit();
					return false;
				};

//				_contentNode.append(R8.Dock.render({'display':'block','top':_topbarNode.get('region').bottom}));
//				_contentNode.append(R8.Dock2.render({'display':'block','top':_contentNode.get('region').top}));
				_contentNode.append(R8.Dock2.render({'display':'block','top':40}));
				R8.Dock2.init(_contentNode.get('id'));

				_initialized = true;
			},
			render: function() {
				return _contentTpl;
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
						return _id;
						break;
					case "name":
						return _view.name;
						break;
					case "type":
						return _view.type;
						break;
					case "node":
						return _contentWrapperNode;
						break;
					case "items":
						return _viewSpaces[_currentViewSpace].get('items');
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
				R8.Ctrl.call('target/get_view_items/'+_view.id,params);
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
					'targetId':_id,
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
			touchItems: function(itemList,viewSpaceId) {
				var vSpaceId = (typeof(viewSpaceId) == 'undefined') ? _currentViewSpace : viewSpaceId;

				_viewSpaces[vSpaceId].touchItems(itemList);
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