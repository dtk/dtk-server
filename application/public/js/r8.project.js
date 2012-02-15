
if (!R8.Project) {

	R8.Project = function(projectDef) {
		var _def = projectDef,
			_wrapperNode = null,
			_rootNode = null,
			_leafNode = null,

			_implementations = {},
			_targets = {},

			_views = {},
			_initialized = false,
			_events = {};

		return {
			init: function() {
				//instantiate the targets and the implementations
				for(var t in _def.tree.targets) {
					var target = _def.tree.targets[t];
					_targets[target.id] = new R8.Target(target,this);
					_targets[target.id].init();
				}
//DEBUG
//console.log('going to instantiation implementations inside fo project.init....');
				for(var i in _def.tree.implementations) {
					var implementation = _def.tree.implementations[i];
//console.log(implementation);
					_implementations[implementation.id] = new R8.Implementation(implementation,this);
					_implementations[implementation.id].init();
				}

				this.setupEvents();
				_iniitialized = true;
			},
			get: function(key) {
				switch(key) {
					case "id":
						return _def.id;
						break;
					case "model":
						return "project";
						break;
					case "status":
						return _def.status;
						break;
					case "type":
					case "project_type":
						return _def.type;
						break;
					case "name":
						return _def.name;
						break;
					case "targets":
						return _targets;
						break;
					case "implementations":
						return _implementations;
						break;
				}
			},
			setupEvents: function() {
//				R8.IDE.on('node-'+this.get('id')+'-component-add',this.instantiateComponent,this);
			},
//-----------------------------------------------
//VIEW RELATED METHODS-------------------
//-----------------------------------------------
			requireView: function(viewType) {
				if(typeof(_views[viewType]) == 'undefined') _views[viewType] = {};

				_views[viewType] = new R8.IDE.View[viewType].project(this);

			},
			getView: function(viewType) {
				if(typeof(_views[viewType]) == 'undefined') this.requireView(viewType);

				return _views[viewType];
			},
			renderView: function(viewType) {
				if(typeof(_views[viewType]) == 'undefined') this.requireView(viewType);

				return _views[viewType].render();
			},
			isInitialized: function() {
				return _initialized;
			},
//-------------------------------------
//PROJECT SPECIFIC CALLS
//-------------------------------------
			hasImplementation: function(implementation_id) {
				for(var impId in _implementations) {
					if(impId == implementation_id) return true;
				}
				return false;
			},
			instantiateImplementationById: function(implementationId) {
				var _this = this;
				var successCallback = function(ioId,responseObj) {
						eval("var response =" + responseObj.responseText);
						var impTree = response.application_implementation_get_tree.content[0]['data'];
//DEBUG
//console.log('going to add new implementation tree...');
//console.log(impTree);
//return;
						_implementations[impTree.id] = new R8.Implementation(impTree,_this);
						_implementations[impTree.id].init();
						for(var v in _views) {
							_views[v].addImplementation(_implementations[impTree.id],true);
						}

//						this.addImplementation(implementations[i]);

//						_this.addImplementation(impTree);
				}
				var callbacks = {
					'io:success' : successCallback
				};

				R8.Ctrl.call('implementation/get_tree/'+implementationId,{
					'callbacks': callbacks,
					'cfg': {
						'data': 'project_id='+this.get('id')
					}
				});
			}
/*
			loadFileInEditor: function(fileId) {
				R8.Editor.loadFile(fileId);
			}
*/
		}
	};
}