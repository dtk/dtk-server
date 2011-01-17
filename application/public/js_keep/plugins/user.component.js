if(!R8.UserComponent) {

	(function(R8){

	R8.UserComponent = function() {
		var _events = {},
			_tabListNodeId = 'modal-tab-list',
			_tabListNode = null;

		var _tabs = ['general','home-directory','ssh'];

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
			}
		}
	}();
	})(R8)
}