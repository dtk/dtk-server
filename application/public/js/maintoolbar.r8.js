
if (!R8.MainToolbar) {

	(function(R8) {
		R8.MainToolbar = function(options) {
			return {
				toggleSlider: function(){
					R8.utils.$("#sliderbar").slideToggle(100);
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
			console.log('Should show help');
		}
	}
}

R8.MainToolbar.addTool(plugin);
R8.MainToolbar.tools['monitoring'].help();


//console.log(R8.MainToolbar.tools.prototype);
