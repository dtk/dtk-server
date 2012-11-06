
if (!R8.IDE.View.component) { R8.IDE.View.component = {}; }

if (!R8.IDE.View.component.project) {

	R8.IDE.View.component.project = function(component) {
		var _component = component,
			_idPrefix = "component-leaf-",

			_leafNodeId = '',
			_leafNode = null,
			_leafBodyNodeId = '',
			_leafBodyNode = null,

			_childrenListNode = null,
			_childrenListNodeId = '',

			_interfaceLeafNode = null,
			_interfaceLeafNodeId = '',
			_interfaceListNode = null,
			_interfaceListNodeId = '',

			_linkDefsLeafNode = null,
			_linkDefsLeafNodeId = '',

			_attributesLeafNode = null,
			_attributesLeafNodeId = '',

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

//				_childrenListNode = R8.Utils.Y.one('#'+_childrenListNodeId);
//				_interfaceLeafNode = R8.Utils.Y.one('#'+_interfaceLeafNodeId);
//				_interfaceListNode = R8.Utils.Y.one('#'+_interfaceListNodeId);
//				_linkDefsLeafNode = R8.Utils.Y.one('#'+_linkDefsLeafNodeId);
//				_attributesLeafNode = R8.Utils.Y.one('#'+_attributesLeafNodeId);

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
console.log('double clicked a component:'+leafObjectId);
//					R8.IDE.openEditorView(_component);

					e.halt();
					e.stopImmediatePropagation();
				},this);
/*
				_events['linkdefs_dblclick'] = _linkDefsLeafNode.on('dblclick',function(e) {

					var leafNodeId = e.currentTarget.get('id'),
						leafType = e.currentTarget.getAttribute('type'),
						leafObjectId = leafNodeId.replace('leaf-body-'+leafType+'-leaf-',''),
						leafLabel = e.currentTarget.get('children').item(1).get('innerHTML');

//DEBUG
console.log('double clicked on component link defs:'+leafObjectId);
					R8.IDE.openEditorView(_component,'linkDefsEditor');

					e.halt();
					e.stopImmediatePropagation();
				},this);
*/
			},
			render: function(newApplication) {
				_leafNode = R8.Utils.Y.Node.create(R8.Rtpl['project_tree_leaf']({'leaf_item': _leafDef}));
				_leafNodeId = _leafNode.get('id');

				_leafBodyNode = _leafNode.get('children').item(0);
				_leafBodyNodeId = _leafBodyNode.get('id');

				if(newApplication==true) {
					_leafNode.addClass('jstree-leaf');
				}

/*
				_childrenListNode = R8.Utils.Y.Node.create('<ul id="'+_idPrefix+_component.get('id')+'-children"></ul>');
				_childrenListNodeId = _childrenListNode.get('id');

				var interfaceLeaf = {
					'node_id': _idPrefix+_component.get('id')+'-interface-leaf',
					'type': 'application',
					'basic_type': 'component',
					'name': 'Interface',
//					'class': 'jstree-closed'
				};
				_interfaceLeafNode = R8.Utils.Y.Node.create(R8.Rtpl['project_tree_leaf']({'leaf_item': interfaceLeaf}));
				_interfaceLeafNodeId = _interfaceLeafNode.get('id');
				_interfaceListNode = R8.Utils.Y.Node.create('<ul id="'+_idPrefix+_component.get('id')+'-interface-list"></ul>');
				_interfaceListNodeId = _interfaceListNode.get('id');

				var linkDefsLeaf = {
					'node_id': _idPrefix+_component.get('id')+'-interface-link-defs-leaf',
					'type': 'application',
					'basic_type': 'component',
					'name': 'LinkDefs',
//					'class': 'jstree-closed'
				};
				_linkDefsLeafNode = R8.Utils.Y.Node.create(R8.Rtpl['project_tree_leaf']({'leaf_item': linkDefsLeaf}));
				_linkDefsLeafNodeId = _linkDefsLeafNode.get('id');
				_interfaceListNode.append(_linkDefsLeafNode);

				var attributesLeaf = {
					'node_id': _idPrefix+_component.get('id')+'-interface-attributes-leaf',
					'type': 'application',
					'basic_type': 'component',
					'name': 'Attributes',
//					'class': 'jstree-closed'
				};
				_attributesLeafNode = R8.Utils.Y.Node.create(R8.Rtpl['project_tree_leaf']({'leaf_item': attributesLeaf}));
				_attributesLeafNodeId = _attributesLeafNode.get('id');
				_interfaceListNode.append(_attributesLeafNode);

				_interfaceLeafNode.append(_interfaceListNode);
				_childrenListNode.append(_interfaceLeafNode);
*/				_leafNode.append(_childrenListNode);

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