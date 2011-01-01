
if (!R8.Workspace) {

	R8.Workspace = function(){
		var _viewSpaces = {},
			_viewSpaceStack = [],
			_currentViewSpace = null,

			_pageContainerId = 'page-container',
			_pageContainerNode = null;

			_toolbarId = 'wspace-toolbar',
			_toolbarNode = null,

			_contextBarId = 'wspace-context-wrapper',
			_contextBarNode = null;

		return {
			viewPortRegion : null,
			pageContainerElem : null,

			topbarElem : null,
			topbarHeight : null,
			cmdbarElem : null,

			wspaceContainerElem : null,


			viewspaceAnim : null,
			viewspaceDD : null,

			//DOM element reference for workspace container DIV
			viewspaceElem : null,

			//Y Node reference Object for the viewspaceElem
			nodeRef : null,

			init : function() {
				_pageContainerNode = R8.Utils.Y.one('#'+_pageContainerId);

				_toolbarNode = R8.Utils.Y.one('#'+_toolbarId);
				_contextBarNode = R8.Utils.Y.one('#'+_contextBarId);

//----------------------

				this.pageContainerElem = R8.Utils.Y.one('#page-container');
				this.topbarElem = R8.Utils.Y.one('#wspace-toolbar');
				this.wspaceContainerElem = R8.Utils.Y.one('#wspace-container');
				this.cmdbarElem = R8.Utils.Y.one('#cmdbar');

				this.resizeWorkspace();
				YUI().use('node','event',function(Y){
					var windowNode = Y.one(window);
					windowNode.on('resize',R8.Workspace.resizeWorkspace);
				});
				this.setupViewspace();
				R8.Cmdbar.init();
				this.loadWorkspace();
			},

			setupViewspace : function() {
				YUI().use('anim', function(Y){
					R8.Workspace.viewspaceAnim = new Y.Anim({
						node: '#viewspace',
						duration: 0.3,
					});
				});
//				this.toggleHandTool();
			},
			resizeWorkspace : function(e) {
				R8.Workspace.viewPortRegion = R8.Workspace.pageContainerElem.get('viewportRegion');
				var vportHeight = R8.Workspace.viewPortRegion['height'];
				var vportWidth = R8.Workspace.viewPortRegion['width'];
				var height = "",width="";
				var margin = 2;
				(vportHeight < 500) ? vportHeight = (500-margin) : null;
				(vportWidth < 500) ? vportWidth = (500-margin) : null;
				height = (vportHeight-margin)+"px";
				width = (vportWidth-margin)+"px";

				R8.Workspace.pageContainerElem.setStyles({'height': height,'width':width});

				var topbarRegion = R8.Workspace.topbarElem.get('region');
				var cmdbarRegion = R8.Workspace.cmdbarElem.get('region');
				var wspaceRegion = R8.Workspace.wspaceContainerElem.get('region');
				var wspaceHeight = vportHeight - (topbarRegion['height']+cmdbarRegion['height']) - margin;
//console.log(toolbarRegion);
				R8.Workspace.wspaceContainerElem.setStyles({'height': wspaceHeight});
				R8.Workspace.topbarHeight = topbarRegion['height'];

				for(rcId in R8.Workspace.resizeCallbacks) {
					var nodeObj = R8.Utils.Y.one(R8.Workspace.resizeCallbacks[rcId]['nodeId']);
					var newDimensions = R8.Workspace.resizeCallbacks[rcId]['lambda'](vportHeight,vportWidth);
					nodeObj.setStyles(newDimensions);
				}
			},

			addResizeCallback : function(callback) {
				R8.Workspace.resizeCallbacks[callback['nodeId']] = callback;
			},

			cancelResizeCallback : function(callbackId) {
				delete(R8.Workspace.resizeCallbacks[callbackId]);
			},

			/*
			 * Load a given workspace or create a new empty one
			 * @method loadWorkspace
			 * @param {string} wSpaceID ID corresponding to a given workspace to load, if empty/null create empty space
			 */
			loadWorkspace: function(wSpaceID){

//return;
//				R8.Workspace.viewspaceElem = document.getElementById('viewspace');

				R8.Workspace.viewSpaceNode = R8.Utils.Y.one('#viewspace');

//				R8.Workspace.events['item_click'] = R8.Utils.Y.delegate('click',R8.Workspace.updateSelectedItems,R8.Workspace.viewSpaceNode,'.item-wrapper, .connector');
//				R8.Workspace.events['item_click'] = R8.Utils.Y.delegate('click',function(){console.log('clicked item');},R8.Workspace.viewSpaceNode,'.item, .connector');
//				R8.Workspace.events['vspace_click'] = R8.Utils.Y.delegate('click',R8.Workspace.clearSelectedItems,'body','#viewspace');
//				R8.Workspace.events['vspace_mdown'] = R8.Utils.Y.delegate('mousedown',R8.Workspace.checkMouseDownEvent,'body','#viewspace');

//				R8.Utils.Y.all('.group').each(function(){
//console.log(this);
//				});

				R8.Workspace.events['item_dbl_click'] = R8.Utils.Y.delegate('dblclick',function(e){
					var node = e.currentTarget;
					var model = node.getAttribute('data-model');
					var id = node.getAttribute('data-id');
					R8.Workspace.Dock.show();

					var route = 'attribute/wspace_'+model+'_display/'+id;
//					var route = 'attribute/wspace_'+model+'_display';

//					R8.Ctrl.call(route,'id='+id,{});
					R8.Ctrl.call(route);

				},R8.Workspace.viewSpaceNode,'.wspace-item');


//------Dock setup-------------

//				_pageContainerNode.append(R8.Workspace.Dock.render({'display':'block','top':_toolbarNode.get('region').bottom}));
//				R8.Workspace.Dock.init();
				R8.Workspace.Dock.render({'display':'block','top':_toolbarNode.get('region').bottom});
//				R8.MainToolbar.init();
return;

//TODO: right now hardcoding assignment from demoData.r8.js
				this.components = workspaceComponents;
				this.ports = workspacePorts;

//TODO: add logic in to retrieve workspace info based on ID
				for(var c in this.components) {
					var comp = R8.Component.render(this.components[c]);
					this.viewspaceElem.appendChild(comp);
					this.addDragDrop(comp);
					R8.Component.renderPorts(comp);

/*
					for (var i in this.components[c].availPorts[p]) {
						var portObj = this.components[c].availPorts[p][i];
						var portElemID = c + '-' + p + '-' + portObj.id;
						this.ports[portElemID] = portObj;
console.log('registering port:'+portElemID);
					}
*/
//TODO: this might change with behavior change of Delegate to query all children, not just 1st level
					this.registerPorts(c);
				}

				for(var c in this.components) {
//TODO: cleanup after reworking server/client side def and store
//*****TODO: rework and FLATTEN how ports are stored under components, should be completely flat
					for(var p in this.components[c].availPorts) {
					}
				}

//TODO: render all connectors on page after rendering components/nodes/groups, etc
				this.connectors = workspaceConnectors;

				for(var c in this.connectors) {
					var startElemID = this.connectors[c].startElement.connectElemID;
					var endElemID = this.connectors[c].endElements[0].connectElemID;
					var connectionType = this.connectors[c].type;
					R8.Canvas.renderLink(c);
				}
			},

			toggleHandTool : function() {
				YUI().use('dd-drag', function(Y) {
					R8.Workspace.viewspaceDD = new Y.DD.Drag({
						node: '#viewspace'
					});
					R8.Workspace.viewspaceDD.on('drag:end',function(e){
						var viewspaceElem = Y.one('#viewspace');
						var top = viewspaceElem.getStyle('top');
						var left = viewspaceElem.getStyle('left');
						top = top.replace('px','');
						left = left.replace('px','');

						if (top > 0 || left > 0) {
							top > 0 ? top = 0 : null;
							left > 0 ? left = 0 : null;
							R8.Workspace.viewspaceAnim.set('to',{xy:[left,top]});
							R8.Workspace.viewspaceAnim.run();
						}
					});
				});
			},

//			activeTool : 'selection',
			activeTool : '',
			selectionDragEvent : null,
			selectionMouseUpEvent : null,
			selectionStartX : 0,
			selectionStartY : 0,
			selectionBoxElem : null,

			checkMouseDownEvent : function(e) {
				if(R8.Workspace.activeTool === 'selection') {
					R8.Workspace.selectionStartX = e.pageX;
					R8.Workspace.selectionStartY = e.pageY;
					R8.Workspace.selectionDragEvent = R8.Utils.Y.one('#viewspace').on('mousemove', R8.Workspace.updateSelectionRegion);
					R8.Workspace.selectionMouseUpEvent = R8.Utils.Y.one('#viewspace').on('mouseup', R8.Workspace.handleSelectionMouseUp);
				}
			},

			updateSelectionRegion : function(e) {
				var boxHeight = Math.sqrt(Math.pow((e.pageY-R8.Workspace.selectionStartY),2));
				var boxWidth = Math.sqrt(Math.pow((e.pageX-R8.Workspace.selectionStartX),2));
				var mouseX = e.pageX;
				var mouseY = e.pageY;
				var boxStyles = {'height':boxHeight+'px','width':boxWidth+'px'};

				if(R8.Workspace.selectionBoxElem === null) {
					R8.Workspace.selectionBoxElem = document.createElement('div');
					R8.Workspace.selectionBoxElem.setAttribute('class','selectionBox');
					R8.Workspace.selectionBoxElem.setAttribute('id','selectionBox');
					R8.Workspace.viewspaceElem.appendChild(R8.Workspace.selectionBoxElem);
				}

				if(mouseX < R8.Workspace.selectionStartX)
					boxStyles['left'] = mouseX + 'px';
				else
					boxStyles['left'] = R8.Workspace.selectionStartX + 'px';

				if(mouseY < R8.Workspace.selectionStartY)
					boxStyles['top'] = mouseY + 'px';
				else
					boxStyles['top'] = R8.Workspace.selectionStartY + 'px';

				R8.Utils.Y.one(R8.Workspace.selectionBoxElem).setStyles(boxStyles);
			},
			handleSelectionMouseUp : function(e) {
				R8.Workspace.selectionDragEvent.detach();
				R8.Workspace.selectionMouseUpEvent.detach();
				if (R8.Workspace.selectionBoxElem) {
					R8.Workspace.viewspaceElem.removeChild(R8.Workspace.selectionBoxElem);
					R8.Workspace.selectionBoxElem = null;
				}
			},

			/*
			 * addDrag will make a component drag/droppable on a workspace
			 * @method addDrag
			 * @param {string} 	componentID The DOM ID for the component to add drag drop capabilities to
			 * @param {DOM Elem}	Node Object to add drag drop capabilities to
			 */
			addDrag : function(itemId) {
				var vsContext = this.getVspaceContext();

				YUI().use('dd-drag','dd-plugin',function(Y){
					R8.Workspace.viewspaces[vsContext]['items'][itemId]['drag'] = new Y.DD.Drag({
						node: '#'+itemId
					});
					R8.Workspace.viewspaces[vsContext]['items'][itemId]['drag'].on('drag:start',function(){
						R8.Workspace.clearSelectedItems();
						var node = this.get('node');
						var nodeId = node.get('id');
						node.addClass('focus');
//TODO: revisit, using {} for selected items in case have to enrich data pts around selected items down road
						R8.Workspace.viewspaces[vsContext]['selectedItems'][nodeId] = '1';
					});
					R8.Workspace.viewspaces[vsContext]['items'][itemId]['drag'].on('drag:drag',function(){
//TODO: update refreschConnectors with new viewspace object usage
//						R8.Component.refreshConnectors(this.get('node').get('id'));
					});
					R8.Workspace.viewspaces[vsContext]['items'][itemId]['node'].setAttribute('data-status','dd-ready');
				});
			},

			/*
			 * removeDrag will take away a components drag/droppable capabilites on a workspace
			 * @method removeDrag
			 * @param {string} 	componentID The DOM ID for the component to remove drag drop capabilities from
			 * @param {Node}	Node Object to remove drag drop capabilities from
			 */
			removeDrag: function(itemId){
			},

			addDrop : function(itemId) {
				var vsContext = this.getVspaceContext();
				var modelName = R8.Workspace.viewspaces[vsContext]['items'][itemId]['node'].getAttribute('data-model');
//				var dropGroupName = 'dg-'+modelName;
				var dropGroupName = 'dg-component';

				R8.Workspace.viewspaces[vsContext]['items'][itemId]['node'].addClass(dropGroupName)
return;
//TODO: probably pull the drop registration into its own function once more functionality is added
//console.log('Going to add node to drop group:'+dropGroupName);
//console.log(node);
				YUI().use('dd-drop', function(Y){
//					node.plug(R8.Utils.Y.Plugin.Drop);
					R8.Workspace.viewspaces[vsContext]['items'][itemId]['drop'] = new Y.DD.Drop({
						node: '#'+itemId
					});
//					R8.Workspace.viewspaces[vsContext]['items'][itemId]['drop'].addToGroup([dropGroupName]);
					R8.Workspace.viewspaces[vsContext]['items'][itemId]['drop'].on('drop:enter',function(e){
//DEBUG
console.log('Over drop target....');
console.log(e);
					});
					R8.Workspace.viewspaces[vsContext]['items'][itemId]['drop'].on('drop:hit',function(e){
console.log('I guess I am hitting this now!!!!');
					});
				});
			},

			updateSelectedItems : function(e) {
				var vsContext = R8.Workspace.getVspaceContext();
				var itemId = e.currentTarget.get('id');
				if(typeof(R8.Workspace.viewspaces[vsContext]['items'][itemId]) === 'undefined') {
					R8.Workspace.clearSelectedItems();
					return;
				} else {
					//if ctrl no held then clear all currently selected
					if(e.ctrlKey == false) R8.Workspace.clearSelectedItems();
//TODO: temp setting to 1 until figuring out if need to enhance
					R8.Workspace.viewspaces[vsContext]['selectedItems'][itemId] = '1';
					R8.Workspace.viewspaces[vsContext]['items'][itemId]['node'].addClass('focus');

					e.stopImmediatePropagation();
				}
				return;
			},

			/*
			 * clearSelectedItems removes styling from any selectedElements
			 * @method clearSelectedItems
			 * @param {Evt} e Event object passed from event firing
			 * @param {String} clickEventTarget String indicating if being called from which workspace event
			 */
			clearSelectedItems : function(e) {
				var vsContext = R8.Workspace.getVspaceContext();
				for(var itemId in R8.Workspace.viewspaces[vsContext]['selectedItems']) {
					R8.Workspace.viewspaces[vsContext]['items'][itemId]['node'].removeClass('focus');
				}
				R8.Workspace.viewspaces[vsContext]['selectedItems'] = {};
			},

			/*
			 * registerPorts will register ports with workspace and activate for connection if applicable
			 * @method registerPorts
			 * @param {string} compElemID
			 */
			registerPorts : function(compElemID) {
//				var portObj = R8.Workspace.ports[portElemID];

//TODO: figure out how to handle groups for drop zones
				var groups = ['test'];

				var dragDelegate = new R8.Utils.Y.DD.Delegate({
						cont:'#'+compElemID,
						nodes:'.available',
						groups: groups
						}
					);
				dragDelegate.dd.plug(R8.Utils.Y.Plugin.DDProxy, {
					borderStyle: false,
					moveOnEnd: false
				});
				dragDelegate.on('drag:start', function(e) {
					e.stopPropagation();
					var p = this.get('dragNode'),
						n = this.get('currentNode');
					p.setAttribute('class', n.getAttribute('class'));
					this.dd.addToGroup(groups);

					var drop = new R8.Utils.Y.DD.Drop({
						node: '#comp1-north-0',
						groups: groups
					});

				});
				dragDelegate.on('drag:drag', function(e) {
					e.stopPropagation();
					R8.Canvas.renderDragWire(this.get('currentNode'),this.get('dragNode'));
				});
				dragDelegate.on('drag:drophit', function(e) {
//					wireConnected = true;
					var wireCanvas = R8.Utils.Y.one('#wireCanvas');
					R8.Utils.Y.one('#viewspace').removeChild(wireCanvas);
					delete(wireCanvas);
					R8.Workspace.createConnector(this.get('currentNode').get('id'),e.drop.get('node').get('id'));
//					console.log('Gyeah!! Hit Target Yo!');
				});

				dragDelegate.on('drag:dropmiss', function(e) {
					var wireCanvas = R8.Utils.Y.one('#wireCanvas');
					R8.Utils.Y.one('#viewspace').removeChild(wireCanvas);
					delete(wireCanvas);
					console.log('drop miss');
				});
			},

			/*
			 * createConnector will create details for new connector, render it and call the server to persist it
			 * @method createConnector
			 */
			createConnector : function(startElemID,endElemID) {
				var startConnectorLocation = R8.Workspace.ports[startElemID].location;
				var startCompID = R8.Workspace.ports[startElemID].compID;
				var endConnectorLocation = R8.Workspace.ports[endElemID].location;
				var endCompID = R8.Workspace.ports[endElemID].compID;
				var connectorType = 'fullBezier';
				var date = new Date();
				var tempConnectorID = 't-'+date.getTime() + '-' + Math.floor(Math.random()*20);

				R8.Workspace.connectors[tempConnectorID] = {
					'type': connectorType,
					'startElement': {
						'elemID': '?',
						'location':startConnectorLocation,
						'connectElemID':startElemID
					},
					'endElements': [{
						'elemID':'?',
						'location':endConnectorLocation,
						'connectElemID':endElemID
					}]
				};

				R8.Canvas.renderLink(tempConnectorID);

				var startNode = R8.Utils.Y.one('#'+startElemID);
				var endNode = R8.Utils.Y.one('#'+endElemID);
				startNode.removeClass('available');
				startNode.addClass('connected');
				endNode.removeClass('available');
				endNode.addClass('connected');

//TODO: add call to server here to persist, then update tempConnectorID with actual persisted ID
				R8.Workspace.components[startCompID].connectors[tempConnectorID] = R8.Workspace.connectors[tempConnectorID];
				R8.Workspace.components[endCompID].connectors[tempConnectorID] = R8.Workspace.connectors[tempConnectorID];
			},
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

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

				var ui = {'top':top,'left':left};

				YUI().use("json", function(Y) {
					var uiStr = Y.JSON.stringify(ui);
					var queryParams = 'target_model_name='+vspaceType+'&target_id='+vspaceId+'&ui='+uiStr;
//					var queryParams = 'target_model_name=project&target_id=2147483649&ui='+uiStr;
//					queryParams += '&redirect='+modelName+'/wspace_display';
//					queryParams += '&model_redirect='+modelName+'&action_redirect=wspace_display&id_redirect=*id';
					queryParams += '&model_redirect='+modelName+'&action_redirect=wspace_display_2&id_redirect=*id';
//console.log(queryParams);
//return;
					var completeCallback = function(){
						R8.Workspace.setupNewItems();
					}
					var callbacks = {
						'io:renderComplete' : completeCallback
					};
					var params = {
						'callbacks': callbacks,
						'cfg': {
							'data': queryParams
						} 
					}
					R8.Ctrl.call(modelName+'/clone/'+modelId,params);
				});
			},

			addComponentToContainer : function(componentId,containerNode) {
				var modelName = containerNode.getAttribute('data-model');
				var modelId = containerNode.getAttribute('data-id');

				var queryParams = 'target_model_name='+modelName+'&target_id='+modelId;
//				queryParams += '&model_redirect='+modelName+'&action_redirect=wspace_display&id_redirect='+modelId;
				queryParams += '&model_redirect='+modelName+'&action_redirect=wspace_refresh&id_redirect='+modelId;

//				containerNode.setAttribute('data-status','pending_delete');

				var completeCallback = function() {
					R8.Workspace.refreshItem(modelId);
				}
				var callbacks = {
					'io:renderComplete' : completeCallback
				};
//				containerNode.setAttribute('data-status','pending_delete');
//				R8.Ctrl.call('component/clone/'+componentId,queryParams,callbacks);
				R8.Ctrl.call('component/clone/'+componentId,{
					'callbacks': callbacks,
					'cfg': {
						'data': queryParams
					}
				});
			},

			addNodesToGroup : function(nodeList,groupId) {
//DEBUG
console.log('Going to add nodes:'+nodeList);
console.log('To Group:'+groupId);
			},

			refreshItem : function(itemId) {
				itemId = 'item-'+itemId;
				var viewspaceNode = R8.Utils.Y.one('#viewspace');
				var vspaceContext = R8.Workspace.getVspaceContext();
				var itemChildren = viewspaceNode.get('children');
				itemChildren.each(function(){
					if(this.get('id') == itemId && this.getAttribute('data-status') == 'pending_delete') {
						this.purge(true);
						this.remove();
						delete (this);
						R8.Workspace.viewspaces[vspaceContext]['items'][itemId] = {};
					} else {
						var dataModel = this.getAttribute('data-model');
						var status = this.getAttribute('data-status');

						if (dataModel == 'node' && status == 'pending_setup') {
							R8.Workspace.regNewItem(this.get('id'));
						}
					}
				});
			},

			setupNewItems : function() {
				var viewspaceNode = R8.Utils.Y.one('#viewspace');
				var itemChildren = viewspaceNode.get('children');
				itemChildren.each(function(){
					var dataModel = this.getAttribute('data-model');
					var status = this.getAttribute('data-status');

					if(status == 'pending_delete') {
						R8.Workspace.pendingDelete[this.get('id')] = {
							'top':this.getStyle('top'),
							'left':this.getStyle('left')
						}
					}
					if((dataModel == 'node' || dataModel == 'group') && status == 'pending_setup') {
						var top = this.getStyle('top');
						var left = this.getStyle('left');
						for(item in R8.Workspace.pendingDelete) {
							if(R8.Workspace.pendingDelete[item]['top'] == top && R8.Workspace.pendingDelete[item]['left'] == left) {
								var cleanupNode = R8.Utils.Y.one('#'+item);
								cleanupNode.purge(true);
								cleanupNode.remove();
								delete(cleanupNode);
								delete(R8.Workspace.pendingDelete[item]);
							}
						}
						R8.Workspace.regNewItem(this.get('id'));
//						R8.Workspace.addViewSpaceItem(this);
//						this.setAttribute('data-status','added');
//						R8.Workspace.addDragDrop(this.get('id'));
//						this.setAttribute('data-status','dd-ready');
					}
				});
			},

//TODO: revisit to turn components into a [viewspace][item] style
			regNewItem : function(itemId) {
				var vsContext = R8.Workspace.getVspaceContext();
				var node = R8.Utils.Y.one('#'+itemId);
				var nodeId = node.get('id');
				R8.Workspace.viewspaces[vsContext]['items'][nodeId] = {
					'node' : node
				}
				R8.Workspace.viewspaces[vsContext]['items'][nodeId]['node'].setAttribute('data-status', 'added');
//				R8.Workspace.setupViewSpaceItem(nodeId);
				R8.Workspace.addDrag(itemId);
				R8.Workspace.addDrop(itemId);
				R8.Workspace.setupMinMax(itemId);
			},

			setupMinMax : function(itemId) {
				var minMaxId = itemId+'-minmax-large';
				var minMaxNode = R8.Utils.Y.one('#'+minMaxId);

				if(minMaxNode != null) {
					minMaxNode.on('mouseover',function(e,itemId){
						e.currentTarget.setStyle('backgroundPosition','-16px 0px');
					},this,itemId);
					minMaxNode.on('mouseout',function(e,itemId){
						e.currentTarget.setStyle('backgroundPosition','0px 0px');
					},this,itemId);
					minMaxNode.on('click',function(e,itemId){
						R8.Utils.Y.one('#'+itemId+'-large').setStyle('display','none');
						R8.Utils.Y.one('#'+itemId+'-medium').setStyle('display','block');
						var itemNode = R8.Utils.Y.one('#'+itemId);
						itemNode.addClass('medium');
						itemNode.removeClass('large');
					},this,itemId);

					//setup medium minmax
					var minMaxId = itemId+'-minmax-medium';
					var minMaxNode = R8.Utils.Y.one('#'+minMaxId);

					minMaxNode.on('mouseover',function(e,itemId){
						e.currentTarget.setStyle('backgroundPosition','-16px -16px');
					},this,itemId);
					minMaxNode.on('mouseout',function(e,itemId){
						e.currentTarget.setStyle('backgroundPosition','0px -16px');
					},this,itemId);
					minMaxNode.on('click',function(e,itemId){
						R8.Utils.Y.one('#'+itemId+'-medium').setStyle('display','none');
						R8.Utils.Y.one('#'+itemId+'-large').setStyle('display','block');
						var itemNode = R8.Utils.Y.one('#'+itemId);
						itemNode.addClass('large');
						itemNode.removeClass('medium');
					},this,itemId);
				}
			},

			addItemSuccess : function(ioId,responseObj) {
//				eval("R8.Ctrl.callResults[ioId] =" + responseObj.responseText);
				eval("var response =" + responseObj.responseText);
//console.log(responseObj.responseText);
//console.log(response);

			},

			addItemFailure : function(ioId,responseObj) {
console.log('call to add item to workspace failed.....');
			},


//-------------------------------------------------------------
//-------------------------------------------------------------
//-------------------------------------------------------------

			commitChanges: function() {
				var contextId = _currentViewSpace,
					contextType = 'datacenter';

				var successCallback = function(ioId,responseObj) {
					eval("var response =" + responseObj.responseText);
					var returnData = response['application_workspace_commit_changes']['content'][0]['data'];
					alert(returnData);
console.log(response);
				}
				var params = {
					'cfg': {
						'data': 'context_type='+contextType+'&context_id='+contextId
					},
					'callbacks': {
						'io:success': successCallback
					}
				};
				R8.Ctrl.call('workspace/commit_changes',params);
			},
//TODO: add check to see if viewspace is already loaded and this is a 'refocus'
			pushViewSpace: function(viewSpaceDef) {
				var id = viewSpaceDef['object']['id'];
				_viewSpaces[id] = new R8.ViewSpace(viewSpaceDef);
				_viewSpaces[id].init();
				_viewSpaceStack.push(id);
				_currentViewSpace = id;
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
			},

			renderItemPorts: function(itemId,ports,viewSpaceId) {
				var vSpaceId = (typeof(viewSpaceId) == 'undefined') ? _currentViewSpace : viewSpaceId;

				_viewSpaces[vSpaceId].renderItemPorts(itemId,ports);
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
			},
/*
			setupItem: function(itemDef) {
console.log(itemDef);
			},

			setupItemToolbar: function(toolbarDef) {
console.log(toolbarDef);
			},
*/
			getSelectedItems: function() {
				return _viewSpaces[_currentViewSpace].getSelectedItems();
			},

			checkViewSpaces: function() {
for(vs in _viewSpaces) {
	_viewSpaces[vs].test();
}
			},

			setupItem : function(itemDef) {
				var viewspaceNode = R8.Utils.Y.one('#viewspace');
				var itemChildren = viewspaceNode.get('children');
				itemChildren.each(function(){
					var dataModel = this.getAttribute('data-model');
					var status = this.getAttribute('data-status');

					if(status == 'pending_delete') {
						R8.Workspace.pendingDelete[this.get('id')] = {
							'top':this.getStyle('top'),
							'left':this.getStyle('left')
						}
					}
					if((dataModel == 'node' || dataModel == 'group') && status == 'pending_setup') {
						var top = this.getStyle('top');
						var left = this.getStyle('left');
						for(item in R8.Workspace.pendingDelete) {
							if(R8.Workspace.pendingDelete[item]['top'] == top && R8.Workspace.pendingDelete[item]['left'] == left) {
								var cleanupNode = R8.Utils.Y.one('#'+item);
								cleanupNode.purge(true);
								cleanupNode.remove();
								delete(cleanupNode);
								delete(R8.Workspace.pendingDelete[item]);
							}
						}
						R8.Workspace.regNewItem(this.get('id'));
//						R8.Workspace.addViewSpaceItem(this);
//						this.setAttribute('data-status','added');
//						R8.Workspace.addDragDrop(this.get('id'));
//						this.setAttribute('data-status','dd-ready');
					}
				});
			},

//-------------------------------------------------------------
//-------------------------------------------------------------
//-------------------------------------------------------------

			viewspaces : {},
//TODO: revisit when fully implementing multiple viewspaces
			getVspaceContext : function() {
				if (typeof(R8.Workspace.viewspaces['vspace1']) == 'undefined') {
					R8.Workspace.viewspaces['vspace1'] = {
						'items' : {},
						'selectedItems' : {}
					};
				}
				return 'vspace1';
			},

			events : {},
			/*
			 * Collection of active connectors for the given workspace
			 */
			connectors: {},

			/*
			 * Collection of active ports in given workspace
			 */
			ports: {},
			
			/*
			 * Collection of active elements for the given workspace
			 */
//			components: {},

			/*
			 * Collection of selected/focused elements for the given workspace
			 */
//			selectedElements : {},

			resizeCallbacks : {},

			pendingDelete : {},
		}
	}();
}