
if(!R8.CommitTool) {

	(function(R8){

	R8.CommitTool = function() {
		var _events = {},
			_tabListNodeId = 'modal-tab-list',
			_tabListNode = null,
			_formNode = null,
			_submitBtnNode = null;

		var _tabs = ['change-list','details'];

		return {
			init: function() {
				_tabListNode = R8.Utils.Y.one('#'+_tabListNodeId);
				if(_tabListNode == null) {
					var that = this;
					var setupCallback = function() {
						that.init();
					}
					setTimeout(setupCallback,50);
					return;
				}
				this.setupModalFormTabs();
				this.initForm();
			},

			renderTree: function(taskDef,viewType,panel_id) {
				testNode = R8.Utils.Y.one('#'+panel_id);
				if(testNode == null) {
					var that = this;
					var renderCallback = function() {
						that.renderTree(taskDef,viewType,panel_id);
					}
					setTimeout(renderCallback,50);
					return;
				}

/*
for(var i=taskDef.children.length-1; i >=0; i--) {
	if(i > 1) delete(taskDef.children[i]);
}
/*
console.log(taskDef);
for(var i=taskDef.children[0].children.length-1; i >=0; i--) {
	if(i > 0) delete(taskDef.children[0].children[i]);
}
taskDef.children[0].children[0].children = [];
*/

				var rootNode = R8.Utils.Y.Node.create('<ul>');
				rootNode.set('id','task-'+taskDef.task_id+'-container');
				rootNode.addClass('filetree');

				this.setTaskContent(taskDef,viewType,rootNode);
//				R8.Workspace.get('modalNode').append(rootNode);
				R8.Utils.Y.one('#'+panel_id).append(rootNode);

				$("#"+rootNode.get('id')).treeview({
					collapsed: true
				});

			},
/*
			getTreeNode: function(taskDef,viewType) {
				var treeNode = R8.Utils.Y.Node.create('<ul>');
				treeNode.set('id','task-'+taskDef.task_id+'-container');
				if(taskDef.type == 'top') treeNode.addClass('filetree');

				this.setTaskContent(taskDef,viewType,treeNode);

				return treeNode;
			},
*/
			setTaskContent: function(taskDef,viewType,parentNode) {
				var taskContent = '',taskClass='',editContent='',
					taskId = 'task-'+taskDef.task_id+'-commit';

				switch(taskDef.type) {
					case "top":
						taskI18n = 'Commit - '+taskDef.task_id;
						taskClass = 'commit-task';
						break;
					case "create_node":
						taskI18n = '<b>Launch Node - '+taskDef.node_name+'</b>({need image type/name info})';
						taskClass = 'create-node';
						editContent = '<input type="checkbox" id="'+taskId+'" name="'+taskId+'" value="true"/>';
						break;
					case "install_component":
						var compTypei18n = '';
						switch(taskDef.component_basic_type) {
							case "language":
								compTypei18n = 'Language';
								taskClass = 'install-language';
								break;
							case "feature":
								compTypei18n = 'Application';
								taskClass = 'install-application';
								break;
							case "application":
								compTypei18n = 'Application';
								taskClass = 'install-application';
								break;
							case "client":
								compTypei18n = 'Client';
								taskClass = 'install-application';
								break;
							case "service":
								compTypei18n = 'Application';
								taskClass = 'install-application';
								break;
							default:
console.log('missing component type...');
console.log(taskDef);
								compTypei18n = '{compontent_basic_type is NULL}';
								break;
						}
						taskI18n = '<b>Install '+compTypei18n+'</b> ('+taskDef.component_name+')';
						editContent = '<input type="checkbox" id="'+taskId+'" name="'+taskId+'" value="true"/>';
						break;
					case "setting":
						taskI18n = '<b>Configure </b>(Set '+taskDef.attribute_name+'='+taskDef.attribute_value+')';
						taskClass = 'configure';
						editContent = '<input type="checkbox" id="'+taskId+'" name="'+taskId+'" value="true"/>';
						break;
					default:
						taskI18n = '<b>UNKOWN TYPE</b>';
						taskClass = 'unkown-type';
						editContent = '<input type="checkbox" id="'+taskId+'" name="'+taskId+'" value="true"/>';
console.log('unkown task type...');
console.log(taskDef);
						break;
				}
				var taskNode = R8.Utils.Y.Node.create('<li><span class="'+taskClass+'">'+editContent+taskI18n+'</span></li>');

				if(typeof(taskDef.children) !='undefined' && taskDef.children.length > 0) {
					var childTree = R8.Utils.Y.Node.create('<ul>');
					childTree.set('id','task-'+taskDef.task_id+'-container');
					for(var i in taskDef.children) {
						this.setTaskContent(taskDef.children[i],viewType,childTree);
					}
					taskNode.append(childTree);
				}

				parentNode.append(taskNode);

				return parentNode;
			},
/*
	<ul id="treeview-test" class="filetree">
		<li><span class="create-node"><input type="checkbox"/><b>Launch Node</b> (Ubuntu 10.4LTE)</span>
*/

			setupModalFormTabs: function() {
				_events['tabClick'] = R8.Utils.Y.delegate('click',function(e){
					var tabNodeId = e.currentTarget.get('id'),
						tabId = tabNodeId.replace('-tab','');

					this.changeTabFocus(tabId);
				},_tabListNode,'.tab',this);
				var itemMouseOver = R8.Utils.Y.delegate('mouseenter',function(e){
//					e.currentTarget.addClass('active');
				},_tabListNode,'.tab',this);

			},
			changeTabFocus: function(tabId) {
				for(var t in _tabs) {
					var tabNodeId = _tabs[t]+'-tab';
					var tabContentNodeId = _tabs[t]+'-tab-content';
//console.log('tabNodeId:'+tabNodeId);
//console.log('tabContentNodeid:'+tabContentNodeId);
					R8.Utils.Y.one('#'+tabNodeId).removeClass('selected');
					R8.Utils.Y.one('#'+tabContentNodeId).setStyle('display','none');
				}
				var tabNodeId = tabId+'-tab';
				var tabContentNodeId = tabId+'-tab-content';
				R8.Utils.Y.one('#'+tabNodeId).addClass('selected');
				R8.Utils.Y.one('#'+tabContentNodeId).setStyle('display','block');
			},
			initForm: function() {
/*
				var dirNameNode = R8.Utils.Y.one('#home_directory_name'), userNameNode = R8.Utils.Y.one('#username');
				//console.log(R8.Utils.Y.one('#username'));
				userNameNode.on('keyup', function(e){
					var usernameValue = e.currentTarget.get('value');
					dirNameNode.set('value', usernameValue);
				});
*/
				_formNode = R8.Utils.Y.one('#modal-form');
				_submitBtnNode = R8.Utils.Y.one('#modal-form-submit-btn');
				_submitBtnNode.on('click',this.formSubmit);
//				formNode.setAttribute('onsubmit',this.formSubmit);
			},

			formSubmit: function(e) {
				R8.Workspace.destroyShim();
/*
				var params = {
					'cfg' : {
						method : 'POST',
						form: {
							id : 'modal-form',
							upload: false
						}
					}
				};
*/				var params = {
					'cfg' : {
						method : 'GET'
					}
				};
				var datacenter_id = R8.Workspace.get('context_id');
				R8.Ctrl.call('workspace/commit_changes/'+datacenter_id,params);

console.log('helllloooo there.....');
			}
		}
	}();
	})(R8)
}