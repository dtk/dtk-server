
if(!R8.AssemblyTool2) {

	(function(R8){

	R8.AssemblyTool2 = function() {
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
				_submitBtnNode.on('click',this.formSubmit,this);
//				formNode.setAttribute('onsubmit',this.formSubmit);
			},
			cleanup: function() {
				
			},
			formSubmit: function(e) {
				var currentEditorView = R8.IDE.get('currentEditorView');

				if(currentEditorView == null && currentEditorView.type != 'target') {
					alert('Open a target in the editor to create an assembly');
					this.cleanup();
					R8.IDE.destroyShim();
					return false;
				}

				var items = currentEditorView.getSelectedItems();
				var itemCount = 0;
				for(var i in items) { itemCount++; }

				if(itemCount == 0) {
					alert('Please select one or more items to create an assembly');
					this.cleanup();
					R8.IDE.destroyShim();
					return false;
				}

				var item_list = [];
				for(var i in items) {
					item_list.push(items[i]);
				}

				var _this=this;
				YUI().use("json","node", function (Y) {
console.log(item_list);
					Y.one('#item_list').set('value',Y.JSON.stringify(item_list));

					var successCallback = function(ioId,responseObj) {
//						_this.setNodeSearchResults(ioId,responseObj);
console.log('should be getting to showign alert...');
						R8.IDE.showAlert('Created Assembly');
					}
					var callbacks = {
						'io:success': successCallback
					};
					var params = {
						'cfg' : {
							method : 'POST',
							form: {
								id : 'modal-form',
//								upload: true
							}
						},
						'callbacks': callbacks
					};
					R8.Ctrl.call('workspace/clone_assembly_ide',params);
					_this.cleanup();
					R8.IDE.destroyShim();
				});
				return;
			}
		}
	}();
	})(R8)
}