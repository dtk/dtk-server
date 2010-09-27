R8.Cmdbar.cmdHandlers['search'] = {
	'cmdSubmit':function(cmdList) {
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

		if (R8.Cmdbar.tabExists(tabName)) {
//TODO: need to port all maintoolbar stuff over to tab definition
//								R8.Cmdbar.loadedTabs[tabIndex].clearContent();
			var tabIndex = R8.Cmdbar.getTabIndexByName(tabName);
			R8.Cmdbar.loadedTabs[tabIndex].clearSlider();
		} else {
			var newTab = R8.Cmdbar.cloneTabObj(this.tabDefs[tabName]);
			newTab.name = tabName;
			newTab['i18n'] = tabI18n;
			var tabIndex = R8.Cmdbar.addTab(newTab);
			R8.Cmdbar.registerTabEvents(tabIndex);
		}
//TODO: needed registerTabEvents seperated out from addTab b/c of some weird timing issues or something, need to revisit and hopefully consolidate
		R8.Cmdbar.changeTabFocus(tabIndex);
		if(!R8.Cmdbar.tabsPaneOpen) R8.Cmdbar.toggleTabs();

		for(term in qList) {
			if(queryTerm !='') queryTerm +='&';
				queryTerm += qList[term]['name']+'='+qList[term]['value'];
		}
		var tabName = this.name;
		var renderCompleteCallback = function() {
			R8.Cmdbar.loadedTabs[tabIndex].initSlider(R8.Cmdbar.loadedTabs[tabIndex].name);
		}
		var callbacks = {
			'io:start' : R8.Cmdbar.loadedTabs[tabIndex].startSearch,
			'io:end' : R8.Cmdbar.loadedTabs[tabIndex].endSearch,
			'io:renderComplete' : renderCompleteCallback,
		};
		R8.Ctrl.call('workspace/search',queryTerm,callbacks);
	},

	'tabDefs': {
		'node-search': {
			'name': '',
			'i18n': '',
			'status': '',
			'node': null,
			'events': {},
			'contentLoader': function(){
				var name = this.name;
				var width = R8.Workspace.viewPortRegion['width'] - 65;
				var contentFraming = '<div class="slider-top"></div>';
				contentFraming += '<div id="' + name + '-slider-wrapper" class="slider-wrapper">';
				contentFraming += '<div id="' + name + '-lbutton" class="lbutton"></div>';
				contentFraming += '<div id="' + name + '-list-container" class="slide-list-container" style="width: ' + width + 'px;">';
				contentFraming += '<div id="' + name + '-slider"></div>';
				contentFraming += '</div>';
				contentFraming += '<div id="' + name + '-rbutton" class="rbutton"></div>';
				contentFraming += '</div>';
				contentFraming += '<div class="slider-btm"></div>';
				document.getElementById('cmdbar-' + this.name + '-tab-content').innerHTML = contentFraming;
					
				var nodeId = '#' + name + '-list-container';
				var resizeCallback = {
					'nodeId': nodeId,
					'lambda': function(height, width){
						var width = width - 65;
						return {
							'width': width
						};
					}
				};
				R8.Workspace.addResizeCallback(resizeCallback);
			},
				
			'focus': function(){
				var tIndex = R8.Cmdbar.getTabIndexByName(this.name);

				YUI().use("node", function(Y){
					R8.Cmdbar.loadedTabs[tIndex]['events']['slider_key_press'] = Y.get('document').on("keypress", function(e){
						if (e.keyCode == 37) {
							R8.Cmdbar.loadedTabs[tIndex].slideLeft();
//								e.halt();
						}
						else if (e.keyCode == 39) {
							R8.Cmdbar.loadedTabs[tIndex].slideRight();
//								e.halt();
						}
					});
				});
			},
				
			'blur': function(){
				var tIndex = R8.Cmdbar.getTabIndexByName(this.name);
				//DEBUG
				//console.log('Blurring for:'+this.name);
				//console.log(R8.Cmdbar.loadedTabs[tIndex]['events']);
				if (typeof(R8.Cmdbar.loadedTabs[tIndex]['events']['slider_key_press']) != 'undefined') {
					R8.Cmdbar.loadedTabs[tIndex]['events']['slider_key_press'].detach();
				}
			},
				
			'clearContent': function(){
			},
				
			deleteCleanup: function(){
				var nodeId = '#' + this.name + '-list-container';
				R8.Workspace.cancelResizeCallback(nodeId);
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
				
			initSlider: function(tabName){
				var tIndex = R8.Cmdbar.getTabIndexByName(tabName);
				if (document.getElementById(tabName + '-slide-bar') == null) {
					var initSliderCallback = function(){
						R8.Cmdbar.loadedTabs[tIndex].initSlider(tabName);
					}
					setTimeout(initSliderCallback, 100);
					return;
				}
				R8.Cmdbar.loadedTabs[tIndex].setupDD();
					
				YUI().use('anim', function(Y){
					R8.Cmdbar.loadedTabs[tIndex].setupSliderAnim(Y, tIndex);
				});
				R8.Cmdbar.loadedTabs[tIndex].sliderSetup = true;
			},
				
			setupDD: function(){
				var name = this.name;
				var tIndex = R8.Cmdbar.getTabIndexByName(name);
				YUI().use('dd-delegate', 'dd-proxy', 'dd-drop', 'dd-drop-plugin', 'node', function(Y){
					R8.Cmdbar.loadedTabs[tIndex].compDDel = new Y.DD.Delegate({
						cont: '#' + name + '-slide-bar',
						nodes: 'div.avail_node',
	//					dragMode: 'intersect',
					});
						
					R8.Cmdbar.loadedTabs[tIndex].compDDel.dd.plug(Y.Plugin.DDProxy, {
						moveOnEnd: false,
						borderStyle: false,
//						cloneNode: true
					});

					R8.Cmdbar.loadedTabs[tIndex].compDDel.on('drag:start', function(e){
						var drag = this.get('dragNode'), c = this.get('currentNode');
						drag.set('innerHTML',c.get('innerHTML'));
						drag.setAttribute('class', c.getAttribute('class'));
						this.dd.addToGroup('viewspace_drop');
						drag.setStyles({
							opacity: .5,
							zIndex: 1000
						});
					});
						
					R8.Cmdbar.loadedTabs[tIndex].drop = Y.one('#viewspace').plug(Y.Plugin.Drop);
					R8.Cmdbar.loadedTabs[tIndex].drop.drop.addToGroup(['viewspace_drop']);
					//TODO: come back and add in clean up of DD objects and events
					R8.Cmdbar.loadedTabs[tIndex].compDDel.on('drag:drophit', function(e){
						var drop = e.drop.get('node'), drag = this.get('dragNode');
						var item_id = drag.getAttribute('data-id');
						var model_name = drag.getAttribute('data-model-name');
							
						var dragChild = drag.get('children').item(0).cloneNode(true);
						var d = new Date();
						var new_comp_id = d.getTime();
						dragChild.set('id', 'wi_' + new_comp_id);
							
						var wspaceElem = R8.Utils.Y.one('#viewspace');
						var wspaceXY = wspaceElem.getXY();
						var dragXY = drag.getXY();
						var dragLeft = dragXY[0] - (wspaceXY[0]);
						var dragTop = dragXY[1] - (wspaceXY[1]);
						dragChild.setStyles({
							'top': dragTop + 'px',
							'left': dragLeft + 'px'
						});
						drop.append(dragChild);
						R8.Workspace.addItemToViewSpace(dragChild, dragTop, dragLeft);
					});
				});
			},
				
			setupSliderAnim: function(Y, tIndex){
				var name = R8.Cmdbar.loadedTabs[tIndex]['name'];
				R8.Cmdbar.loadedTabs[tIndex].slideBarNode = Y.one('#' + name + '-slide-bar');
				R8.Cmdbar.loadedTabs[tIndex].sliderAnim = new Y.Anim({
					node: R8.Cmdbar.loadedTabs[tIndex].slideBarNode,
					duration: 0.3,
				});
				//TODO: fix bug around non uniqueness on l/r buttons for scrolling
				R8.Cmdbar.loadedTabs[tIndex]['events']['slider_anim'] = R8.Cmdbar.loadedTabs[tIndex].sliderAnim.on('end', function(){
					R8.Cmdbar.loadedTabs[tIndex].sliderInMotion = false;
				});
				R8.Cmdbar.loadedTabs[tIndex]['events']['lbtn_click'] = Y.on('click', R8.Cmdbar.loadedTabs[tIndex].slideLeft,'#' + name + '-lbutton',R8.Cmdbar.loadedTabs[tIndex]);
				R8.Cmdbar.loadedTabs[tIndex]['events']['rbtn_click'] = Y.on('click', R8.Cmdbar.loadedTabs[tIndex].slideRight,'#' + name + '-rbutton',R8.Cmdbar.loadedTabs[tIndex]);
			},
			slideLeft: function(e){
				var tIndex = R8.Cmdbar.getTabIndexByName(this.name);
				if (R8.Cmdbar.loadedTabs[tIndex].sliderInMotion) return;
				else R8.Cmdbar.loadedTabs[tIndex].sliderInMotion = true;

				R8.Cmdbar.loadedTabs[tIndex].sliderAnim.set('to', {
					xy: [R8.Cmdbar.loadedTabs[tIndex].slideBarNode.getX() - 510, R8.Cmdbar.loadedTabs[tIndex].slideBarNode.getY()]
				});
				R8.Cmdbar.loadedTabs[tIndex].sliderAnim.run();
			},
			slideRight: function(e){
				var tIndex = R8.Cmdbar.getTabIndexByName(this.name);
				if (R8.Cmdbar.loadedTabs[tIndex].sliderInMotion) return;
				else R8.Cmdbar.loadedTabs[tIndex].sliderInMotion = true;

//TODO: figure out how to make the x param dynamic based on component width
				R8.Cmdbar.loadedTabs[tIndex].sliderAnim.set('to', {
					xy: [R8.Cmdbar.loadedTabs[tIndex].slideBarNode.getX() + 510, R8.Cmdbar.loadedTabs[tIndex].slideBarNode.getY()]
				});
				R8.Cmdbar.loadedTabs[tIndex].sliderAnim.run();
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
			'contentLoader': function(){
				var name = this.name;
				var width = R8.Workspace.viewPortRegion['width'] - 65;
				var contentFraming = '<div class="slider-top"></div>';
				contentFraming += '<div id="' + name + '-slider-wrapper" class="slider-wrapper">';
				contentFraming += '<div id="' + name + '-lbutton" class="lbutton"></div>';
				contentFraming += '<div id="' + name + '-list-container" class="slide-list-container" style="width: ' + width + 'px;">';
				contentFraming += '<div id="' + name + '-slider"></div>';
				contentFraming += '</div>';
				contentFraming += '<div id="' + name + '-rbutton" class="rbutton"></div>';
				contentFraming += '</div>';
				contentFraming += '<div class="slider-btm"></div>';
				document.getElementById('cmdbar-' + this.name + '-tab-content').innerHTML = contentFraming;
					
				var nodeId = '#' + name + '-list-container';
				var resizeCallback = {
					'nodeId': nodeId,
					'lambda': function(height, width){
						var width = width - 65;
						return {
							'width': width
						};
					}
				};
				R8.Workspace.addResizeCallback(resizeCallback);
			},
				
			'focus': function(){
				var tIndex = R8.Cmdbar.getTabIndexByName(this.name);

				YUI().use("node", function(Y){
					R8.Cmdbar.loadedTabs[tIndex]['events']['slider_key_press'] = Y.get('document').on("keypress", function(e){
						if (e.keyCode == 37) {
							R8.Cmdbar.loadedTabs[tIndex].slideLeft();
//								e.halt();
						}
						else if (e.keyCode == 39) {
							R8.Cmdbar.loadedTabs[tIndex].slideRight();
//								e.halt();
						}
					});
				});
			},
				
			'blur': function(){
				var tIndex = R8.Cmdbar.getTabIndexByName(this.name);
				//DEBUG
				//console.log('Blurring for:'+this.name);
				//console.log(R8.Cmdbar.loadedTabs[tIndex]['events']);
				if (typeof(R8.Cmdbar.loadedTabs[tIndex]['events']['slider_key_press']) != 'undefined') {
					R8.Cmdbar.loadedTabs[tIndex]['events']['slider_key_press'].detach();
				}
			},
				
			'clearContent': function(){
			},
				
			deleteCleanup: function(){
				var nodeId = '#' + this.name + '-list-container';
				R8.Workspace.cancelResizeCallback(nodeId);
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
				
			initSlider: function(tabName){
				var tIndex = R8.Cmdbar.getTabIndexByName(tabName);
				if (document.getElementById(tabName + '-slide-bar') == null) {
					var initSliderCallback = function(){
						R8.Cmdbar.loadedTabs[tIndex].initSlider(tabName);
					}
					setTimeout(initSliderCallback, 100);
					return;
				}
				R8.Cmdbar.loadedTabs[tIndex].setupDD();
					
				YUI().use('anim', function(Y){
					R8.Cmdbar.loadedTabs[tIndex].setupSliderAnim(Y, tIndex);
				});
				R8.Cmdbar.loadedTabs[tIndex].sliderSetup = true;
			},
				
			setupDD: function(){
				var name = this.name;
				var tIndex = R8.Cmdbar.getTabIndexByName(name);
				YUI().use('dd-delegate', 'dd-proxy', 'dd-drop', 'dd-drop-plugin', 'node', function(Y){
					R8.Cmdbar.loadedTabs[tIndex].compDDel = new Y.DD.Delegate({
						cont: '#' + name + '-slide-bar',
						nodes: 'div.avail_component',
	//					dragMode: 'intersect',
					});
					R8.Cmdbar.loadedTabs[tIndex].compDDel.dd.plug(Y.Plugin.DDProxy, {
						moveOnEnd: false,
						borderStyle: false,
//						cloneNode: true
					});
R8.Cmdbar.loadedTabs[tIndex].compDDel.dd.addToGroup('node_drop');
					R8.Cmdbar.loadedTabs[tIndex].compDDel.on('drag:start', function(e){
						var drag = this.get('dragNode'), c = this.get('currentNode');
						drag.set('innerHTML',c.get('innerHTML'));
						drag.setAttribute('class', c.getAttribute('class'));
//						this.dd.addToGroup('node_drop');
						drag.setStyles({
							opacity: .7,
						});


						//create all the drop targets for each node in the viewspace
						R8.Cmdbar.loadedTabs[tIndex].dropList = Y.all('#viewspace div.node');

//TODO: revisit to look into necessity of unplugging drops on the target nodes
						R8.Cmdbar.loadedTabs[tIndex].dropList.each(function(){
var id = this.get('id');
console.log(this);
console.log(R8.Workspace.components[id]['node']);
//console.log(R8.Workspace.components[id]['node'].drop.inGroup(['node_drop']));
//							this.plug(Y.Plugin.Drop);
//							this.drop.addToGroup(['node_drop']);
						});
					});

					//TODO: come back and add in clean up of DD objects and events
					R8.Cmdbar.loadedTabs[tIndex].compDDel.on('drag:drophit', function(e){
						var drop = e.drop.get('node'), compNode = this.get('dragNode').get('children').item(0);
						var component_id = compNode.get('id');
						component_id = component_id.replace('component_','');
console.log('Going to call addComponentToContainer...');
return;
						R8.Workspace.addComponentToContainer(component_id,drop);
					});
				});
			},
				
			setupSliderAnim: function(Y, tIndex){
				var name = R8.Cmdbar.loadedTabs[tIndex]['name'];
				R8.Cmdbar.loadedTabs[tIndex].slideBarNode = Y.one('#' + name + '-slide-bar');
				R8.Cmdbar.loadedTabs[tIndex].sliderAnim = new Y.Anim({
					node: R8.Cmdbar.loadedTabs[tIndex].slideBarNode,
					duration: 0.3,
				});
				//TODO: fix bug around non uniqueness on l/r buttons for scrolling
				R8.Cmdbar.loadedTabs[tIndex]['events']['slider_anim'] = R8.Cmdbar.loadedTabs[tIndex].sliderAnim.on('end', function(){
					R8.Cmdbar.loadedTabs[tIndex].sliderInMotion = false;
				});
				R8.Cmdbar.loadedTabs[tIndex]['events']['lbtn_click'] = Y.on('click', R8.Cmdbar.loadedTabs[tIndex].slideLeft,'#'+name+'-lbutton',R8.Cmdbar.loadedTabs[tIndex]);
				R8.Cmdbar.loadedTabs[tIndex]['events']['rbtn_click'] = Y.on('click', R8.Cmdbar.loadedTabs[tIndex].slideRight,'#'+name+'-rbutton',R8.Cmdbar.loadedTabs[tIndex]);
			},
			slideLeft: function(e){
				var tIndex = R8.Cmdbar.getTabIndexByName(this.name);
				if (R8.Cmdbar.loadedTabs[tIndex].sliderInMotion) 
					return;
				else 
					R8.Cmdbar.loadedTabs[tIndex].sliderInMotion = true;
					
				R8.Cmdbar.loadedTabs[tIndex].sliderAnim.set('to', {
					xy: [R8.Cmdbar.loadedTabs[tIndex].slideBarNode.getX() - 510, R8.Cmdbar.loadedTabs[tIndex].slideBarNode.getY()]
				});
				R8.Cmdbar.loadedTabs[tIndex].sliderAnim.run();
			},
			slideRight: function(e){
				var tIndex = R8.Cmdbar.getTabIndexByName(this.name);
				if (R8.Cmdbar.loadedTabs[tIndex].sliderInMotion) 
					return;
				else 
					R8.Cmdbar.loadedTabs[tIndex].sliderInMotion = true;
				//TODO: figure out how to make the x param dynamic based on component width
				R8.Cmdbar.loadedTabs[tIndex].sliderAnim.set('to', {
					xy: [R8.Cmdbar.loadedTabs[tIndex].slideBarNode.getX() + 510, R8.Cmdbar.loadedTabs[tIndex].slideBarNode.getY()]
				});
				R8.Cmdbar.loadedTabs[tIndex].sliderAnim.run();
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
