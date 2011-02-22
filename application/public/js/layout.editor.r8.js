

if(!R8.LayoutEditor) {

	R8.LayoutEditor = function() {
		var _groupListNode = null
			_addGroupNode = null,
			_contentWrapperNode = null,
			_events = {},

			_availFields = {};
			_layoutDef = {
				'id': 'foo',
				'name': 'New Layout',
				'groups':{
					'group-1': {
						'nul_cols':1,
						'i18n': 'Group 1',
						'fields':[]
					}
				}
			},

			_draggingField = false,
			_tabSwitchTimeout = null;

		return {
			init: function(layoutDef,fieldDefs) {
				if(document.getElementById('layout-tab-list') == null || document.getElementById('add-tab') == null) {
					var that = this;
					var initCallback = function() {
						R8.LayoutEditor.init(layoutDef,fieldDefs);
					}
					setTimeout(initCallback,25);
					return;
				}

				_layoutDef = layoutDef;

				for(var i in fieldDefs) {
					if(!this.fieldInLayout(fieldDefs[i].name)) {
						_availFields[fieldDefs[i].name] = fieldDefs[i];
					}
				}

				_groupListNode = R8.Utils.Y.one('#layout-tab-list');
				_addGroupNode = R8.Utils.Y.one('#add-tab');
				_contentWrapperNode = R8.Utils.Y.one('#group-content-wrapper');
//				_events['addGroupClick'] = _addGroupNode.on('click',this.addGroup,this);
				_events['groupClick'] = R8.Utils.Y.delegate('click',this.groupClick,'#layout-tab-list','.tab',this);

//				_events['groupDblClick'] = R8.Utils.Y.delegate('dblclick',function(e){
//					console.log('hello there...');
//				},'#layout-tab-list','.tab',this);

				this.setupDD();
			},
			fieldInLayout: function(fieldName) {
				for(var gId in _layoutDef.groups) {
					var fieldList = _layoutDef.groups[gId].fields;
					for(var i in fieldList) {
						if(fieldList[i] == fieldName) return true;
					}
				}
				return false;
			},
			addGroup: function(e) {
				var groupIndex = _groupListNode.get('children').size();
				var groupId = 'group-'+groupIndex;
				var groupLabel = 'Group '+groupIndex;

				var newGroupNode = R8.Utils.Y.Node.create(this.getGroupMarkup(groupId,groupLabel));
				_groupListNode.insertBefore(newGroupNode,_addGroupNode);
				_contentWrapperNode.append(this.getContentMarkup(groupId));

				_layoutDef['groups'][groupId] = {
					'nul_cols':1,
					'i18n': groupLabel,
					'fields':[]
				};
				this.groupFocus(groupId);
			},
			groupFocus: function(groupId) {
				for(var gId in _layoutDef.groups) {
					R8.Utils.Y.one('#'+gId+'-tab').removeClass('selected');
					R8.Utils.Y.one('#'+gId+'-content').setStyle('display','none');
				}
				R8.Utils.Y.one('#'+groupId+'-tab').addClass('selected');
				R8.Utils.Y.one('#'+groupId+'-content').setStyle('display','block');
			},
			groupClick: function(e) {
				if(e.currentTarget.get('id') == 'add-tab') {
					this.addGroup(e);
				} else {
					var id = e.currentTarget.get('id'),
						groupId = id.replace('-tab','');
					this.groupFocus(groupId);
				}
			},
			getGroupMarkup: function(id,i18n) {
				var groupTpl = '<li id="'+id+'-tab" class="tab selected">'+i18n+'</li>';

				return groupTpl;
			},
			getContentMarkup: function(id) {
				var groupIndex = _groupListNode.get('children').size();
				var id = (typeof(id) == 'undefined') ? 'group-'+groupIndex : id;
				var contentTpl = '<div id="'+id+'-content" class="tab-content">\
									<ul id="'+id+'-field-list" style="margin: 5px; width: 200px; height: 200px; float: left; border: 1px solid black;">\
									</ul>\
								  </div>';

				return contentTpl;
			},

			setupDD: function() {
				var that=this;

				YUI().use('dd-constrain', 'dd-proxy', 'dd-drop', function(Y) {
					var goingUp = false, lastY = 0;

					Y.DD.DDM.on('drop:over', function(e) {
						//Get a reference to our drag and drop nodes
						var drag = e.drag.get('node'),
							drop = e.drop.get('node');

						//Are we dropping on a li node?
//						if (drop.get('tagName').toLowerCase() === 'li' && drop.get('parentNode').get('id') != 'available-fields') {
						if (drop.get('tagName').toLowerCase() === 'li' && drop.get('parentNode').get('id') != 'layout-tab-list') {
							//Are we not going up?
							if (!goingUp) {
								drop = drop.get('nextSibling');
							}
							//Add the node to this list
							e.drop.get('node').get('parentNode').insertBefore(drag, drop);
							//Resize this nodes shim, so we can drop on it later.
							e.drop.sizeShim();
						}
					});

					Y.DD.DDM.on('drag:mouseDown',function(e){
						for(var gId in _layoutDef.groups) {
							var gFieldNode = Y.one('#'+gId+'-field-list');
							if(!gFieldNode.hasClass('yui3-dd-drop')) {
								var dObj = new Y.DD.Drop({
									node: gFieldNode,
									groups:['field-drop']
								});
							}
						}

						var groupTabList = Y.Node.all('#layout-tab-list .tab');
						groupTabList.each(function(gt,i){
//TODO: remove after refactoring plus btn out of <ul>
							if(gt.get('id') == 'add-tab' || gt.hasClass('yui3-dd-drop')) return;
							var dObj = new Y.DD.Drop({
								node: gt,
								groups:['group-switch']
							});
							dObj.on('drop:enter',function(e){
								var id = e.currentTarget.get('node').get('id'),
									groupId = id.replace('-tab','');
								var tabOvrCallback = function() {
										R8.LayoutEditor.groupFocus(groupId);
									}
								_tabSwitchTimeout = setTimeout(tabOvrCallback,1700);
							});
							dObj.on('drop:exit',function(e){
								if (_tabSwitchTimeout != null) {
									clearTimeout(_tabSwitchTimeout);
									_tabSwitchTimeout = null;
								}
							});
						});
					});

					Y.DD.DDM.on('drag:drag', function(e) {
						var y = e.target.lastXY[1];

						//is it greater than the lastY
						if (y < lastY) { goingUp = true; }
						else { goingUp = false; }

						lastY = y;
					});

					Y.DD.DDM.on('drag:start', function(e) {
						_draggingField = true;
						//Get our drag object
						var drag = e.target;
						//Set some styles here
						drag.get('node').setStyle('opacity', '.25');
						drag.get('dragNode').set('innerHTML', drag.get('node').get('innerHTML'));
						drag.get('dragNode').setStyles({
							opacity: '.7',
							borderColor: drag.get('node').getStyle('borderColor'),
							backgroundColor: drag.get('node').getStyle('backgroundColor')
						});
					});

					Y.DD.DDM.on('drag:end', function(e) {
						_draggingField = false;
						var drag = e.target;
						//Put our styles back
						drag.get('node').setStyles({
							visibility: '',
							opacity: '1'
						});
					});

					Y.DD.DDM.on('drag:drophit', function(e) {
						var drop = e.drop.get('node'),
							drag = e.drag.get('node');

						if(e.drop.inGroup(['group-switch'])) return false;

						//if we are not on an li, we must have been dropped on a ul
						if (drop.get('tagName').toLowerCase() !== 'li') {
							if (!drop.contains(drag)) {
								drop.appendChild(drag);
							}
						}
					});

					var lis = Y.Node.all('#available-fields li');
					lis.each(function(v, k) {
						var dd = new Y.DD.Drag({
							node: v,
							groups:['field-drop','group-switch'],
							target: {
								padding: '0 0 0 20'
							}
						}).plug(Y.Plugin.DDProxy, {
							moveOnEnd: false
						}).plug(Y.Plugin.DDConstrained, {
							constrain2node: '#editor-wrapper'
						});
					});

					var uls = Y.Node.all('#available-fields');
					uls.each(function(v, k) {
						var tar = new Y.DD.Drop({
							node: v,
							groups:['field-drop']
						});
					});
				});
			}
		}
	}();
}
