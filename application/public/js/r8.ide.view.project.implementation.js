
if (!R8.IDE.View.project) { R8.IDE.View.project = {}; }

if (!R8.IDE.View.project.implementation) {

	R8.IDE.View.project.implementation = function(implementation) {
		var _implementation = implementation,
			_idPrefix = "implementation-leaf-",

			_leafNodeId = '',
			_leafNode = null,
			_leafBodyNodeId = '',
			_leafBodyNode = null,
			_childrenListNode = null,
			_childrenListNodeId = '',

			_componentsLeafNode = null,
			_componentsListNode = null,

			_leafDef = {
				'node_id': 'implementation-'+_implementation.get('id'),
				'type': _implementation.get('type'),
				'name': _implementation.get('name'),
				'basic_type': _implementation.get('type')
			},
			_events = {};

		return {
			init: function() {
				_leafNode = R8.Utils.Y.one('#'+_leafNodeId);
				_leafBodyNode = R8.Utils.Y.one('#'+_leafBodyNodeId);
				_childrenListNode = R8.Utils.Y.one('#'+_childrenListNodeId);

/*
				_componentsLeafNode = R8.Utils.Y.one('#implementation-components-'+_implementation.get('id'));
				_componentsListNode = R8.Utils.Y.one('#implementation-components-list-'+_implementation.get('id'));

				var components = _implementation.get('components');
				for(var c in components) {
					components[c].getView('project').init();
				}
*/
				this.setupEvents();
				_initialized = true;
			},
			setupEvents: function() {
				_events['leaf_dblclick'] = _leafBodyNode.on('dblclick',function(e){

					var leafNodeId = e.currentTarget.get('id'),
						leafType = e.currentTarget.getAttribute('type'),
						leafObjectId = leafNodeId.replace('leaf-body-'+leafType+'-',''),
						leafLabel = e.currentTarget.get('children').item(1).get('innerHTML');

//					R8.IDE.openEditorView(_implementation);
//DEBUG
//console.log('double clicked on implementation leaf:'+leafObjectId);
					e.halt();
					e.stopImmediatePropagation();
				},this);
			},
			render: function(newImplementation) {
				_leafNode = R8.Utils.Y.Node.create(R8.Rtpl['project_tree_leaf']({'leaf_item': _leafDef}));
				_leafNodeId = _leafNode.get('id');

				if(newImplementation==true) {
//					_leafNode.addClass('jstree-leaf');
					_leafNode.get('children').item(0).prepend('<ins class="jstree-icon">&nbsp;</ins>');
					_leafNode.prepend('<ins class="jstree-icon">&nbsp;</ins>');
				}

				_leafBodyNode = _leafNode.get('children').item(0);
				_leafBodyNodeId = _leafBodyNode.get('id');
				_childrenListNode = R8.Utils.Y.Node.create('<ul id="implementation-'+_implementation.get('id')+'-children"></ul>');
				_childrenListNodeId = _childrenListNode.get('id');

/*
				var componentsLeaf = {
					'node_id': 'implementation-components-'+_implementation.get('id'),
					'type': 'component_list',
					'basic_type': 'component_list',
					'name': 'Components',
//					'class': 'jstree-closed'
				};

				_componentsLeafNode = R8.Utils.Y.Node.create(R8.Rtpl['project_tree_leaf']({'leaf_item': componentsLeaf}));
				_componentsLeafNodeId = _componentsLeafNode.get('id');
				_componentsListNode = R8.Utils.Y.Node.create('<ul id="implementation-components-list-'+_implementation.get('id')+'"></ul>');
				_componentsListNodeId = _componentsListNode.get('id');

				var components = _implementation.get('components');
				for(var c in components) {
					this.addComponent(components[c],newImplementation);
				}

				_componentsLeafNode.append(_componentsListNode);
				if (newImplementation == true) {
					_componentsLeafNode.get('children').item(0).prepend('<ins class="jstree-icon">&nbsp;</ins>');
					_componentsLeafNode.prepend('<ins class="jstree-icon">&nbsp;</ins>');
				}
				_childrenListNode.append(_componentsLeafNode);
*/
				//Need to pass _childrenListNode to renderFileTree b/c of recursive behavior to render files and folders
				this.renderFileTree(_implementation.get('file_assets'),_childrenListNode,newImplementation);

				_leafNode.append(_childrenListNode);
				return _leafNode;
			},
			resize: function() {
			},
			get: function(key) {
				switch(key) {
					case "id":
						return _id;
						break;
					case "id-prefix":
						return "foo";
						break;
				}
			},
			focus: function() {
				this.resize();
			},
			blur: function() {
			},
			close: function() {
			},
//--------------------------------------
//IMPLEMENTATION VIEW FUNCTIONS
//--------------------------------------
			addComponent: function(component,newImplementation) {
				var componentLeafNode = component.getView('project').render();
				if(newImplementation==true) {
					componentLeafNode.addClass('jstree-leaf');
					componentLeafNode.get('children').item(0).prepend('<ins class="jstree-icon">&nbsp;</ins>');
					componentLeafNode.prepend('<ins class="jstree-icon">&nbsp;</ins>');
				}
				_componentsListNode.append(componentLeafNode);
			},
			renderFileTree: function(file_assets,listNode,newImplementation) {
//DEBUG
//console.log('Inside renderFileTree, listNode is:'+listNode);
//console.log(arguments);
				file_assets.sort(this.sortAssetTree);

				if (typeof(listNode) == 'undefined' || listNode == false) {
					var listNode = R8.Utils.Y.Node.create('<ul></ul>');
				}
				for(var f in file_assets) {
					switch(file_assets[f].model_name) {
						case "directory_asset":
							var ulDNode = R8.Utils.Y.Node.create('<ul></ul>');
							var dirLeaf = {
								'node_id': 'directory-'+f+'-'+file_assets[f].display_name,
//								'type': 'directory',
								'basic_type': 'directory',
								'name': file_assets[f].display_name
							};
							var fileNode = R8.Utils.Y.Node.create(R8.Rtpl['project_tree_leaf']({'leaf_item': dirLeaf}));
							if(newImplementation==true) {
//								fileNode.addClass('jstree-leaf');
								fileNode.get('children').item(0).prepend('<ins class="jstree-icon">&nbsp;</ins>');
								fileNode.prepend('<ins class="jstree-icon">&nbsp;</ins>');
							}
							fileNode.append(this.renderFileTree(file_assets[f].children),false,newImplementation);

							ulDNode.append(fileNode);
							listNode.append(ulDNode);
							break;
						case "file_asset":
							var fileLeaf = {
								'node_id': 'file-'+file_assets[f].id,
								'type': 'file',
								'basic_type': 'file',
//								'type': file_assets[f].model_name,
//								'basic_type': file_assets[f].type,
								'name': file_assets[f].file_name
							};
							var fileNode = R8.Utils.Y.Node.create(R8.Rtpl['project_tree_leaf']({'leaf_item': fileLeaf}));
//DEBUG
//console.log('rendering file, newImplementation is:'+newImplementation+ '   for file:'+file_assets[f].file_name);
							if(newImplementation==true) {
								fileNode.addClass('jstree-leaf');
								fileNode.get('children').item(0).prepend('<ins class="jstree-icon">&nbsp;</ins>');
								fileNode.prepend('<ins class="jstree-icon">&nbsp;</ins>');
							}
							listNode.append(fileNode);
							break;
					}
				}
				return listNode;
			},
			sortAssetTree: function(itemA, itemB) {
				if(itemA.model_name == 'directory_asset' && itemB.model_name == 'directory_asset') {
					return itemA.display_name > itemB.display_name ? 1 : -1;
				} else if(itemA.model_name == 'directory_asset' && itemB.model_name != 'directory_asset') {
					return -1;
				} else if(itemA.model_name != 'directory_asset' && itemB.model_name == 'directory_asset') {
					return 1;
				} else if(itemA.model_name == 'file_asset' && itemB.model_name == 'file_asset') {
					return itemA.file_name > itemB.file_name ? 1 : -1;
				}
			}
		}
	};
}