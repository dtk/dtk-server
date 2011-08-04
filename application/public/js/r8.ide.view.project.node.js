
if (!R8.IDE.View.node) { R8.IDE.View.node = {}; }

if (!R8.IDE.View.project.node) {

	R8.IDE.View.project.node = function(node) {
		var _node = node,
			_idPrefix = "node-leaf-",

			_leafNodeId = '',
			_leafNode = null,
			_leafBodyNodeId = '',
			_leafBodyNode = null,

			_applicationsLeafNode = null,
			_applicationsListNode = null,

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
//DEBUG
console.log('INSIDE OF INIT IN PROJECT.NODE view....');
console.log('node-applications-list-'+_node.get('id'));
				_applicationsLeafNode = R8.Utils.Y.one('#node-applications-'+_node.get('id'));
				_applicationsListNode = R8.Utils.Y.one('#node-applications-list-'+_node.get('id'));
console.log(_applicationsListNode);
//console.log(_applicationsListNode.set('innerHTML','%%%%%%%%%%%%%%%%%%%%%%%'));

				this.setupEvents();
				_initialized = true;

				var applications = _node.get('applications');
				for(var a in applications) {
					applications[a].getView('project').init();
				}

			},
			setupEvents: function() {
/*
				_events['leaf_dblclick'] = _leafBodyNode.on('dblclick',function(e){

					var leafNodeId = e.currentTarget.get('id'),
						leafType = e.currentTarget.getAttribute('type'),
						leafObjectId = leafNodeId.replace('leaf-body-'+leafType+'-',''),
						leafLabel = e.currentTarget.get('children').item(1).get('innerHTML');

					R8.IDE.openEditorView(_node);

					e.halt();
					e.stopImmediatePropagation();
				},this);
*/
			},
			render: function() {
				_leafNode = R8.Utils.Y.Node.create(R8.Rtpl['project_tree_leaf']({'leaf_item': _leafDef}));
				_leafNodeId = _leafNode.get('id');

				_leafBodyNode = _leafNode.get('children').item(0);
				_leafBodyNodeId = _leafBodyNode.get('id');

				var applicationsLeaf = {
					'node_id': 'node-applications-'+_node.get('id'),
					'type': 'applications',
					'basic_type': 'components',
					'name': 'Applications'
				};
				_applicationsLeafNode = R8.Utils.Y.Node.create('<ul>'+R8.Rtpl['project_tree_leaf']({'leaf_item': applicationsLeaf})+'</ul>');

				_applicationsListNode = R8.Utils.Y.Node.create('<ul id="node-applications-list-'+_node.get('id')+'"></ul>');

				var applications = _node.get('applications');
				for(var a in applications) {
					this.addApplication(applications[a]);
				}

				if(_applicationsListNode == null) {
					_applicationsListNode = R8.Utils.Y.Node.create('<ul id="node-applications-list-'+_node.get('id')+'"></ul>');
				}

//DEBUG
console.log('appending applications list node for node:'+_applicationsListNode.get('id'));
				_applicationsLeafNode.get('children').item(0).append(_applicationsListNode);
				_leafNode.append(_applicationsLeafNode);

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
			addApplication: function(application,tester) {
				var applicationLeaf = application.renderView('project');

				//TODO: revisit, temp hack to work over the top of jstree library
				if(_node.isInitialized()) {
//console.log('node IS initialized.., going to do mish mosh for jstree...');
					applicationLeaf.get('children').item(0).prepend('<ins class="jstree-icon">&nbsp;</ins>');
					applicationLeaf.prepend('<ins class="jstree-icon">&nbsp;</ins>');
				}

				if(_applicationsListNode == null) {
//LEFT OFF HERE
console.log('app list node is null, and project node view IS init');
					_applicationsLeafNode.append(R8.Utils.Y.Node.create('<ul id="node-applications-list-'+_node.get('id')+'"></ul>'));
					_applicationsLeafNode.get('children').item(0).prepend('<ins class="jstree-icon">&nbsp;</ins>');
//					_applicationsLeafNode.prepend('<ins class="jstree-icon">&nbsp;</ins>');

					_applicationsListNode = R8.Utils.Y.one('#node-applications-list-'+_node.get('id'));
				}

/*
//DEBUG
if (tester == true) {
	console.log('Adding application....');
	console.log(applicationLeaf);
	console.log(_applicationsListNode);
//	_applicationsListNode.set('innerHTML','&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&');
}
*/
//LEFT OFF HERE
				_applicationsListNode.append(applicationLeaf);
			},
//TODO: revisit to see best way to render types of components likes apps, languages, etc
			addComponent: function(component,tester) {
console.log('inside of addComponent in node, tester is:'+tester);
				this.addApplication(component,tester);
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