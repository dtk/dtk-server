
if (!R8.MainToolbar) {

	(function(R8) {
		R8.MainToolbar = function(options) {
			return {
				init : function() {
//					autocomplete('sq',{'delay':100,'uri':'http://yahoo.com','callback':R8.MainToolbar.search});
					autocomplete('sq',{'delay':2000,'uri':'http://yahoo.com','callback':ac_request});
				},

				toggleSlider: function(){
					R8.Utils.$("#sliderbar").slideToggle(100);
					var slider_display = document.getElementById('sliderbar').style.display;
					if(slider_display.toLowerCase() == 'block') R8.MainToolbar.sliderStatus = 'open';
					else this.sliderStatus = 'closed';
				},
				search: function() {
					var basicSearch = true;
					var sboxElem = document.getElementById('sq');

					if(R8.MainToolbar.sliderStatus=='closed') R8.MainToolbar.toggleSlider();

					R8.MainToolbar.clearSlider();
					if(basicSearch == true) {
						var queryTerm = 'sq=' + sboxElem.value;
						var callbacks = {
							'io:start':R8.MainToolbar.startSearch(),
							'io:end':R8.MainToolbar.endSearch(),
							'io:renderComplete':R8.MainToolbar.initSlider(),
						};
						R8.Ctrl.call('workspace/search',queryTerm,callbacks);
					}
				},
				addComponent: function(obj_id) {
					var sboxElem = document.getElementById('sq');

					if(this.sliderStatus=='closed') R8.MainToolbar.toggleSlider();

					if(basicSearch == true) {
						var queryTerm = 'sq=' + sboxElem.value;
						var callbacks = {
							'io:start':R8.MainToolbar.startSearch(),
							'io:end':R8.MainToolbar.endSearch(),
							'io:renderComplete':R8.MainToolbar.initSlider(),
						};
						R8.Ctrl.call('workspace/search',queryTerm,callbacks);
					}
				},

				startSearch : function(ioId,arguments) {
				},

				endSearch : function(ioId,arguments) {
				},

				searchNodes: function(queryTerm) {
				},

				initSlider: function() {
					if(document.getElementById('slide_bar') == null) {
						var initSliderCallback = function() { R8.MainToolbar.initSlider(); }
						setTimeout(initSliderCallback,100);
						return;
					}
testing();
					YUI().use('anim', function(Y) {
						R8.MainToolbar.sliderBarNode = Y.one('#slide_bar');
						R8.MainToolbar.sliderAnim = new Y.Anim({
							node: R8.MainToolbar.sliderBarNode,
							duration: 0.3,
						});
						R8.MainToolbar.sliderEvents['slider_anim'] = R8.MainToolbar.sliderAnim.on('end',function(){ R8.MainToolbar.sliderInMotion = false;});

						var slideLeft = function(e) {
							if(R8.MainToolbar.sliderInMotion) return;
							else R8.MainToolbar.sliderInMotion = true;
					
							R8.MainToolbar.sliderAnim.set('to', { xy: [R8.MainToolbar.sliderBarNode.getX()-510, R8.MainToolbar.sliderBarNode.getY()] });
							R8.MainToolbar.sliderAnim.run();
						};
						var slideRight = function(e) {
							if(R8.MainToolbar.sliderInMotion) return;
							else R8.MainToolbar.sliderInMotion = true;
							//TODO: figure out how to make the x param dynamic based on component width					
							R8.MainToolbar.sliderAnim.set('to', { xy: [R8.MainToolbar.sliderBarNode.getX()+510, R8.MainToolbar.sliderBarNode.getY()] });
							R8.MainToolbar.sliderAnim.run();
						};

						R8.MainToolbar.sliderEvents['lbtn_click'] = Y.one('#lbutton').on('click', slideLeft);
						R8.MainToolbar.sliderEvents['rbtn_click'] = Y.one('#rbutton').on('click', slideRight);

						YUI().use("node", function(Y) {
							R8.MainToolbar.sliderEvents['slider_key_press'] = Y.get('document').on("keypress", function(e) {
								var key = {
									'code': e.keyCode,
									'char': String.fromCharCode(e.keyCode),
									'dir_code' : 0,
									'alt': e.altKey,
									'ctrl': e.ctrlKey,
									'shift': e.shiftKey
								};
								if (e.keyCode == 37) {
									slideLeft();
//									e.halt();
								} else if(e.keyCode == 39) {
									slideRight();
//									e.halt();
								}
							});
						});

					});
					R8.MainToolbar.sliderSetup = true;
				},

				clearSlider : function() {
					if(R8.MainToolbar.sliderBarNode === null) return;

					for(e in R8.MainToolbar.sliderEvents) {
						R8.MainToolbar.sliderEvents[e].detach();
						delete(R8.MainToolbar.sliderEvents[e]);
					}
					R8.MainToolbar.sliderAnim = null;
					R8.MainToolbar.sliderBarNode = null;
					R8.MainToolbar.sliderSetup = false;
					document.getElementById('slidecontainer').innerHTML = '';
console.log('Done Clearing shite out!!!!');
				},

				addSet : function(setObj) {
				},
				addTool : function(tool){
					this.tools[tool.name] = tool.def;
				},
				tools : {},

				//this stores the list of currently loaded main toolbar sets
				tool_sets : {},
				//this stores teh list of currently loaded items that are referenced in sets
				tools : {},

				sliderStatus: 'closed',
				sliderSetup : true,
				sliderInMotion : false,
				sliderBarNode : null,
				sliderAnim : null,
				sliderEvents : {},
			}
		}();
	})(R8);
}

