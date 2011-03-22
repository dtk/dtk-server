
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

				this.setupTreeDD('task-'+taskDef.task_id+'-container');
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
				var taskDefType = '';
				if (taskDef.type != undefined) {
				    taskDefType = taskDef.type;
				} else {
				    taskDefType = "no_tasks";
				}
				switch(taskDefType) {
					case "no_tasks":
						taskI18n = '<b>No Pending Changes</b>';
						taskClass = 'no-pending-changes';
						break;
					case "top":
						taskI18n = 'Commit - '+taskDef.task_id;
						taskClass = 'commit-task';
						break;
					case "on_node":
						taskI18n = '<b>Node - '+taskDef.node_name+'</b>';
						taskClass = 'create-node';
						editContent = '<input type="checkbox" id="'+taskId+'" name="'+taskId+'" value="true"/>';
						break;
					case "create_node":
						taskI18n = '<b>Launch Node - '+taskDef.node_name+' ('+taskDef.image_name+')</b>';
						taskClass = 'create-node';
						editContent = '<input type="checkbox" id="'+taskId+'" name="'+taskId+'" value="true"/>';
						break;
					case "install_component":
					case "on_component":
						var compTypei18n = '';
						var compTypeAction = 'Install';
						if(taskDef.type == "on_component"){
						    compTypeAction = 'Configure';
						}
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
							case "database":
								compTypei18n = 'Database';
								taskClass = 'install-application';
								break;
							case "user":
								compTypei18n = 'User';
								compTypeAction = 'Add';
								taskClass = 'install-application';
								break;
							default:
console.log('missing component type...');
console.log(taskDef);
								compTypei18n = '{compontent_basic_type is NULL}';
								break;
						}
						taskI18n = '<b>'+compTypeAction+' '+compTypei18n+'</b> ('+taskDef.component_i18n+')';
						editContent = '<input type="checkbox" id="'+taskId+'" name="'+taskId+'" value="true"/>';
						break;
					case "setting":
						taskI18n = '<b>Configure </b>(Set '+taskDef.attribute_i18n+'='+taskDef.attribute_value+')';
						taskClass = 'configure';
						editContent = '<input type="checkbox" id="'+taskId+'" name="'+taskId+'" value="true"/>';
						break;
					default:
						taskI18n = '<b>UNKNOWN TYPE</b>';
						taskClass = 'unkown-type';
						editContent = '<input type="checkbox" id="'+taskId+'" name="'+taskId+'" value="true"/>';
console.log('unkown task type...');
console.log(taskDef);
						break;
				}
//TODO: cleanup post demos
				if (taskDefType != 'setting' && taskDefType != 'top' && taskDefType != 'no_tasks') {
					var tempDropdown = '<select name=""><option value="foo">Auto</option><option value="bar">Manual</option></select>';
					editContent = editContent + '&nbsp;' + tempDropdown + '&nbsp;';
				}
				var taskNode = R8.Utils.Y.Node.create('<li class="'+taskDefType+'"><span class="'+taskClass+'">'+editContent+taskI18n+'</span></li>');

				if(typeof(taskDef.children) !='undefined' && taskDef.children.length > 0) {
					var childTree = R8.Utils.Y.Node.create('<ul>');
					childTree.set('id','task-'+taskDef.task_id+'-container');
					childTree.addClass('task-tree');
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
			},

			setupTreeDD: function(rootListNodeId) {
				YUI().use('dd-constrain', 'dd-proxy', 'dd-drop', 'dd-scroll', function(Y) {
					//Listen for all drop:over events
					//Y.DD.DDM._debugShim = true;

					//Static Vars
					var goingUp = false, lastY = 0;

					//Get the list of li's in the lists and make them draggable
					var topTask = Y.one('#'+rootListNodeId);
					var children = topTask.all('ul');
					children.each(function(ulNode, index) {
//						if(index==0) {
							var itemList = ulNode.get('children');
							itemList.each(function(item,indx) {
								if(item.hasClass('setting')) return;
								var dd = new Y.DD.Drag({
									node: item,
									target: {
										padding: '20 0 0 100'
									},
									groups:[ulNode.get('id')]
								}).plug(Y.Plugin.DDProxy, {
									moveOnEnd: false
								});/*.plug(Y.Plugin.DDConstrained, {
									constrain2node: item.get('parentNode')
								}).plug(Y.Plugin.DDNodeScroll, {
									node: item.get('parentNode')
								});*/
							});
							var dZone = new Y.DD.Drop({
								node: ulNode,
								groups:[ulNode.get('id')]
							});
//						}
					});
//return;
					Y.DD.DDM.on('drop:over', function(e) {
						//Get a reference to out drag and drop nodes
						var drag = e.drag.get('node'),
							drop = e.drop.get('node');

						//Are we dropping on a li node?
						if (drop.get('tagName').toLowerCase() === 'li') {
							//Are we not going up?
							if (!goingUp) {
								drop = drop.get('nextSibling');
							}
							//Add the node to this list
							e.drop.get('node').get('parentNode').insertBefore(drag, drop);
							//Set the new parentScroll on the nodescroll plugin
//							e.drag.nodescroll.set('parentScroll', e.drop.get('node').get('parentNode'));                        
							//Resize this nodes shim, so we can drop on it later.
							e.drop.sizeShim();
						}
					});
					//Listen for all drag:drag events
					Y.DD.DDM.on('drag:drag', function(e) {
						//Get the last y point
						var y = e.target.lastXY[1];
						//is it greater than the lastY var?
						if (y < lastY) {
							//We are going up
							goingUp = true;
						} else {
							//We are going down.
							goingUp = false;
						}
						//Cache for next check
						lastY = y;
						Y.DD.DDM.syncActiveShims(true);
					});
					//Listen for all drag:start events
					Y.DD.DDM.on('drag:start', function(e) {
						//Get our drag object
						var drag = e.target;
						//Set some styles here
						drag.get('node').setStyle('opacity', '.25');
						drag.get('dragNode').set('innerHTML', drag.get('node').get('innerHTML'));
						drag.get('dragNode').setStyles({
							opacity: '.5',
							borderColor: drag.get('node').getStyle('borderColor'),
							backgroundColor: drag.get('node').getStyle('backgroundColor')
						});
					});
					//Listen for a drag:end events
					Y.DD.DDM.on('drag:end', function(e) {
						var drag = e.target;
						//Put out styles back
						drag.get('node').setStyles({
							visibility: '',
							opacity: '1'
						});
					});
					//Listen for all drag:drophit events
					Y.DD.DDM.on('drag:drophit', function(e) {
						var drop = e.drop.get('node'),
							drag = e.drag.get('node');

						//if we are not on an li, we must have been dropped on a ul
						if (drop.get('tagName').toLowerCase() !== 'li') {
							if (!drop.contains(drag)) {
								drop.appendChild(drag);
								//Set the new parentScroll on the nodescroll plugin
//								e.drag.nodescroll.set('parentScroll', e.drop.get('node'));                                
							}
						}
					});

				});
			}
		}
	}();
	})(R8)
}