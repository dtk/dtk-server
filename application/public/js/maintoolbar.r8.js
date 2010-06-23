
if (!R8.MainToolbar) {

	(function(R8) {
		R8.MainToolbar = function(options) {
			return {
				toggleSlider: function(){
					R8.utils.$("#sliderbar").slideToggle(100);
					var slider_display = document.getElementById('sliderbar').style.display;
					if(slider_display.toLowerCase() == 'block') this.slider_status = 'open';
					else this.slider_status = 'closed';
				},
				search: function() {
					var basicSearch = true;
					var sboxElem = document.getElementById('sq');

					if(this.slider_status=='closed') this.toggleSlider();

					if(basicSearch == true) {
						var queryTerm = 'name=' + sboxElem.value;
console.log('Searching for:'+queryTerm);
						this.searchNodes(queryTerm);
					}
				},

				searchNodes: function(queryTerm) {
					YUI().use('io','io-base', function(Y) {

						var cfg = {
							method: "GET",
							data: queryTerm
						};

						var success = function(ioId, o) {
							if(o.responseText !== undefined) {
								eval("var response =" + o.responseText);
//								console.log(o.responseText);
								console.log(response);
							} else {
								console.log('respnose is undefined');
							}
						};
				 		var failure = function(ioId, o) {
							if(o.responseText !== undefined) {
								console.log(o.responseText);
							} else {
								console.log('respnose is undefined');
							}
						};
				
						Y.on('io:start', console.log('starting io request.....'));
						Y.on('io:success', success);
						Y.on('io:failure', failure);
						Y.on('io:end', console.log('finished io request'));
//						var base_url = 'http://172.22.101.112:7000/xyz/workspace/testsearch';
						var base_url = 'http://localhost:7000/xyz/node/list.json';
						var request = Y.io(base_url, cfg);
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
			console.log('Should show help');
		}
	}
}

R8.MainToolbar.addTool(plugin);
R8.MainToolbar.tools['monitoring'].help();


//console.log(R8.MainToolbar.tools.prototype);
