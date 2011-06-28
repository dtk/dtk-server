
if(!R8.UserComponent) {

	(function(R8){

	R8.UserComponent = function() {
		var _events = {},
			_tabListNodeId = 'modal-tab-list',
			_tabListNode = null,
			_formNode = null,

			_addKeyBtnNode = null,
			_numKeys = 1,
			_submitBtnNode = null;

//		var _tabs = ['general','home-directory','ssh'];
		var _tabs = ['general','ssh-keys'];

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

					R8.UserComponent.changeTabFocus(tabId);
				},_tabListNode,'.tab');
				var itemMouseOver = R8.Utils.Y.delegate('mouseenter',function(e){
//					e.currentTarget.addClass('active');
				},_tabListNode,'.tab');

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
				var dirNameNode = R8.Utils.Y.one('#home_directory_name'), userNameNode = R8.Utils.Y.one('#username');
				//console.log(R8.Utils.Y.one('#username'));
				userNameNode.on('keyup', function(e){
					var usernameValue = e.currentTarget.get('value');
					dirNameNode.set('value', usernameValue);
				});

				_formNode = R8.Utils.Y.one('#modal-form');
				_submitBtnNode = R8.Utils.Y.one('#modal-form-submit-btn');
				_submitBtnNode.on('click',function(e){
					this.formSubmit();
				},this);
				_addKeyBtnNode = R8.Utils.Y.one('#add-ssh-key-btn');
				_addKeyBtnNode.on('click',function(e){
					this.addKeyToForm();
				},this);
			},
			addKeyToForm: function() {
				_numKeys++;
				var titleId = 'ssh_key_title_'+_numKeys, keyId = 'ssh_key_'+_numKeys;

				var tableNode = R8.Utils.Y.one('#ssh-keys-table');
				newKeyTpl = '<tr><td class="label">Key Title</td></tr>\
							<tr><td class="field"><input type="text" value="" size="30" id="'+titleId+'" name="ssh_key_title[]"/></td></tr>\
							<tr><td class="label">SSH Key</td></tr>\
							<tr><td class="field"><textarea rows="8" cols="40" id="'+keyId+'" name="ssh_key[]"></textarea></td></tr>';

				tableNode.append(newKeyTpl);
			},
			cleanup: function() {
				
			},
			formSubmit: function(e) {
				var params = {
					'cfg' : {
						method : 'POST',
						form: {
							id : 'modal-form',
							upload: false
						}
					}
				};

				R8.Ctrl.call('component/edit_user/',params);

				this.cleanup();
				R8.IDE.destroyShim();
			}
		}
	}();
	})(R8)
}