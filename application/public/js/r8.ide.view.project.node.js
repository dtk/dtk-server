
if (!R8.IDE.View.node) { R8.IDE.View.node = {}; }

if (!R8.IDE.View.project.node) {

	R8.IDE.View.project.node = function(viewDef) {
		var _panel = viewDef.panel,
			_obj = viewDef.obj,
			_idPrefix = "node-leaf-",

			_leafNodeId = '',
			_leafNode = null,
			_leafBodyNodeId = '',
			_leafBodyNode = null,

//			_nodesLeafNode = null,
//			_nodesListNode = null,

			_nodes = {},
			_nodeGroups = {},
			_views = {},

			_leafDef = {
				'node_id': _idPrefix+_obj.get('id'),
				'type': 'node-'+_obj.get('os_type'),
				'name': _obj.get('name'),
				'basic_type': 'node'
			},

			_events = {};

		return {
			init: function() {
//				_leafBodyNode = R8.Utils.Y.one('#'+_leafBodyNode.get('id'));

				_leafNode = R8.Utils.Y.one('#'+_leafNodeId);
				_leafBodyNode = R8.Utils.Y.one('#'+_leafBodyNodeId);

				this.initEvents();
				_initialized = true;

				return _initialized;
			},
			initEvents: function() {
				_events['leaf_dblclick'] = _leafBodyNode.on('click',function(e){

					var leafNodeId = e.currentTarget.get('id'),
						leafType = e.currentTarget.getAttribute('type'),
						leafObjectId = leafNodeId.replace('leaf-body-'+leafType+'-',''),
						leafLabel = e.currentTarget.get('children').item(1).get('innerHTML');

					R8.IDE.openEditorView(_obj);

					e.halt();
					e.stopImmediatePropagation();
				},this);
			},
			render: function() {
				_leafNode = R8.Utils.Y.Node.create(R8.Rtpl['project_tree_leaf']({'leaf_item': _leafDef}));
				_leafNodeId = _leafNode.get('id');

				_leafBodyNode = _leafNode.get('children').item(0);
				_leafBodyNodeId = _leafBodyNode.get('id');
/*
				var appsLeaf = {
					'node_id': 'target-nodes-'+_obj.get('id'),
					'type': 'nodes',
					'basic_type': 'nodes',
					'name': 'Nodes'
				};
				_appsLeafNode = R8.Utils.Y.Node.create(R8.Rtpl['project_tree_leaf']({'leaf_item': appsLeaf}));

				_appsListNode = R8.Utils.Y.Node.create('<ul></ul>');
				_apps = _obj.get('apps');

				for(var n in _apps) {
					this.addApp(_apps[n]);
				}

				_appsLeafNode.append(_appsListNode);
				_leafNode.append(_appsLeafNode);
*/
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
//NODE VIEW FUNCTIONS
//--------------------------------------
			addApp: function(app) {
				var appId = app.id;
				_apps[appId] = new R8.App(app);

				_appsListNode.append(_apps[appId].renderVIew('project'));
			}
		}
	};
}