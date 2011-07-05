
if(!R8.CreateProjectTool) {

	(function(R8){

	R8.CreateProjectTool = function() {
		var _events = {},
			_tabListNodeId = 'modal-tab-list',
			_tabListNode = null,
			_formNode = null,
			_submitBtnNode = null;

		var _tabs = ['general','targets'];

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

					R8.Utils.Y.one('#'+tabNodeId).removeClass('selected');
					R8.Utils.Y.one('#'+tabContentNodeId).setStyle('display','none');
				}
				var tabNodeId = tabId+'-tab';
				var tabContentNodeId = tabId+'-tab-content';
				R8.Utils.Y.one('#'+tabNodeId).addClass('selected');
				R8.Utils.Y.one('#'+tabContentNodeId).setStyle('display','block');
			},
			initForm: function() {

				_formNode = R8.Utils.Y.one('#modal-form');
				_submitBtnNode = R8.Utils.Y.one('#modal-form-submit-btn');
				_submitBtnNode.on('click',function(e){
					this.formSubmit();
				},this);
//				formNode.setAttribute('onsubmit',this.formSubmit);
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

				R8.Ctrl.call('project/create',params);

				this.cleanup();
				R8.IDE.destroyShim();
			}
		}
	}();
	})(R8)
}