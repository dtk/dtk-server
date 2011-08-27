
if (!R8.IDE.View.node) { R8.IDE.View.node = {}; }

if (!R8.IDE.View.project.node) {

	R8.IDE.View.project.node = function(node) {
		var _node = node,
			_idPrefix = "node-leaf-",

			_leafNodeId = '',
			_leafNode = null,
			_leafBodyNodeId = '',
			_leafBodyNode = null,
			_childrenListNode = null,
			_childrenListNodeId = '',

			_applicationsLeafNode = null,
			_applicationsLeafNodeId = '',
			_applicationsListNode = null,
			_applicationsListNodeId = '',

			_leafDef = {
				'node_id': _idPrefix+_node.get('id'),
				'type': 'node-'+_node.get('os_type'),
				'name': _node.get('name'),
				'basic_type': 'node'
			},

			_initialized = false,
			_events = {};

		return {
			init: function() {
//				_leafBodyNode = R8.Utils.Y.one('#'+_leafBodyNode.get('id'));

				_leafNode = R8.Utils.Y.one('#'+_leafNodeId);
				_leafBodyNode = R8.Utils.Y.one('#'+_leafBodyNodeId);
				_childrenListNode = R8.Utils.Y.one('#'+_childrenListNodeId);

				_applicationsLeafNode = R8.Utils.Y.one('#'+_applicationsLeafNodeId);
				_applicationsListNode = R8.Utils.Y.one('#'+_applicationsListNodeId);
//DEBUG
/*
				if(_applicationsListNode == null) {
					_applicationsListNode = R8.Utils.Y.Node.create('<ul id="node-'+_node.get('id')+'-applications-list"></ul>');
					_applicationsListNodeId = _applicationsListNode.get('id');
					_applicationsLeafNode.append(_applicationsListNode);
					_applicationsListNode = R8.Utils.Y.one('#'+_applicationsListNodeId);
				}
*/
				this.setupEvents();
				_initialized = true;

				var applications = _node.get('applications');
				for(var a in applications) {
					applications[a].getView('project').init();
				}
			},
			setupEvents: function() {
				_events['leaf_dblclick'] = _leafBodyNode.on('dblclick',function(e){

					var leafNodeId = e.currentTarget.get('id'),
						leafType = e.currentTarget.getAttribute('type'),
						leafObjectId = leafNodeId.replace('leaf-body-'+leafType+'-',''),
						leafLabel = e.currentTarget.get('children').item(1).get('innerHTML');

//DEBUG
console.log('double clicked on node leaf:'+_node.get('id'));
//					R8.IDE.openEditorView(_node);

					e.halt();
					e.stopImmediatePropagation();
				},this);
			},
			render: function(newNode) {
				_leafNode = R8.Utils.Y.Node.create(R8.Rtpl['project_tree_leaf']({'leaf_item': _leafDef}));
				_leafNodeId = _leafNode.get('id');

				_leafBodyNode = _leafNode.get('children').item(0);
				_leafBodyNodeId = _leafBodyNode.get('id');
				_childrenListNode = R8.Utils.Y.Node.create('<ul id="node-'+_node.get('id')+'-children"></ul>');
				_childrenListNodeId = _childrenListNode.get('id');

				var applicationsLeaf = {
					'node_id': 'node-applications-'+_node.get('id'),
					'type': 'applications',
					'basic_type': 'components',
					'name': 'Applications',
//					'class': 'jstree-closed'
				};
				_applicationsLeafNode = R8.Utils.Y.Node.create(R8.Rtpl['project_tree_leaf']({'leaf_item': applicationsLeaf}));
				_applciationsLeafNodeId = _applicationsLeafNode.get('id');

				if(newNode==true) {
					_applicationsLeafNode.addClass('jstree-closed');
					_applicationsLeafNode.get('children').item(0).prepend('<ins class="jstree-icon">&nbsp;</ins>');
					_applicationsLeafNode.prepend('<ins class="jstree-icon">&nbsp;</ins>');
				}
				_applicationsListNode = R8.Utils.Y.Node.create('<ul id="node-'+_node.get('id')+'-applications-list"></ul>');
				_applicationsListNodeId = _applicationsListNode.get('id');

				var applications = _node.get('applications');
				for(var a in applications) {
					this.addApplication(applications[a]);
				}

				_applicationsLeafNode.append(_applicationsListNode);
				_childrenListNode.append(_applicationsLeafNode);
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
				}
			},
			focus: function() {
				this.resize();
			},
			blur: function() {
			},
			close: function() {
			},
			isInitialized: function() {
				return _initialized;
			},
//--------------------------------------
//NODE VIEW FUNCTIONS
//--------------------------------------
			refresh: function() {
				_leafNode.set('id',_idPrefix+_node.get('id'));
				_leafBodyNode.set('id','leaf-body-node-leaf-'+_idPrefix+_node.get('id'));

				_leafBodyNode.get('children').item(1).set('innerHTML',_node.get('name'));
			},
			updateName: function() {
				_leafBodyNode.get('children').item(1).set('innerHTML',_node.get('name'));
			},
			addApplication: function(application,newApplication) {
				var applicationLeafNode = application.getView('project').render();

				if(newApplication == true) {
					applicationLeafNode.get('children').item(0).prepend('<ins class="jstree-icon">&nbsp;</ins>');
					applicationLeafNode.prepend('<ins class="jstree-icon">&nbsp;</ins>');
				}

				_applicationsListNode.append(applicationLeafNode);

				if(newApplication == true) {
					application.getView('project').init();
				}
			},
//TODO: revisit to see best way to render types of components likes apps, languages, etc
			addComponent: function(component,newComponent) {
				this.addApplication(component,newComponent);
			}
/*
			addApp: function(app) {
				var appId = app.id;
				_apps[appId] = new R8.App(app);

				_appsListNode.append(_apps[appId].renderVIew('project'));
			}
*/
		}
	};
}