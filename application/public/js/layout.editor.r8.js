

if(!R8.LayoutEditor) {

	R8.LayoutEditor = function() {
		var _groupListNode = null
			_addGroupNode = null,
			_contentWrapperNode = null,
			_modalHeaderNode = null,
			_editorTplWrapperNode = null,
			_events = {},
			_parentId = null,

			_availFields = {},
			_layoutDef = {};
/*
			_layoutDef = {
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
			_draggingField = false,
			_tabSwitchTimeout = null;

		return {
			layoutType: 'wspace-edit',

			init: function(parentId,layoutDef,fieldDefs) {
				if(document.getElementById('editor-tpl-wrapper') == null) {
					var that = this;
					var initCallback = function() {
					    R8.LayoutEditor.init(parentId,layoutDef,fieldDefs);
					}
					setTimeout(initCallback,25);
					return;
				}
				_parentId = parentId;
				_fieldDefs = fieldDefs;
				_layoutDef = layoutDef;

				for(var g in _layoutDef.groups) {
					if(g==0) {
						_layoutDef.groups[g].selected = 'selected';
						_layoutDef.groups[g].content_display = 'block';
					} else {
						_layoutDef.groups[g].selected = '';
						_layoutDef.groups[g].content_display = 'none';
					}
				}
				_editorTplWrapperNode = R8.Utils.Y.one('#editor-tpl-wrapper');
				_editorTplWrapperNode.append(R8.Rtpl.wspace_edit_layout({
					'layout_def': _layoutDef
				}));

				_groupListNode = R8.Utils.Y.one('#modal-tab-list');
				_addGroupNode = R8.Utils.Y.one('#add-group-btn');
				_contentWrapperNode = R8.Utils.Y.one('#modal-content-wrapper');
				_modalHeaderNode = R8.Utils.Y.one('#modal-header');

//TODO: this is temp until fully refactoring the view/rtpl stuff
this.setI18n(fieldDefs);

//				this.renderLayout();
				for(var i in fieldDefs) {
					if(!this.fieldInLayout(fieldDefs[i].name)) {
						_availFields[fieldDefs[i].name] = fieldDefs[i];
						this.addAvailField(fieldDefs[i]);
					}
				}

				_modalHeaderNode.on('mouseenter',function(e){
					e.currentTarget.setStyles({'border':'1px dashed #0000CC'});
				});
				_modalHeaderNode.on('mouseleave',function(e){
					e.currentTarget.setStyles({'border':'1px solid #EDEDED'});
				});
				_modalHeaderNode.on('click',function(e){
					R8.Utils.Y.one('#title-txt').setStyles({'display':'none'});
					R8.Utils.Y.one('#modal-header').setStyles({'border':'1px solid #EDEDED'});
					R8.Utils.Y.one('#title-input-wrapper').setStyle('display','block');
					R8.Utils.Y.one('#title-input').focus();
				});
				R8.Utils.Y.one('#title-input').on('change',function(e){
					R8.Utils.Y.one('#title-txt').set('innerHTML',this.get('value'));
					_layoutDef.i18n = this.get('value');
				});
				R8.Utils.Y.one('#title-input').on('blur',function(e){
					var inputVal = R8.Utils.Y.one('#title-input').get('value');
					R8.Utils.Y.one('#title-input-wrapper').setStyle('display','none');
					R8.Utils.Y.one('#title-txt').setStyles({'display':'block'});
					_layoutDef.i18n = inputVal;
				});

				_events['addGroupClick'] = _addGroupNode.on('click',this.addGroup,this);
				_events['groupClick'] = R8.Utils.Y.delegate('click',this.groupClick,'#modal-tab-list','.tab',this);

//				_events['groupDblClick'] = R8.Utils.Y.delegate('dblclick',function(e){
//					console.log('hello there...');
//				},'#layout-tab-list','.tab',this);

				this.setupDD();
			},
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
			getCurrentDef: function() {
				var currentDef = _layoutDef;
				var that = this;
				for(var g in _layoutDef.groups) {
					currentDef.groups[g].fields = [];
					R8.Utils.Y.all('#'+_layoutDef.groups[g].name+'-field-list li').each(function(){
						currentDef.groups[g].fields.push(that.getFieldDefByName(this.get('id')));
					});
				}
				return currentDef;
			},
			save: function() {
				var layoutDef = this.getCurrentDef();
				var layoutDefJson = R8.Utils.Y.JSON.stringify(_layoutDef),
					params = {
						'cfg': {
							form: {
								id : 'wspace-edit-form',
								upload : false
							}
						}
					}
				document.getElementById(this.layoutType+'-form')['id'].value='';
				document.getElementById(this.layoutType+'-form')['def'].value=layoutDefJson;
				R8.Ctrl.call('component/save_layout/'+_parentId,params);
			},
			deploy: function() {
				var layoutDefJson = R8.Utils.Y.JSON.stringify(_layoutDef),
					params = {
						'cfg': {
							form: {
								id : 'wspace-edit-form',
								upload : false
							}
						}
					}
				document.getElementById(this.layoutType+'-form')['def'].value=layoutDefJson;
				document.getElementById(this.layoutType+'-form')['active'].value='true';
				R8.Ctrl.call('component/publish_layout/'+_parentId,params);
			},
//-----------------------------------------
//TODO: remove after cleanup
			setI18n: function(fieldDefs) {
				for(var g in _layoutDef.groups) {
					for(var f in _layoutDef.groups[g].fields) {
						_layoutDef.groups[g].fields[f].i18n = this.getFieldI18n(_layoutDef.groups[g].fields[f].name,fieldDefs);
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

				_layoutDef.i18n = inputVal;
			},
			fieldInLayout: function(fieldName) {
				for(var g in _layoutDef.groups) {
					var fieldList = _layoutDef.groups[g].fields;
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
			},
			renderLayout: function() {
				for(var g in _layoutDef.groups) {
					if(g==0) {
						_layoutDef.groups[g].focus=true;
					}
					this.renderGroup(_layoutDef.groups[g]);
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
				_layoutDef.groups.push({
					'name':groupId,
					'num_cols':1,
					'i18n': groupLabel,
					'fields':[]
				});
*/
//				this.groupFocus(_layoutDef.groups.length-1);
			},
			addGroup: function(e) {
				var groupIndex = _groupListNode.get('children').size()+1;
				var groupId = 'group-'+groupIndex;
				var groupLabel = 'Group '+groupIndex;

				var newGroupNode = R8.Utils.Y.Node.create(this.getGroupMarkup(groupId,groupLabel,'selected'));
				_groupListNode.append(newGroupNode);
				_contentWrapperNode.append(this.getContentMarkup(groupId,'block'));

				_layoutDef.groups.push({
					'name':groupId,
					'num_cols':1,
					'i18n': groupLabel,
					'fields':[]
				});
				this.groupFocus(_layoutDef.groups.length-1);
			},
			groupFocus: function(groupIndex) {
				var groupId = _layoutDef.groups[groupIndex].name;
				for(var g in _layoutDef.groups) {
					var gId = _layoutDef.groups[g].name;
					R8.Utils.Y.one('#'+gId+'-tab').removeClass('selected');
					R8.Utils.Y.one('#'+gId+'-content').setStyle('display','none');
				}
				R8.Utils.Y.one('#'+groupId+'-tab').addClass('selected');
				R8.Utils.Y.one('#'+groupId+'-content').setStyle('display','block');
			},
			groupClick: function(e) {
				var id = e.currentTarget.get('id'),
					groupId = id.replace('-tab',''),
					groupIndex = this.getGIndexByName(groupId);
				this.groupFocus(groupIndex);
			},
			getGIndexByName: function(groupName) {
				for(var g in _layoutDef.groups) {
					if(groupName === _layoutDef.groups[g].name) return g;
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
				var that=this;

				YUI().use('dd-constrain', 'dd-proxy', 'dd-drop', function(Y) {
					var goingUp = false, lastY = 0;

					Y.DD.DDM.on('drop:over', function(e) {
						//Get a reference to our drag and drop nodes
						var drag = e.drag.get('node'),
							drop = e.drop.get('node');

						//Are we dropping on a li node?
//						if (drop.get('tagName').toLowerCase() === 'li' && drop.get('parentNode').get('id') != 'available-fields') {
						if (drop.get('tagName').toLowerCase() === 'li' && drop.get('parentNode').get('id') != 'modal-tab-list') {
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
						for(var g in _layoutDef.groups) {
							var gId = _layoutDef.groups[g].name;
							var gFieldNode = Y.one('#'+gId+'-field-list');
							if(!gFieldNode.hasClass('yui3-dd-drop')) {
								var dObj = new Y.DD.Drop({
									node: gFieldNode,
									groups:['field-drop']
								});
							}
						}

						var groupTabList = Y.Node.all('#modal-tab-list .tab');
						groupTabList.each(function(gt,i){
//TODO: remove after refactoring plus btn out of <ul>
							if(gt.hasClass('yui3-dd-drop')) return;
							var dObj = new Y.DD.Drop({
								node: gt,
								groups:['group-switch']
							});
							dObj.on('drop:enter',function(e){
								var id = e.currentTarget.get('node').get('id'),
									groupId = id.replace('-tab','');
								var tabOvrCallback = function() {
										R8.LayoutEditor.groupFocus(that.getGIndexByName(groupId));
									}
								_tabSwitchTimeout = setTimeout(tabOvrCallback,1500);
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

					Y.DD.DDM.on('drop:exit',function(e){
						var drop = e.target.get('node');
						if(!drop.hasClass('tab') && drop.get('tagName').toLowerCase() !== 'li') drop.setStyle('border','1px solid #EDEDED');
						Y.DD.DDM.syncActiveShims(true);
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

					for(var g in _layoutDef.groups) {
						var groupId = _layoutDef.groups[g].name;

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
				});
			}
		}
	}();
}
