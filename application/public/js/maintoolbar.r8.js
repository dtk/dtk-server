
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
				toolbar_sets : [],
				//this stores teh list of currently loaded items that are referenced in sets
				toolbar_items : [],

			}
		}();
	})(R8);
}

var testTool = {
	name: 'ssh',
	def: function() { console.log('GOT IT!!!'); }
}

R8.MainToolbar.addTool(testTool);
R8.MainToolbar.tools.ssh();


//console.log(R8.MainToolbar.tools.prototype);