var plugin = {
	name: 'monitoring',
	creator: 'R8',
	description: 'A psuedo test plugin-in to manage monitoring on nodes',
	moverIcon: 'someicon.png',
	clickIcon: 'someicno.png',
	activeIcon: 'someicon.png',
	def: {
		open: function() {
			console.log('should open the plugin');
		},
		help: function() {
//			console.log('Should show help');
		}
	}
}

R8.MainToolbar.addTool(plugin);
R8.MainToolbar.tools['monitoring'].help();
//console.log(R8.MainToolbar.tools.prototype);
function testing(){
	YUI().use('dd-delegate', 'dd-proxy', 'dd-drop','dd-drop-plugin','node', function(Y){
		var compDDel = new Y.DD.Delegate({
			cont: '#slide_bar',
//			nodes: 'div.component',
			nodes: 'div.avail_item',
			dragMode: 'intersect',
		});
		
		compDDel.dd.plug(Y.Plugin.DDProxy, {
			moveOnEnd: false,
			cloneNode: true
		});

		compDDel.on('drag:start', function(e){
			var drag = this.get('dragNode'), c = this.get('currentNode');
			drag.setAttribute('class', c.getAttribute('class'));
			this.dd.addToGroup('workspace_drop');
			drag.setStyles({
				opacity: .3,
			});
		});
		/*
		 //setup the drop targets for the keys in the layout
		 var keyDropList = Y.Node.all('#layoutTable li');
		 keyDropList.each(function(keyNode, index) {
		 availKeysDDel.createDrop(keyNode,['layout_drop']);
		 });
		 */
//		var testnode = Y.one('#mainWorkspace');
//console.log(testnode);
//		compDDel.createDrop(Y.one('#mainWorkspace'), ['workspace_drop']);
//console.log('asdfasdfasdfasdfasdf');

		var drop = Y.one('#mainWorkspace').plug(Y.Plugin.Drop);
		drop.drop.addToGroup(['workspace_drop']);

		compDDel.on('drag:drophit', function(e){
			var drop = e.drop.get('node'), drag = this.get('dragNode');
			var item_id = drag.getAttribute('data-id');
			var model_name = drag.getAttribute('data-model-name');

			var dragChild = drag.get('children').item(0).cloneNode(true);
			var d = new Date();
			var new_comp_id = d.getTime();
			dragChild.set('id','wi_'+new_comp_id);

			var wspaceElem = R8.Utils.Y.one('#mainWorkspace');
			var wspaceXY = wspaceElem.getXY();
			var dragXY = drag.getXY();
			var dragLeft = dragXY[0] - (wspaceXY[0]);
			var dragTop = dragXY[1] - (wspaceXY[1]);
			dragChild.setStyles({'top':dragTop+'px','left':dragLeft+'px'});
			drop.append(dragChild);
		});
	});
}
/*
YUI().use('node', function(Y){
	var docNode = Y.one(document);
	docNode.on('click',function(e){
		var mouseX = e.clientX;
		var mouseY = e.clientY;
		console.log('Mouse is at X:'+mouseX+'  Y:'+mouseY);
	});
});
*/

//auto complete testing
var autocomplete_list = {};

function autocomplete(input_id,config) {

	autocomplete_list[input_id] = {
		'config':config,
		'delay':config['delay'],
	}
	YUI().use("node", function(Y) {
		autocomplete_list[input_id]['key_up_event'] = Y.one('#'+input_id).on("keyup", function(e) {
			var key = {
				'code': e.keyCode,
				'char': String.fromCharCode(e.keyCode),
				'dir_code' : 0,
				'alt': e.altKey,
				'ctrl': e.ctrlKey,
				'shift': e.shiftKey
			};

			if(typeof(autocomplete_list[input_id]['config']['delay']) === 'undefined')
				autocomplete_list[input_id]['config']['delay'] = 50;

			var ac_callback = function() {
				autocomplete_list[input_id]['config']['callback'](input_id);
			}
			autocomplete_list[input_id]['ac_callback'] = setTimeout(ac_callback,autocomplete_list[input_id]['config']['delay']);
console.log('Created timeout:'+autocomplete_list[input_id]['ac_callback']);
	//		e.halt();
		});
	});

	YUI().use("node", function(Y) {
		autocomplete_list[input_id]['key_down_event'] = Y.one('#'+input_id).on("keydown", function(e) {
			if (typeof(autocomplete_list[input_id]['ac_callback']) != 'undefined') {
console.log('Should clear timeout for:'+autocomplete_list[input_id]['ac_callback']);
				clearTimeout(autocomplete_list[input_id]['ac_callback']);
			}
		});
	});

}

function ac_request(input_id) {
	var input_elem = document.getElementById(input_id);
	if(input_elem.value ==='') return;

console.log('AutoCompete Req Value:'+input_elem.value);
}
