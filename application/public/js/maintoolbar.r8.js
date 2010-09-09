
if (!R8.MainToolbar) {

	(function(R8) {
		R8.MainToolbar = function(options) {
			return {
				init : function() {},

				toggleSlider: function(){
					R8.Utils.$("#sliderbar").slideToggle(100);
					var slider_display = document.getElementById('sliderbar').style.display;
					if(slider_display.toLowerCase() == 'block') this.slider_status = 'open';
					else this.slider_status = 'closed';
				},
				search: function() {
					var basicSearch = true;
					var sboxElem = document.getElementById('sq');

					if(this.slider_status=='closed') this.toggleSlider();

					if(basicSearch == true) {
						var queryTerm = 'sq=' + sboxElem.value;
						var callbacks = {
							'io:start':R8.MainToolbar.startSearch(),
							'io:end':R8.MainToolbar.endSearch(),
							'io:renderComplete':this.initSlider(),
						};
						R8.Ctrl.call('workspace/search',queryTerm,callbacks);
					}
				},
				addComponent: function(obj_id) {
					var sboxElem = document.getElementById('sq');

					if(this.slider_status=='closed') this.toggleSlider();

					if(basicSearch == true) {
						var queryTerm = 'sq=' + sboxElem.value;
						var callbacks = {
							'io:start':R8.MainToolbar.startSearch(),
							'io:end':R8.MainToolbar.endSearch(),
							'io:renderComplete':this.initSlider(),
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
						var slideBarNode = Y.one('#slide_bar');
						var anim = new Y.Anim({
							node: slideBarNode,
							duration: 0.3,
						});
						anim.on('end',function(){ R8.MainToolbar.sliderInMotion = false;});
					
						var slideLeft = function(e) {
							if(R8.MainToolbar.sliderInMotion) return;
							else R8.MainToolbar.sliderInMotion = true;
					
							anim.set('to', { xy: [slideBarNode.getX()-510, slideBarNode.getY()] });
							anim.run();
						};
						var slideRight = function(e) {
							if(R8.MainToolbar.sliderInMotion) return;
							else R8.MainToolbar.sliderInMotion = true;
					
							anim.set('to', { xy: [slideBarNode.getX()+510, slideBarNode.getY()] });
							anim.run();
						};

						Y.one('#lbutton').on('click', slideLeft);
						Y.one('#rbutton').on('click', slideRight);

						YUI().use("node", function(Y) {
							R8.MainToolbar.sliderKeyPress = Y.get('document').on("keypress", function(e) {
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
									e.halt();
								} else if(e.keyCode == 39) {
									slideRight();
									e.halt();
								}
							});
						});

					});
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

				slider_status: 'closed',
				sliderInMotion : false,
				sliderKeyPress : null,
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
			dragMode: 'intersect'
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
				opacity: .5
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

//			var dropCloneNode = Y.one('#item_'+item_id).cloneNode(true);
			var dragChild = drag.get('children').item(0).cloneNode(true);
			var d = new Date();
			var new_comp_id = d.getTime();

			dragChild.set('id',new_comp_id);
			dragChild.setStyles({'top':'0px','left':'0px'});
			drop.append(dragChild);

			//		var drop_id = drop.get('id');
			//		var drag_id = dragChild.get('id');
			//		console.log('Drop Id:'+drop_id+'     Drag ID:'+drag_id);
		});
	});
}

YUI().use('node', function(Y){
	var docNode = Y.one(document);
	docNode.on('click',function(e){
		var mouseX = e.clientX;
		var mouseY = e.clientY;
		console.log('Mouse is at X:'+mouseX+'  Y:'+mouseY);
	});
});