
if(!R8.AssemblyTool) {

	(function(R8){

	R8.AssemblyTool = function() {
		var _events = {},
			_tabListNodeId = 'modal-tab-list',
			_tabListNode = null,
			_formNode = null,
			_submitBtnNode = null;

		var _tabs = ['overview','details'];

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
				var items = R8.Workspace.getSelectedItems();

				YUI().use("json","node", function (Y) {
					Y.one('#item_list').set('value',Y.JSON.stringify(items));

					var params = {
						'cfg' : {
							method : 'POST',
							form: {
								id : 'modal-form',
								upload: true
							}
						}
					};
					R8.Ctrl.call('workspace/clone_assembly',params);
				});
				R8.Workspace.destroyShim();
				return;
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
				var params = {
					'cfg' : {
						method : 'GET'
					}
				};
				var datacenter_id = R8.Workspace.get('context_id');
				R8.Ctrl.call('workspace/commit_changes/'+datacenter_id,params);

console.log('helllloooo there.....');
*/
			}
		}
	}();
	})(R8)
}