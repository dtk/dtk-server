
if (!R8.IDE.View.component) { R8.IDE.View.component = {}; }

if (!R8.IDE.View.project.component) {

	R8.IDE.View.project.component = function(component) {
		var _component = component,
			_idPrefix = "component-leaf-",

			_leafNodeId = '',
			_leafNode = null,
			_leafBodyNodeId = '',
			_leafBodyNode = null,

			_leafDef = {
				'node_id': _idPrefix+_component.get('id'),
				'type': 'application',
				'name': _component.get('name'),
				'basic_type': 'component'
			},

			_initialized = false,
			_events = {};

		return {
			init: function() {
				_leafNode = R8.Utils.Y.one('#'+_leafNodeId);
				_leafBodyNode = R8.Utils.Y.one('#'+_leafBodyNodeId);

//				_applicationsListNode = R8.Utils.Y.one('#node-applications-list-'+_node.get('id'));

				this.setupEvents();
				_initialized = true;
			},
			setupEvents: function() {
				_events['leaf_dblclick'] = _leafBodyNode.on('dblclick',function(e) {

					var leafNodeId = e.currentTarget.get('id'),
						leafType = e.currentTarget.getAttribute('type'),
						leafObjectId = leafNodeId.replace('leaf-body-'+leafType+'-leaf-',''),
						leafLabel = e.currentTarget.get('children').item(1).get('innerHTML');

//DEBUG
console.log('double clicked a compoennt:'+leafObjectId);
//					R8.IDE.openEditorView(_component);

					e.halt();
					e.stopImmediatePropagation();
				},this);
			},
			render: function() {
				_leafNode = R8.Utils.Y.Node.create(R8.Rtpl['project_tree_leaf']({'leaf_item': _leafDef}));
				_leafNodeId = _leafNode.get('id');

				_leafBodyNode = _leafNode.get('children').item(0);
				_leafBodyNodeId = _leafBodyNode.get('id');

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
			}
//--------------------------------------
//COMPONENT VIEW FUNCTIONS
//--------------------------------------
		}
	};
}