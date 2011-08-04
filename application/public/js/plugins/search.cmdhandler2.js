//R8.Cmdbar2.cmdHandlers['search'] = {
if(!R8.Commands) R8.Commands = {};
R8.Commands.search = {
	'cmdSubmit':function(cmdList,cmdbar) {
		var qList = [],numCmds = cmdList.length;

		for(i=1;i<numCmds;i++) {
			if(cmdList[i] == ' ') continue;
			var qtParts = cmdList[i].split('=');
			var param = qtParts[0],value = qtParts[1];
			var queryTerm = {'name':param,'value':value};
			qList.push(queryTerm);
		}

		switch(cmdList[0]) {
			case "node":
				var tabName = 'node-search';
				var tabI18n = 'Node Search';
				var queryTerm = 'model_name=node';
				break;
			case "component":
				var tabName = 'component-search';
				var tabI18n = 'Component Search';
				var queryTerm = 'model_name=component&type=template';
				break;
			case "attribute":
				var tabName = 'attribute-search';
				var tabI18n = 'Attr Search';
				var queryTerm = 'model_name=attribute';
				break;
			case "blah":
				break;
		}

		if (cmdbar.tabExists(tabName)) {
//TODO: need to port all maintoolbar stuff over to tab definition
//								R8.Cmdbar.loadedTabs[tabIndex].clearContent();
			var tabIndex = cmdbar.getTabIndexByName(tabName);
			cmdbar.loadedTabs[tabIndex].clearSlider();
		} else {
			var newTab = cmdbar.cloneTabObj(this.tabDefs[tabName]);
			newTab.name = tabName;
			newTab['i18n'] = tabI18n;
			var tabIndex = cmdbar.addTab(newTab);
			cmdbar.registerTabEvents(tabIndex);
		}
//TODO: needed registerTabEvents seperated out from addTab b/c of some weird timing issues or something, need to revisit and hopefully consolidate
		cmdbar.changeTabFocus(tabIndex);
		if(!cmdbar.tabsPaneOpen) cmdbar.toggleTabs();

		for(term in qList) {
			if(queryTerm !='') queryTerm +='&';
				queryTerm += qList[term]['name']+'='+qList[term]['value'];
		}
		var tabName = this.name;
		var renderCompleteCallback = function() {
			cmdbar.loadedTabs[tabIndex].initSlider(cmdbar.loadedTabs[tabIndex].name,cmdbar);
		}
		var callbacks = {
			'io:start' : cmdbar.loadedTabs[tabIndex].startSearch,
			'io:end' : cmdbar.loadedTabs[tabIndex].endSearch,
			'io:renderComplete' : renderCompleteCallback,
		};
		var params = {
			'cfg':{
				'data': queryTerm
			},
			'callbacks':callbacks
		}

		R8.Ctrl.call('workspace/search',params);
//TODO: remove
//		R8.Ctrl.call('workspace/search',queryTerm,callbacks);
	},

	'tabDefs': {
		'node-search': {
			'name': '',
			'i18n': '',
			'status': '',
			'node': null,
			'events': {},
			'contentLoader': function(containerNode){
				var name = this.name;
//				var width = R8.Workspace.viewPortRegion['width'] - 40;
				var width = containerNode.get('region').width - 40;

				var slideContainerWidth = width - 4;

				var contentFraming = '<div id="' + name + '-slide-wrapper" class="slide-wrapper" style="width: ' + width + 'px; margin-top: 10px;">';
				contentFraming += 	'<div id="' + name + '-lbutton" class="lbutton"></div>';
				contentFraming += 	'<div class="slide-l-shade">';
				contentFraming +=		'<div class="shade-top"></div>';
				contentFraming += 		'<div class="shade-body"></div>';
				contentFraming += 		'<div class="shade-bottom"></div>';
				contentFraming += 	'</div>';
				contentFraming += 	'<div id="' + name + '-list-container" class="slide-container" style="width: ' + slideContainerWidth + 'px;">';
				contentFraming +=		'<div class="slide-container-header"></div>';
				contentFraming += 		'<div id="' + name + '-slider"></div>';
				contentFraming += 	'</div>';
				contentFraming += 	'<div class="slide-r-shade">';
				contentFraming +=		'<div class="shade-top"></div>';
				contentFraming += 		'<div class="shade-body"></div>';
				contentFraming += 		'<div class="shade-bottom"></div>';
				contentFraming += 	'</div>';
				contentFraming += 	'<div id="' + name + '-rbutton" class="rbutton"></div>';
				contentFraming += '</div>';
				document.getElementById('cmdbar-' + this.name + '-tab-content').innerHTML = contentFraming;

				var wrapperId = '#' + name + '-slide-wrapper';
				var wrapperResizeCallback = {
					'nodeId': wrapperId,
					'lambda': function(height, width){
						var width = width - 40;
						return {
							'width': width
						};
					}
				};

//DEBUG
//				R8.Workspace.addResizeCallback(wrapperResizeCallback);

				var sliderId = '#' + name + '-list-container';
				var sliderResizeCallback = {
					'nodeId': sliderId,
					'lambda': function(height, width){
						var width = width - 44;
						return {
							'width': width
						};
					}
				};
//DEBUG
//				R8.Workspace.addResizeCallback(sliderResizeCallback);
			},
				
			'focus': function(cmdbar){
				var tIndex = cmdbar.getTabIndexByName(this.name);

				YUI().use("node", function(Y){
					cmdbar.loadedTabs[tIndex]['events']['slider_key_press'] = Y.one('document').on("keypress", function(e){
						if (e.keyCode == 37) {
							cmdbar.loadedTabs[tIndex].slideLeft(e,cmdbar);
//								e.halt();
						}
						else if (e.keyCode == 39) {
							cmdbar.loadedTabs[tIndex].slideRight(e,cmdbar);
//								e.halt();
						}
					});
				});
			},

			blur: function(cmdbar){
				var tIndex = cmdbar.getTabIndexByName(this.name);
				//DEBUG
				//console.log('Blurring for:'+this.name);
				//console.log(R8.Cmdbar.loadedTabs[tIndex]['events']);
				if (typeof(cmdbar.loadedTabs[tIndex]['events']['slider_key_press']) != 'undefined') {
					cmdbar.loadedTabs[tIndex]['events']['slider_key_press'].detach();
				}
			},

			clearContent: function(){
			},

			deleteCleanup: function(){
				var nodeId = '#' + this.name + '-list-container';
//DEBUG
//				R8.Workspace.cancelResizeCallback(nodeId);
				this.sliderAnim = null;
				this.slideBarNode = null;
			},

			//------------Search Specific Functions/Callbacks---------
			startSearch: function(ioId, arguments){
			},

			endSearch: function(ioId, arguments){
			},

			clearSlider: function(){
				if (this.slideBarNode === null) 
					return;
				//DEBUG
				//console.log('Going to clear everything out...');
				this.events['slider_anim'].detach();
				delete (this.events['slider_anim']);
				this.events['lbtn_click'].detach();
				delete (this.events['lbtn_click']);
				this.events['rbtn_click'].detach();
				delete (this.events['rbtn_click']);
					
				//TODO: figure out why slider_key_press throws undefined error after a 2nd search is run
				this.events['slider_key_press'].detach();
				delete (this.events['slider_key_press']);
					
				this.sliderAnim = null;
				this.slideBarNode = null;
				this.sliderSetup = false;
				document.getElementById(this.name + '-list-container').innerHTML = '';
			},

			initSlider: function(tabName,cmdbar){
				var tIndex = cmdbar.getTabIndexByName(tabName);
				if (document.getElementById(tabName + '-slide-bar') == null) {
					var initSliderCallback = function(){
						cmdbar.loadedTabs[tIndex].initSlider(tabName,cmdbar);
					}
					setTimeout(initSliderCallback, 100);
					return;
				}
				cmdbar.loadedTabs[tIndex].setupDD(cmdbar);

				YUI().use('anim', function(Y){
					cmdbar.loadedTabs[tIndex].setupSliderAnim(Y, tIndex,cmdbar);
				});
				cmdbar.loadedTabs[tIndex].sliderSetup = true;
			},

			setupDD: function(cmdbar){
				var name = this.name;
				var tIndex = cmdbar.getTabIndexByName(name);

				YUI().use('dd-delegate', 'dd-proxy', 'dd-drop', 'dd-drop-plugin', 'node', function(Y){
					cmdbar.loadedTabs[tIndex].compDDel = new Y.DD.Delegate({
						cont: '#' + name + '-slide-bar',
						nodes: 'div.node-drag',
					});

					cmdbar.loadedTabs[tIndex].compDDel.dd.plug(Y.Plugin.DDProxy, {
						moveOnEnd: false,
						borderStyle: false,
					});

					cmdbar.loadedTabs[tIndex].compDDel.on('drag:start', function(e){
						var drag = this.get('dragNode'), c = this.get('currentNode');
						drag.set('innerHTML',c.get('innerHTML'));
						drag.setAttribute('class', c.getAttribute('class'));
						this.dd.addToGroup('viewspace_drop');
						drag.setStyles({
							opacity: .5,
							zIndex: 1000
						});
					});

					cmdbar.loadedTabs[tIndex].compDDel.on('drag:mouseDown', function(e){
						var dropGroup = 'dg-node';

						var vspaceNode = Y.one('#'+cmdbar.get('containerNode').get('id'));
						if (!vspaceNode.hasClass('yui3-dd-drop')) {
							var vspaceDrop = new Y.DD.Drop({
								node: vspaceNode
							});
							vspaceDrop.addToGroup([dropGroup]);

							vspaceDrop.on('drop:enter', function(e){
							});
							vspaceDrop.on('drop:hit', function(e){
								var drop = e.drop.get('node');
								var dragClone = e.drag.get('dragNode').get('children').item(0);
								var itemNodeId = dragClone.get('id');
								var new_comp_id = Y.guid();
								dragClone.set('id', new_comp_id);
		
								var vspaceElem = R8.Utils.Y.one('#'+cmdbar.get('containerNode').get('id'));
								var vspaceXY = vspaceElem.getXY();
								var dragXY = dragClone.getXY();
								var dragRegion = dragClone.get('region');
								var dragLeft = dragXY[0] - (vspaceXY[0]);
								var dragTop = dragXY[1] - (vspaceXY[1]);

								dragClone.setStyles({
									'top': dragTop + 'px',
									'left': dragLeft + 'px'
								});
var tempId = Y.guid();
var newNodeDef = {
	'id': tempId,
//	'id': dragClone.getAttribute('data-id'),
	'status': 'temp',
	'is_deployed': false,
	'node_id': dragClone.getAttribute('data-id'),
	'data-model': dragClone.getAttribute('data-model'),
	'name': R8.Utils.Y.one('#'+itemNodeId+' .node-image-name').get('innerHTML'),
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
//DEBUG
//console.log('got drop hit on target...');
//console.log(newItemDef);

//								drop.append(dragClone);
//								dragClone.setAttribute('data-status','pending_delete');
//								cmdbar.get('viewSpace').addItemToViewSpace(dragClone);
//								cmdbar.get('parentView').addItem(dragClone);
							});
						}

						var dropList = Y.all('#'+cmdbar.get('containerNode').get('id')+' div.'+dropGroup);
						dropList.each(function(){
							if(!this.hasClass('yui3-dd-drop')) {
								var drop = new Y.DD.Drop({node:this});
								drop.addToGroup([dropGroup]);
								drop.on('drop:enter',function(e){ console.log('entered drop element!!!');});
								drop.on('drop:hit',function(e){
									var group = e.drop.get('node');
									var groupId = group.getAttribute('data-id');
									var dragNode = e.drag.get('dragNode').get('children').item(0);
									var nodeId = dragNode.getAttribute('data-id');

									cmdbar.get('viewSpace').addNodesToGroup([nodeId],groupId);
								});
							}
						});
					});

//					R8.Cmdbar.loadedTabs[tIndex].drop.drop.addToGroup(['viewspace_drop']);
					//TODO: come back and add in clean up of DD objects and events
/*
					R8.Cmdbar.loadedTabs[tIndex].compDDel.on('drag:drophit', function(e){
						var drop = e.drop.get('node'), drag = this.get('dragNode');
//						var item_id = drag.getAttribute('data-id');
//						var model_name = drag.getAttribute('data-model');
//DEBUG
console.log('Have a drop hit for node!!!!');
						var dragChild = drag.get('children').item(0).cloneNode(true);
						var new_comp_id = Y.guid();
						dragChild.set('id', new_comp_id);

						var wspaceElem = R8.Utils.Y.one('#viewspace');
						var wspaceXY = wspaceElem.getXY();
						var dragXY = drag.getXY();
						var dragRegion = drag.get('region');
						var dragLeft = dragXY[0] - (wspaceXY[0]);
						var dragTop = dragXY[1] - (wspaceXY[1]);

						dragChild.setStyles({
							'top': dragTop + 'px',
							'left': dragLeft + 'px'
						});
						drop.append(dragChild);
						dragChild.setAttribute('data-status','pending_delete');
//						R8.Workspace.addItemToViewSpace(dragChild, dragTop, dragLeft);
						R8.Workspace.addItemToViewSpace(dragChild);
					});
*/
				});
			},

			setupSliderAnim: function(Y, tIndex,cmdbar){
				var name = cmdbar.loadedTabs[tIndex]['name'];
				cmdbar.loadedTabs[tIndex].slideBarNode = Y.one('#' + name + '-slide-bar');
				cmdbar.loadedTabs[tIndex].sliderAnim = new Y.Anim({
					node: cmdbar.loadedTabs[tIndex].slideBarNode,
					duration: 0.3,
				});
				//TODO: fix bug around non uniqueness on l/r buttons for scrolling
				cmdbar.loadedTabs[tIndex]['events']['slider_anim'] = cmdbar.loadedTabs[tIndex].sliderAnim.on('end', function(){
					cmdbar.loadedTabs[tIndex].sliderInMotion = false;
				});
				cmdbar.loadedTabs[tIndex]['events']['lbtn_click'] = Y.on('click', cmdbar.loadedTabs[tIndex].slideLeft,'#' + name + '-lbutton',cmdbar.loadedTabs[tIndex],cmdbar);
				cmdbar.loadedTabs[tIndex]['events']['rbtn_click'] = Y.on('click', cmdbar.loadedTabs[tIndex].slideRight,'#' + name + '-rbutton',cmdbar.loadedTabs[tIndex],cmdbar);
			},
			slideLeft: function(e,cmdbar){
				var tIndex = cmdbar.getTabIndexByName(this.name);
				if (cmdbar.loadedTabs[tIndex].sliderInMotion) return;
				else cmdbar.loadedTabs[tIndex].sliderInMotion = true;

				cmdbar.loadedTabs[tIndex].sliderAnim.set('to', {
					xy: [cmdbar.loadedTabs[tIndex].slideBarNode.getX() - 510, cmdbar.loadedTabs[tIndex].slideBarNode.getY()]
				});
				cmdbar.loadedTabs[tIndex].sliderAnim.run();
			},
			slideRight: function(e,cmdbar){
				var tIndex = cmdbar.getTabIndexByName(this.name);
				if (cmdbar.loadedTabs[tIndex].sliderInMotion) return;
				else cmdbar.loadedTabs[tIndex].sliderInMotion = true;

//TODO: figure out how to make the x param dynamic based on component width
				cmdbar.loadedTabs[tIndex].sliderAnim.set('to', {
					xy: [cmdbar.loadedTabs[tIndex].slideBarNode.getX() + 510, cmdbar.loadedTabs[tIndex].slideBarNode.getY()]
				});
				cmdbar.loadedTabs[tIndex].sliderAnim.run();
			},
				
			slideBarNode: null,
			sliderAnim: null,
			sliderInMotion: false,
			sliderSetup: false,
		},
		//end node tabDef
		'component-search': {
			'name': '',
			'i18n': '',
			'status': '',
			'node': null,
			'events': {},
			'contentLoader': function(containerNode){
				var name = this.name;
//				var width = R8.Workspace.viewPortRegion['width'] - 40;
				var width = containerNode.get('region').width - 40;
				var slideContainerWidth = width - 4;

				var contentFraming = '<div id="' + name + '-slide-wrapper" class="slide-wrapper" style="width: ' + width + 'px; margin-top: 10px;">';
				contentFraming += 	'<div id="' + name + '-lbutton" class="lbutton"></div>';
				contentFraming += 	'<div class="slide-l-shade">';
				contentFraming +=		'<div class="shade-top"></div>';
				contentFraming += 		'<div class="shade-body"></div>';
				contentFraming += 		'<div class="shade-bottom"></div>';
				contentFraming += 	'</div>';
				contentFraming += 	'<div id="' + name + '-list-container" class="slide-container" style="width: ' + slideContainerWidth + 'px;">';
				contentFraming +=		'<div class="slide-container-header"></div>';
				contentFraming += 		'<div id="' + name + '-slider"></div>';
				contentFraming += 	'</div>';
				contentFraming += 	'<div class="slide-r-shade">';
				contentFraming +=		'<div class="shade-top"></div>';
				contentFraming += 		'<div class="shade-body"></div>';
				contentFraming += 		'<div class="shade-bottom"></div>';
				contentFraming += 	'</div>';
				contentFraming += 	'<div id="' + name + '-rbutton" class="rbutton"></div>';
				contentFraming += '</div>';
				document.getElementById('cmdbar-' + this.name + '-tab-content').innerHTML = contentFraming;
					
				var wrapperId = '#' + name + '-slide-wrapper';
				var wrapperResizeCallback = {
					'nodeId': wrapperId,
					'lambda': function(height, width){
						var width = width - 40;
						return {
							'width': width
						};
					}
				};
//DEBUG
//				R8.Workspace.addResizeCallback(wrapperResizeCallback);

				var sliderId = '#' + name + '-list-container';
				var sliderResizeCallback = {
					'nodeId': sliderId,
					'lambda': function(height, width){
						var width = width - 44;
						return {
							'width': width
						};
					}
				};
//DEBUG
//				R8.Workspace.addResizeCallback(sliderResizeCallback);
			},
				
			'focus': function(cmdbar){
				var tIndex = cmdbar.getTabIndexByName(this.name);

				YUI().use("node", function(Y){
					cmdbar.loadedTabs[tIndex]['events']['slider_key_press'] = Y.one('document').on("keypress", function(e){
						if (e.keyCode == 37) {
							cmdbar.loadedTabs[tIndex].slideLeft(e,cmdbar);
//								e.halt();
						}
						else if (e.keyCode == 39) {
							cmdbar.loadedTabs[tIndex].slideRight(e,cmdbar);
//								e.halt();
						}
					});
				});
			},

			'blur': function(cmdbar){
				var tIndex = cmdbar.getTabIndexByName(this.name);

				if (typeof(cmdbar.loadedTabs[tIndex]['events']['slider_key_press']) != 'undefined') {
					cmdbar.loadedTabs[tIndex]['events']['slider_key_press'].detach();
				}
			},

			'clearContent': function(){
			},

			deleteCleanup: function(){
				var nodeId = '#' + this.name + '-list-container';
//DEBUG
//				R8.Workspace.cancelResizeCallback(nodeId);
				this.sliderAnim = null;
				this.slideBarNode = null;
			},

			//------------Search Specific Functions/Callbacks---------
			startSearch: function(ioId, arguments){
			},

			endSearch: function(ioId, arguments){
			},

			clearSlider: function(){
				if (this.slideBarNode === null) 
					return;
				//DEBUG
				//console.log('Going to clear everything out...');
				this.events['slider_anim'].detach();
				delete (this.events['slider_anim']);
				this.events['lbtn_click'].detach();
				delete (this.events['lbtn_click']);
				this.events['rbtn_click'].detach();
				delete (this.events['rbtn_click']);

				//TODO: figure out why slider_key_press throws undefined error after a 2nd search is run
				this.events['slider_key_press'].detach();
				delete (this.events['slider_key_press']);

				this.sliderAnim = null;
				this.slideBarNode = null;
				this.sliderSetup = false;
				document.getElementById(this.name + '-list-container').innerHTML = '';
			},

			initSlider: function(tabName,cmdbar){
				var tIndex = cmdbar.getTabIndexByName(tabName);
				if (document.getElementById(tabName + '-slide-bar') == null) {
					var initSliderCallback = function(){
						cmdbar.loadedTabs[tIndex].initSlider(tabName);
					}
					setTimeout(initSliderCallback, 100);
					return;
				}
				cmdbar.loadedTabs[tIndex].setupDD(cmdbar);
					
				YUI().use('anim', function(Y){
					cmdbar.loadedTabs[tIndex].setupSliderAnim(Y, tIndex,cmdbar);
				});
				cmdbar.loadedTabs[tIndex].sliderSetup = true;
			},

			setupDD: function(cmdbar){
				var name = this.name;
				var tIndex = cmdbar.getTabIndexByName(name);

				YUI().use('dd-delegate', 'dd-proxy', 'node', 'dd-drop-plugin', function(Y){
					cmdbar.loadedTabs[tIndex].compDDel = new Y.DD.Delegate({
						cont: '#' + name + '-slide-bar',
						nodes: 'div.component-drag',
					});
					cmdbar.loadedTabs[tIndex].compDDel.dd.plug(Y.Plugin.DDProxy, {
						moveOnEnd: false,
						borderStyle: false,
					});

					cmdbar.loadedTabs[tIndex].compDDel.on('drag:mouseDown', function(e){
						var componentType = this.get('currentNode').get('children').item(0).getAttribute('data-type');

						var vspaceNode = Y.one('#'+cmdbar.get('containerNode').get('id'));

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
									cmdbar.get('viewSpace').addAssemblyToViewspace(componentId,'node',assemblyLeftPos,dropNode);
								});
							}
						} else {
							var dropGroup = 'dg-component';
							var dropList = Y.all('#'+vspaceNode.get('id')+' div.'+dropGroup);

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

//										cmdbar.get('viewSpace').addComponentToContainer(componentId,dropNode);
									});
								}
							});
						}
					});

					cmdbar.loadedTabs[tIndex].compDDel.on('drag:start', function(e){
						var drag = this.get('dragNode'), c = this.get('currentNode');
						drag.set('innerHTML',c.get('innerHTML'));
						drag.setAttribute('class', c.getAttribute('class'));
						this.dd.addToGroup('dg-component');
						drag.setStyles({
							opacity: .5,
						});
					});
				});
			},

			setupSliderAnim: function(Y, tIndex,cmdbar){
				var name = cmdbar.loadedTabs[tIndex]['name'];
				cmdbar.loadedTabs[tIndex].slideBarNode = Y.one('#' + name + '-slide-bar');

				//DEBUG
				cmdbar.loadedTabs[tIndex].listContainer = Y.one('#' + name + '-list-container');

				cmdbar.loadedTabs[tIndex].sliderAnim = new Y.Anim({
					node: cmdbar.loadedTabs[tIndex].slideBarNode,
					duration: 0.3,
				});
				//TODO: fix bug around non uniqueness on l/r buttons for scrolling
				cmdbar.loadedTabs[tIndex]['events']['slider_anim'] = cmdbar.loadedTabs[tIndex].sliderAnim.on('end', function(){
					cmdbar.loadedTabs[tIndex].sliderInMotion = false;
				});
				cmdbar.loadedTabs[tIndex]['events']['lbtn_click'] = Y.on('click', cmdbar.loadedTabs[tIndex].slideLeft,'#'+name+'-lbutton',cmdbar.loadedTabs[tIndex],cmdbar);
				cmdbar.loadedTabs[tIndex]['events']['rbtn_click'] = Y.on('click', cmdbar.loadedTabs[tIndex].slideRight,'#'+name+'-rbutton',cmdbar.loadedTabs[tIndex],cmdbar);
			},
			slideLeft: function(e,cmdbar){
				var tIndex = cmdbar.getTabIndexByName(this.name);
				var containerRgn = cmdbar.loadedTabs[tIndex].listContainer.get('region'),
					sliderRgn = cmdbar.loadedTabs[tIndex].slideBarNode.get('region');

				if (cmdbar.loadedTabs[tIndex].sliderInMotion || (sliderRgn.right <= containerRgn.right))
					return;
				else
					cmdbar.loadedTabs[tIndex].sliderInMotion = true;

				cmdbar.loadedTabs[tIndex].sliderAnim.set('to', {
					xy: [cmdbar.loadedTabs[tIndex].slideBarNode.getX() - 510, cmdbar.loadedTabs[tIndex].slideBarNode.getY()]
				});
				cmdbar.loadedTabs[tIndex].sliderAnim.run();
			},
			slideRight: function(e,cmdbar){
				var tIndex = cmdbar.getTabIndexByName(this.name);
				var containerRgn = cmdbar.loadedTabs[tIndex].listContainer.get('region'),
					sliderRgn = cmdbar.loadedTabs[tIndex].slideBarNode.get('region');

				if (cmdbar.loadedTabs[tIndex].sliderInMotion || (sliderRgn.left >= containerRgn.left)) 
					return;
				else 
					cmdbar.loadedTabs[tIndex].sliderInMotion = true;
				//TODO: figure out how to make the x param dynamic based on component width
				cmdbar.loadedTabs[tIndex].sliderAnim.set('to', {
					xy: [cmdbar.loadedTabs[tIndex].slideBarNode.getX() + 510, cmdbar.loadedTabs[tIndex].slideBarNode.getY()]
				});
				cmdbar.loadedTabs[tIndex].sliderAnim.run();
			},
				
			slideBarNode: null,
			sliderAnim: null,
			sliderInMotion: false,
			sliderSetup: false,
		},
		//end node tabDef
	}
	//end tabDefs
};
