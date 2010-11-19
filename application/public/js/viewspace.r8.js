
if (!R8.ViewSpace) {

	R8.ViewSpace = function(viewSpaceDef) {
		var _def = viewSpaceDef,
			_id = _def['id'],
			_type = _def['type'],
			_items = {},
			_node = R8.Utils.Y.one('#viewspace'),

			_draggableItems = {},
			_selectedItems = {},

			_events = {};
		return {

			init: function() {
				this.setupEvents();
			},

			setupEvents: function() {
				_events['item_click'] = R8.Utils.Y.delegate('click',this.updateSelectedItems,_node,'.vspace-item, .connector',this);
//				R8.Workspace.events['item_click'] = R8.Utils.Y.delegate('click',function(){console.log('clicked item');},R8.Workspace.viewSpaceNode,'.item, .connector');
//				R8.Workspace.events['vspace_click'] = R8.Utils.Y.delegate('click',R8.Workspace.clearSelectedItems,'body','#viewspace');
//				R8.Workspace.events['vspace_mdown'] = R8.Utils.Y.delegate('mousedown',R8.Workspace.checkMouseDownEvent,'body','#viewspace');
			},

			addItems: function(items) {
				for(i in items) {
					var item = items[i], tpl_callback = item['tpl_callback'];

					switch(items[i]['type']) {
						case "node_group":
							this.addGroup(item);
						case "component":
							this.addComponent(item);
						default:
							break;
					}
				}
			},

			regNewItem : function(item) {
				var itemNodeId = item.get('node_id'),
					itemNode = item.get('node');

				itemNode.setAttribute('data-status','added');
				itemNode.addClass('vspace-item');
				this.addDrag(item);
//				this.addDrop(itemId);
			},


			/*
			 * addDrag will make a item drag/droppable on a viewspace
			 * @method addDrag
			 * @param {string} 	item An item object, stored locally in _items
			 */
			addDrag : function(item) {
				var viewSpace = this,
					draggableItems = _draggableItems,
					itemId = item.get('id');

				YUI().use('dd-drag','dd-plugin',function(Y){
					draggableItems[itemId] = new Y.DD.Drag({
						node: '#'+item.get('node_id')
					});
					draggableItems[itemId].on('drag:start',function(){
						viewSpace.clearSelectedItems();
						var node = this.get('node');
						var nodeId = node.get('id');
						node.addClass('focus');

						viewSpace.addSelectedItem(itemId);
					});
/*
					R8.Workspace.viewspaces[vsContext]['items'][itemId]['drag'].on('drag:drag',function(){
//TODO: update refreschConnectors with new viewspace object usage
//						R8.Component.refreshConnectors(this.get('node').get('id'));
					});
*/
				});
				item.get('node').setAttribute('data-status','dd-ready');
			},

			addSelectedItem: function(itemId,data) {
				_selectedItems[itemId] = data;
				_items[itemId].get('node').setStyle('zIndex',51);
				_items[itemId].get('node').addClass('focus');
			},

			clearSelectedItems: function() {
				for(itemId in _selectedItems) {
					_items[itemId].get('node').removeClass('focus');
					_items[itemId].get('node').setStyle('zIndex',1);
					delete(_selectedItems[itemId]);
				}
			},

			updateSelectedItems: function(e) {
				var itemNodeId = e.currentTarget.get('id'),
					model = e.currentTarget.getAttribute('data-model'),
					modelId = e.currentTarget.getAttribute('data-id');

				if(e.ctrlKey == false) this.clearSelectedItems();
				this.addSelectedItem(modelId,{'model':model,'id':modelId});

				e.stopImmediatePropagation();
			},

//---------------------------------------------------
//---------------------------------------------------
//------------ ITEM METHODS -------------------------
//---------------------------------------------------
//---------------------------------------------------

			addGroup: function(group) {
				var id = group['object']['id'];
				_items[id] = new R8.Group(group,this);
				_node.append(_items[id].render());
				_items[id].init();

				this.regNewItem(_items[id]);
			},

			refreshGroup: function(group) {
				
			},

			addComponent: function(group) {
				
			},

			refreshComponent: function(group) {
				
			},

			focus: function() {
				
			},

			blur: function() {
				
			},

			pushPendingDelete: function(id,def) {
				_pendingDelete[id] = def;
			}
		}
	};
}
