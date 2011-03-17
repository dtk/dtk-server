

if(!R8.LayoutEditor) {

	R8.LayoutEditor = function() {
		var _groupListNode = null
			_addGroupNode = null,
			_contentWrapperNode = null,
			_layoutHeaderNode = null,
			_editorTplWrapperNode = null,
			_events = {},
			_parentId = null,

			_availFields = {},
			_layout = null,
			
			_gtPopupNode = null,
			_gtPopupIndex = null,
			_gtPopupShowTimeout = null,
			_gtPopupHideTimeout = null;
/*
			_layout.def = {
				'id': 'foo',
				'name': 'New Layout',
				'i18n': 'Create User',
				'groups':{
					'group-1': {
						'num_cols':1,
						'i18n': 'Group 1',
						'fields':[]
					}
				}
			},
*/
			_layoutType = 'dock_display',

			_draggingField = false,
			_tabSwitchTimeout = null;

		return {
			init: function(layout,fieldDefs) {
				if(document.getElementById('editor-tpl-wrapper') == null) {
					var that = this;
					var initCallback = function() {
					    R8.LayoutEditor.init(layout,fieldDefs);
					}
					setTimeout(initCallback,25);
					return;
				}
				_layout = layout;
				_parentId = _layout.component_component_id;
				_fieldDefs = fieldDefs;

				for(var g in _layout.def.groups) {
					_layout.def.groups[g].index = g;
					_layout.def.groups[g].id = 'l-'+_layout.id+'-g-'+g;

					if(g==0) {
						_layout.def.groups[g].selected = 'selected';
						_layout.def.groups[g].content_display = 'block';
					} else {
						_layout.def.groups[g].selected = '';
						_layout.def.groups[g].content_display = 'none';
					}
				}

				if(typeof(_layout.def.i18n) == 'undefined') _layout.def.i18n = '(no title)';
				this.setI18n(fieldDefs);
				_editorTplWrapperNode = R8.Utils.Y.one('#editor-tpl-wrapper');
				_editorTplWrapperNode.append(R8.Rtpl[_layoutType+'_layout']({
					'layout': _layout
				}));

				_groupListNode = R8.Utils.Y.one('#'+_layoutType+'-tab-list');
				_addGroupNode = R8.Utils.Y.one('#add-group-btn');
				_contentWrapperNode = R8.Utils.Y.one('#'+_layoutType+'-content-wrapper');
				_layoutHeaderNode = R8.Utils.Y.one('#'+_layoutType+'-header');

//TODO: this is temp until fully refactoring the view/rtpl stuff

//				this.renderLayout();
				for(var i in fieldDefs) {
					if(!this.fieldInLayout(fieldDefs[i].name)) {
						this.addAvailField(fieldDefs[i]);
					}
				}

				_layoutHeaderNode.on('mouseenter',function(e){
					e.currentTarget.setStyles({'border':'1px dashed #0000CC'});
				});
				_layoutHeaderNode.on('mouseleave',function(e){
					e.currentTarget.setStyles({'border':'1px solid #EDEDED'});
				});
				_layoutHeaderNode.on('click',function(e){
					R8.Utils.Y.one('#title-txt').setStyles({'display':'none'});
					R8.Utils.Y.one('#'+_layoutType+'-header').setStyles({'border':'1px solid #EDEDED'});
					R8.Utils.Y.one('#title-input-wrapper').setStyle('display','block');
					R8.Utils.Y.one('#title-input').focus();
				});
				R8.Utils.Y.one('#title-input').on('change',function(e){
					R8.Utils.Y.one('#title-txt').set('innerHTML',this.get('value'));
					_layout.def.i18n = this.get('value');
				});
				R8.Utils.Y.one('#title-input').on('blur',function(e){
					var inputVal = R8.Utils.Y.one('#title-input').get('value');
					R8.Utils.Y.one('#title-input-wrapper').setStyle('display','none');
					R8.Utils.Y.one('#title-txt').setStyles({'display':'block'});
					_layout.def.i18n = inputVal;
				});

				_events['addGroupClick'] = _addGroupNode.on('click',this.addGroup,this);
				_events['groupClick'] = R8.Utils.Y.delegate('click',this.groupClick,'#'+_layoutType+'-tab-list','.tab',this);

//-----Group Popup----------
				_events['groupMenter'] = R8.Utils.Y.delegate('mouseenter',this.groupMenter,'#'+_layoutType+'-tab-list','.tab',this);
				_events['groupMleave'] = R8.Utils.Y.delegate('mouseleave',this.groupMleave,'#'+_layoutType+'-tab-list','.tab',this);
//--------------------------

//				_events['groupDblClick'] = R8.Utils.Y.delegate('dblclick',function(e){
//					console.log('hello there...');
//				},'#layout-tab-list','.tab',this);

				this.setupDD();
			},
//-------------Group Popup--------------------------
			groupMenter: function(e) {
				if(_draggingField == true) return;

				var that = this,
					gNodeId = e.currentTarget.get('id'),
					groupId = gNodeId.replace('-tab','');

				if(_gtPopupNode != null) {
					_gtPopupHideTimeout = null;
					if (_gtPopupNode.getAttribute('data-gId') == groupId) {
						return;
					} else {
						this.resetPopup();
					}
				}

				var	groupDef = this.getGroupDefById(groupId),
					showPopup = function() {
						that.showGtPopup(groupDef);
					};
				_gtPopupShowTimeout = setTimeout(showPopup,200);
			},
			groupMleave: function(e) {
				if(_draggingField == true) return;

				var that = this,
					clearGtPopup = function() {
						that.clearGtPopup();
					}
				_gtPopupHideTimeout = setTimeout(clearGtPopup,200);
			},
			resetPopup: function() {
				if(_gtPopupNode == null) return;
				_gtPopupNode.purge(true);
				_gtPopupNode.remove();
				_gtPopupNode = null;
				_gtPopupIndex = null;

//TODO: revisit, including for now to accomodate when popup gets in weird state and dupes are rendered
				var testNode = R8.Utils.Y.one('#gt-popup');
				while(testNode != null) {
					testNode.purge(true);
					testNode.remove();
					testNode = R8.Utils.Y.one('#gt-popup');
				}
			},
			showGtPopup: function(groupDef) {
				_gtPopupShowTimeout = null;

				var gtNode = R8.Utils.Y.one('#'+groupDef.id+'-tab'),
					gtRegion = gtNode.get('region');

				_gtPopupNode = this.getPopupNode(groupDef);

				var gtCenter = gtRegion.left + Math.floor(gtRegion.width/2),
					pTop = gtNode.getY() - 45,
					pLeft = gtCenter - 75;
//					pLeft = gtCenter - Math.floor(popupNode.get('region').width/2);

				_gtPopupNode.setStyles({'top':pTop+'px','left':pLeft+'px'});
				R8.Utils.Y.one('#page-container').append(_gtPopupNode);
				_gtPopupIndex = groupDef.index;
			},
			clearGtPopup: function() {
				if(_gtPopupHideTimeout == null) return;

				var that = this;
				var clearPopup = function() {
					that.resetPopup();
				}
				_gtPopupHideTimeout = setTimeout(clearPopup,400);
			},
			getPopupNode: function(groupDef) {
				var popupNode = R8.Utils.Y.Node.create(R8.Rtpl[_layoutType+'_group_popup']({'group_def': groupDef})),
					that=this;

				popupNode.on('mouseenter',function(e){clearTimeout(_gtPopupHideTimeout);});
				popupNode.on('mouseleave',function(e){
					var clearPopup = function() {
						that.clearGtPopup();
					}
					_gtPopupHideTimeout = setTimeout(clearPopup,400);
				});

				return popupNode;
			},
			gtToggleNameUpdate: function(groupId) {
				var inputNode = R8.Utils.Y.one('#gt-name-input');
				if(typeof(_events['gtNameChange']) != 'undefined') _events['gtNameChange'].detach();

				if(R8.Utils.Y.one('#gt-rename-wrapper').getStyle('display') == 'block') {
					R8.Utils.Y.one('#gt-rename-wrapper').setStyle('display','none');					
					R8.Utils.Y.one('#gt-edit-actions').setStyle('display','block');
				} else {
					R8.Utils.Y.one('#gt-edit-actions').setStyle('display','none');
					R8.Utils.Y.one('#gt-rename-wrapper').setStyle('display','block');

					var that=this;
					_events['gtNameChange'] = R8.Utils.Y.one('body').on('keyup',function(e){
						that.gtUpdateName(R8.Utils.Y.one('#gt-name-input').get('value'));
					});
					inputNode.focus();
				}
			},

			gtUpdateName: function(newName) {
//DEBUG
//console.log('PopupIndex:'+_gtPopupIndex);
				_layout.def.groups[_gtPopupIndex].i18n = newName;
				_layout.def.groups[_gtPopupIndex].name = newName.replace(' ','_');

				R8.Utils.Y.one('#'+_layout.def.groups[_gtPopupIndex].id+'-tab').set('innerHTML',newName);
			},

			deleteGroup: function(groupId) {
				var groupDef = this.getGroupDefById(groupId),
					that = this;

				R8.Utils.Y.all('#'+groupDef.id+'-field-list li').each(function(){
					R8.Utils.Y.one('#available-fields').append(this);
					_availFields[this.get('id')] = that.getFieldDefByName(this.get('id'));
				});

				var gIndex = this.getGroupIndexById(groupDef.id),
					gTabNode = R8.Utils.Y.one('#'+groupDef.id+'-tab'),
					gWasSelected = false;

				if(gTabNode.hasClass('selected')) gWasSelected = true;

				gTabNode.purge(true).remove();
				R8.Utils.Y.one('#'+groupDef.id+'-content').purge(true).remove();
				R8.Utils.arrayRemove(_layout.def.groups,gIndex);

				this.resetPopup();
				if (gWasSelected && _layout.def.groups.length > 0) {
					this.groupFocus(_layout.def.groups[0].id);
				}
			},
//-------------------------------------------------------
			loadViewInstance: function(layoutId) {
				var params = {
						cfg: {
							data: 'layout_id='+layoutId
						}
					};

				R8.Ctrl.call('component/layout_test/'+_parentId,params);
			},
			getFieldDefByName: function(fieldName) {
				for(var f in _fieldDefs) {
					if(_fieldDefs[f].name == fieldName) return _fieldDefs[f];
				}
			},
			getGroupDefById: function(groupId) {
				for(var g in _layout.def.groups) {
					if(_layout.def.groups[g].id == groupId) return _layout.def.groups[g];
				}
				return false;
			},
			getCurrentDef: function() {
				var that = this;
					newGroupList = [];

				R8.Utils.Y.all('#'+_layoutType+'-tab-list li').each(function(){
					var tabNodeId = this.get('id'),
						groupId = tabNodeId.replace('-tab','');

					newGroupList.push(that.getGroupDefById(groupId));
				});
				_layout.def.groups = newGroupList;

				var currentDef = _layout.def;
				for(var g in _layout.def.groups) {
					currentDef.groups[g].fields = [];
					R8.Utils.Y.all('#'+_layout.def.groups[g].id+'-field-list li').each(function(){
						currentDef.groups[g].fields.push(that.getFieldDefByName(this.get('id')));
					});
				}
				return currentDef;
			},
			save: function() {
				var layoutDef = this.getCurrentDef();
				var layoutDefJson = R8.Utils.Y.JSON.stringify(_layout.def),
					params = {
						'cfg': {
							form: {
								id : _layoutType+'-form',
								upload : false
							}
						}
					}

				document.getElementById(_layoutType+'-form')['id'].value='';
				document.getElementById(_layoutType+'-form')['def'].value=layoutDefJson;
				R8.Ctrl.call('component/save_layout/'+_parentId,params);
			},
			deploy: function() {
				var layoutDefJson = R8.Utils.Y.JSON.stringify(_layout.def),
					params = {
						'cfg': {
							form: {
								id : _layoutType+'-edit-form',
								upload : false
							}
						}
					}
				document.getElementById(_layoutType+'-form')['def'].value=layoutDefJson;
				document.getElementById(_layoutType+'-form')['active'].value='true';
				R8.Ctrl.call('component/publish_layout/'+_parentId,params);
			},
//-----------------------------------------
//TODO: remove after cleanup
			setI18n: function(fieldDefs) {
				for(var g in _layout.def.groups) {
					for(var f in _layout.def.groups[g].fields) {
						_layout.def.groups[g].fields[f].i18n = this.getFieldI18n(_layout.def.groups[g].fields[f].name,fieldDefs);
					}
				}
			},
			getFieldI18n: function(fName,fieldDefs) {
				for(var f in fieldDefs) {
					if(fieldDefs[f].name === fName) {
						return fieldDefs[f].i18n;
					}
				}
				return fName;
			},
//-----------------------------------------
			getGroupDefById: function(groupId) {
				for(var g in _layout.def.groups) {
					if(_layout.def.groups[g].id == groupId) return _layout.def.groups[g];
				}
				return false;
			},
			getGroupIndexById: function(groupId) {
				for(var g in _layout.def.groups) {
					if(_layout.def.groups[g].id == groupId) return g;
				}
				return false;
			},
			reset: function() {
				_groupListNode = null;
				_addGroupNode = null;
				_contentWrapperNode = null;
				_events = {};
			},
			updateHeader: function() {
				var inputVal = R8.Utils.Y.one('#title-input').get('value');
				R8.Utils.Y.one('#title-txt').set('innerHTML',inputVal);
				R8.Utils.Y.one('#title-input-wrapper').setStyle('display','none');
				R8.Utils.Y.one('#title-txt').setStyles({'display':'block'});

				_layout.def.i18n = inputVal;
			},
			fieldInLayout: function(fieldName) {
				for(var g in _layout.def.groups) {
					var fieldList = _layout.def.groups[g].fields;
					for(var f in fieldList) {
						if(fieldList[f].name == fieldName) return true;
					}
				}
				return false;
			},
			addAvailField: function(fieldDef) {
				var availFieldsContainer = R8.Utils.Y.one('#available-fields');
				var fieldContent = this.getFieldMarkup(fieldDef);

				availFieldsContainer.append(fieldContent);
				_availFields[fieldDef.name] = fieldDef;
			},
			renderLayout: function() {
				for(var g in _layout.def.groups) {
					if(g==0) {
						_layout.def.groups[g].focus=true;
					}
					this.renderGroup(_layout.def.groups[g]);
				}
			},
			renderGroup: function(groupDef) {
				var groupId = groupDef.name,
					groupLabel = groupDef.i18n,
					selected = '',
					contentDisplay = 'none';

				if (groupDef.focus == true) {
					selected = 'selected';
					contentDisplay = 'block';
				}

				var newGroupNode = R8.Utils.Y.Node.create(this.getGroupMarkup(groupId,groupLabel,selected));
				var contentNode = R8.Utils.Y.Node.create(this.getContentMarkup(groupId,contentDisplay));

				_groupListNode.append(newGroupNode);
				_contentWrapperNode.append(contentNode);

				var groupFListContainer = R8.Utils.Y.one('#'+groupId+'-field-list');
				for(var f in groupDef.fields) {
					var fieldContent = this.getFieldMarkup(groupDef.fields[f]);
					groupFListContainer.append(fieldContent);
				}
/*
				_layout.def.groups.push({
					'name':groupId,
					'num_cols':1,
					'i18n': groupLabel,
					'fields':[]
				});
*/
//				this.groupFocus(_layout.def.groups.length-1);
			},
			addGroup: function(e) {
				var groupNum = (_groupListNode.get('children').size()+1),
					newIndex = _layout.def.groups.length,
					groupId = 'l-'+_layout.id+'-g-'+_layout.def.groups.length;
					groupLabel = 'Group '+groupNum,
					groupName = 'group_'+newIndex;

				var newGroupNode = R8.Utils.Y.Node.create(this.getGroupMarkup(groupId,groupLabel,'selected'));
				_groupListNode.append(newGroupNode);
				_contentWrapperNode.append(this.getContentMarkup(groupId,'block'));

				_layout.def.groups.push({
					'id': groupId,
					'index': newIndex,
					'name': groupName,
					'num_cols': 1,
					'i18n': groupLabel,
					'fields': []
				});

				this.groupFocus(groupId);
			},
			groupFocus: function(groupId) {
				for(var g in _layout.def.groups) {
					var gId = _layout.def.groups[g].id;
					R8.Utils.Y.one('#'+gId+'-tab').removeClass('selected');
					R8.Utils.Y.one('#'+gId+'-content').setStyle('display','none');
				}
				R8.Utils.Y.one('#'+groupId+'-tab').addClass('selected');
				R8.Utils.Y.one('#'+groupId+'-content').setStyle('display','block');
			},
			groupClick: function(e) {
				var id = e.currentTarget.get('id'),
					groupId = id.replace('-tab','');
				this.groupFocus(groupId);
			},
			getGIndexByName: function(groupName) {
				for(var g in _layout.def.groups) {
					if(groupName === _layout.def.groups[g].name) return g;
				}
				return false;
			},
			getGroupMarkup: function(id,i18n,selected) {
				var groupTpl = '<li id="'+id+'-tab" class="tab '+selected+'">'+i18n+'</li>';

				return groupTpl;
			},
			getContentMarkup: function(id,display) {
				var groupIndex = _groupListNode.get('children').size();
				var id = (typeof(id) == 'undefined') ? 'group-'+groupIndex : id;
				var contentTpl = '<div id="'+id+'-content" class="tab-content" style="display: '+display+';">\
									<ul id="'+id+'-field-list" class="field-list">\
									</ul>\
								  </div>';
//									<ul id="'+id+'-field-list" style="margin: 5px; width: 200px; height: 200px; float: left; border: 1px solid black;">\

				return contentTpl;
			},

			getFieldMarkup: function(fieldDef) {
				if(typeof(fieldDef.i18n) === 'undefined') fieldDef.i18n = fieldDef.name;

				var fieldTpl = '<li style="height: 20px; width: 140px; margin: 3px; padding: 3px; border: 1px solid rgb(153, 153, 153); opacity: 1;" id="'+fieldDef.name+'" class="yui3-dd-drop yui3-dd-draggable">\
					<span style="">'+fieldDef.i18n+'</span>\
				</li>';

				return fieldTpl;
			},

			setupDD: function() {
				var that=this,
					gListNodeId = _layoutType+'-tab-list';

				YUI().use('dd-constrain', 'dd-proxy', 'dd-drop', function(Y) {
					var goingUp = false, goingLeft = false, lastY = 0, lastX = 0;

					Y.DD.DDM.on('drop:over', function(e) {
						//Get a reference to our drag and drop nodes
						var drag = e.drag.get('node'),
							drop = e.drop.get('node');

						if(drop.get('id') == gListNodeId) return;

						//Are we dropping on a li node?
//						if (drop.get('tagName').toLowerCase() === 'li' && drop.get('parentNode').get('id') != 'available-fields') {
						if (drop.get('tagName').toLowerCase() === 'li' && drop.get('parentNode').get('id') != gListNodeId) {
							var dropParent = drop.get('parentNode');
							if(dropParent.get('id') != 'available-fields') dropParent.setStyle('border','1px dashed #0000CC');
							//Are we not going up?
							if (!goingUp) {
								drop = drop.get('nextSibling');
							}
							//Add the node to this list
							e.drop.get('node').get('parentNode').insertBefore(drag, drop);
							//Resize this nodes shim, so we can drop on it later.
							e.drop.sizeShim();
						} else if(drop.get('id') != 'available-fields' && !drop.hasClass('tab')) {
							drop.setStyle('border','1px dashed #0000CC');
						}
					});

					Y.DD.DDM.on('drag:mouseDown',function(e){
						for(var g in _layout.def.groups) {
							var gId = _layout.def.groups[g].id;
							var gFieldNode = Y.one('#'+gId+'-field-list');
							if(!gFieldNode.hasClass('yui3-dd-drop')) {
								var dObj = new Y.DD.Drop({
									node: gFieldNode,
									groups:['field-drop']
								});
							}
						}

						var groupTabList = Y.Node.all('#'+gListNodeId+' .tab');
						groupTabList.each(function(gt,i){
							if(gt.hasClass('yui3-dd-draggable')) return;
							var dd = new Y.DD.Drag({
								node: gt,
								groups:['group-reorder'],
								target: {
									padding: '0 0 0 20'
								}
							}).plug(Y.Plugin.DDProxy, {
								moveOnEnd: false
							}).plug(Y.Plugin.DDConstrained, {
								constrain2node: '#editor-wrapper'
							});
							dd.on('drag:start',function(e){
								that.resetPopup();
							});
							dd.on('drag:drag', function(e) {
								var x = e.target.lastXY[0];
			
								//is it greater than the lastY
								if (x < lastX) { goingLeft = true; }
								else { goingLeft = false; }
	
								lastX = x;
							});
	
							var gtDrop = new Y.DD.Drop({
								node: gt,
								groups:['group-reorder','group-switch']
							});
							gtDrop.on('drop:enter',function(e){
								var drag = e.drag.get('node');
	
								if(drag.hasClass('tab')) return false;
	
								var id = e.currentTarget.get('node').get('id'),
									groupId = id.replace('-tab','');
								var tabOvrCallback = function() {
										R8.LayoutEditor.groupFocus(groupId);
									}
								_tabSwitchTimeout = setTimeout(tabOvrCallback,1200);
							});
	
							gtDrop.on('drop:exit',function(e){
								if (_tabSwitchTimeout != null) {
									clearTimeout(_tabSwitchTimeout);
									_tabSwitchTimeout = null;
								}
							});
	
							gtDrop.on('drop:over', function(e) {
								//Get a reference to our drag and drop nodes
								var drag = e.drag.get('node'),
									drop = e.drop.get('node');
	
								if(!drag.hasClass('tab')) return false;
	
								var dropParent = drop.get('parentNode');
	
								if (!goingLeft) {
									drop = drop.get('nextSibling');
								}
								//Add the node to this list
								e.drop.get('node').get('parentNode').insertBefore(drag, drop);
								//Resize this nodes shim, so we can drop on it later.
								e.drop.sizeShim();
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
						that.resetPopup();

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

					Y.DD.DDM.on('drop:exit',function(e){
						var drop = e.target.get('node');

						if(drop.get('id') == gListNodeId) return false;

						if(!drop.hasClass('tab') && drop.get('tagName').toLowerCase() !== 'li') drop.setStyle('border','1px solid #EDEDED');
						Y.DD.DDM.syncActiveShims(true);
					});

					Y.DD.DDM.on('drag:end', function(e) {
						_draggingField = false;
						var drag = e.target;
						//set styles back
						drag.get('node').setStyles({
							visibility: '',
							opacity: '1'
						});
					});

					Y.DD.DDM.on('drag:drophit', function(e) {
						var drop = e.drop.get('node'),
							drag = e.drag.get('node');

						if(e.drop.inGroup(['group-switch']) || drop.get('id') == gListNodeId) return false;

						//if we are not on an li, we must have been dropped on a ul
						if (drop.get('tagName').toLowerCase() !== 'li') {
							if(drop.get('id') != 'available-fields') drop.setStyle('border','1px solid #EDEDED');
							if (!drop.contains(drag)) {
								drop.appendChild(drag);
							}
						}
					});

					var fields = Y.Node.all('#available-fields li');
					fields.each(function(v, k) {
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

					for(var g in _layout.def.groups) {
						var groupId = _layout.def.groups[g].id;

						var fields = Y.Node.all('#'+groupId+'-field-list li');
						fields.each(function(v, k) {
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
					}

					var fContainer = Y.Node.all('#available-fields');
					fContainer.each(function(v, k) {
						var tar = new Y.DD.Drop({
							node: v,
							groups:['field-drop']
						});
					});

					//-----------------------------------------------
					//Setup DD for Tab/Group re-ordering
					var gListNode = Y.one('#'+gListNodeId);

					gListNode.on('mouseenter',function(e){
						var groupTabList = Y.Node.all('#'+gListNodeId+' .tab');

						groupTabList.each(function(gt,i){
							if(gt.hasClass('yui3-dd-draggable')) return;
							var dd = new Y.DD.Drag({
								node: gt,
								groups:['group-reorder'],
								target: {
									padding: '0 0 0 20'
								}
							}).plug(Y.Plugin.DDProxy, {
								moveOnEnd: false
							}).plug(Y.Plugin.DDConstrained, {
								constrain2node: '#editor-wrapper'
							});
							dd.on('drag:start',function(e){
								that.resetPopup();
							});
							dd.on('drag:drag', function(e) {
								var x = e.target.lastXY[0];
		
								//is it greater than the lastY
								if (x < lastX) { goingLeft = true; }
								else { goingLeft = false; }

								lastX = x;
							});

							var gtDrop = new Y.DD.Drop({
								node: gt,
								groups:['group-reorder','group-switch']
							});
							gtDrop.on('drop:enter',function(e){
								var drag = e.drag.get('node');

								if(drag.hasClass('tab')) return false;

								var id = e.currentTarget.get('node').get('id'),
									groupId = id.replace('-tab','');
								var tabOvrCallback = function() {
										R8.LayoutEditor.groupFocus(groupId);
									}
								_tabSwitchTimeout = setTimeout(tabOvrCallback,1200);
							});

							gtDrop.on('drop:exit',function(e){
								if (_tabSwitchTimeout != null) {
									clearTimeout(_tabSwitchTimeout);
									_tabSwitchTimeout = null;
								}
							});


							gtDrop.on('drop:over', function(e) {
								//Get a reference to our drag and drop nodes
								var drag = e.drag.get('node'),
									drop = e.drop.get('node');

								if(!drag.hasClass('tab')) return false;

								var dropParent = drop.get('parentNode');

								if (!goingLeft) {
									drop = drop.get('nextSibling');
								}
								//Add the node to this list
								e.drop.get('node').get('parentNode').insertBefore(drag, drop);
								//Resize this nodes shim, so we can drop on it later.
								e.drop.sizeShim();
							});

						});
//TODO: remove later on
/*
						var gtReorderDrop = new Y.DD.Drop({
							node: gListNode,
							groups:['group-reorder']
						});
*/
					});
					//---end mouseenter setup for handling new tabs

					var groupTabList = Y.Node.all('#'+gListNodeId+' .tab');

					groupTabList.each(function(gt,i){
						if(gt.hasClass('yui3-dd-draggable')) return;
						var dd = new Y.DD.Drag({
							node: gt,
							groups:['group-reorder'],
							target: {
								padding: '0 0 0 20'
							}
						}).plug(Y.Plugin.DDProxy, {
							moveOnEnd: false
						}).plug(Y.Plugin.DDConstrained, {
							constrain2node: '#editor-wrapper'
						});
						dd.on('drag:start',function(e){
							that.resetPopup();
						});
						dd.on('drag:drag', function(e) {
							var x = e.target.lastXY[0];
		
							//is it greater than the lastY
							if (x < lastX) { goingLeft = true; }
							else { goingLeft = false; }

							lastX = x;
						});

						var gtDrop = new Y.DD.Drop({
							node: gt,
							groups:['group-reorder','group-switch']
						});
						gtDrop.on('drop:enter',function(e){
							var drag = e.drag.get('node');

							if(drag.hasClass('tab')) return false;

							var id = e.currentTarget.get('node').get('id'),
								groupId = id.replace('-tab','');
							var tabOvrCallback = function() {
									R8.LayoutEditor.groupFocus(groupId);
								}
							_tabSwitchTimeout = setTimeout(tabOvrCallback,1200);
						});

						gtDrop.on('drop:exit',function(e){
							if (_tabSwitchTimeout != null) {
								clearTimeout(_tabSwitchTimeout);
								_tabSwitchTimeout = null;
							}
						});

						gtDrop.on('drop:over', function(e) {
							//Get a reference to our drag and drop nodes
							var drag = e.drag.get('node'),
								drop = e.drop.get('node');

							if(!drag.hasClass('tab')) return false;

							var dropParent = drop.get('parentNode');

							if (!goingLeft) {
								drop = drop.get('nextSibling');
							}
							//Add the node to this list
							e.drop.get('node').get('parentNode').insertBefore(drag, drop);
							//Resize this nodes shim, so we can drop on it later.
							e.drop.sizeShim();
						});

					});
					var gtReorderDrop = new Y.DD.Drop({
						node: gListNode,
						groups:['group-reorder']
					});

				});
			}
		}
	}();
}
