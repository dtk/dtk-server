
if (!R8.MainToolbar) {

	(function(R8) {
		R8.MainToolbar = function(options) {
			return {
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
console.log('Searching for:'+queryTerm);
//(route, args, callBacks) {
					var callbacks = {
						'io:start':R8.MainToolbar.startSearch(),
						'io:end':R8.MainToolbar.endSearch()
					};
					R8.Ctrl.call('workspace/search',queryTerm,callbacks);

//						this.searchNodes(queryTerm);
					}
				},

				startSearch : function(ioId,arguments) {
console.log('....Started Search');
				},

				endSearch : function(ioId,arguments) {
console.log('....Finished Search');
				},

				searchNodes: function(queryTerm) {
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

				slider_status: 'closed'
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
