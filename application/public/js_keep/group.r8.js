
if (!R8.Group) {

	R8.Group = function(groupDef,viewSpace) {
		var _def = groupDef,
			_id = _def['object']['id'],
			_type = _def['type'],
			_dataModel = null,
			_status = null,
			_node = null,
			_top = null,
			_left = null,

			_minimizeBtnId = null,
			_minimizeBtnNode = null,
			_maximizeBtnId = null,
			_maximizeBtnNode = null,

			_viewSpace = viewSpace,
			_toolbar = null;

		return {

			render: function() {
				var tpl_callback = _def['tpl_callback'];
				return R8.Rtpl[tpl_callback]({'node_group': _def['object']});
			},

			init: function() {
				_node = R8.Utils.Y.one('#item-'+_id);
				_status = _node.getAttribute('data-status');

				if(_status != 'pending_setup') return;

				_top = _node.getStyle('top');
				_left = _node.getStyle('left');
				_dataModel = _node.getAttribute('data-model');

				this.setupMinMax();

				if(typeof(_def['toolbar_def']) != 'undefined') {
					_def['toolbar_def']['parent_node_id'] = this.get('node_id');
					_toolbar = new R8.Toolbar(_def['toolbar_def']);
					_toolbar.init();
				}

/*
				if(_status == 'pending_delete') {
					_viewSpace.pushPendingDelete(_id,{
						'top':_node.getStyle('top'),
						'left':_node.getStyle('left')
					})
				}
*/
			},

			get: function(get_name) {
				switch(get_name) {
					case "id":
						return _id;
						break;
					case "node_id":
						return _node.get('id');
						break;
					case "node":
						return _node;
						break;
					default:
						return null;
						break;
				}
			},

			setupMinMax: function() {
				var nodeId = this.get('node_id'),
					_minimizeBtnId = nodeId+'-minimize-btn',
					_minimizeBtnNode = R8.Utils.Y.one('#'+_minimizeBtnId),
					_maximizeBtnId = nodeId+'-maximize-btn',
					_maximizeBtnNode = R8.Utils.Y.one('#'+_maximizeBtnId);


				if(_minimizeBtnNode != null) {

					//setup minimize
					_minimizeBtnNode.on('mouseover',function(e){
						e.currentTarget.setStyle('backgroundPosition','-16px 0px');
					});
					_minimizeBtnNode.on('mouseout',function(e){
						e.currentTarget.setStyle('backgroundPosition','0px 0px');
					});
					_minimizeBtnNode.on('click',function(e){
						this.minimize();
					},this);

					//setup maximize
					_maximizeBtnNode.on('mouseover',function(e){
						e.currentTarget.setStyle('backgroundPosition','-16px -16px');
					});
					_maximizeBtnNode.on('mouseout',function(e){
						e.currentTarget.setStyle('backgroundPosition','0px -16px');
					});
					_maximizeBtnNode.on('click',function(e){
						this.maximize();
					},this);
				}
			},

			maximize: function() {
				var itemNode = this.get('node'), itemId = this.get('node_id');

				R8.Utils.Y.one('#'+itemId+'-medium').setStyle('display','none');
				R8.Utils.Y.one('#'+itemId+'-large').setStyle('display','block');
				itemNode.addClass('large');
				itemNode.removeClass('medium');
			},

			minimize: function() {
				var itemNode = this.get('node'),itemId = this.get('node_id');

				R8.Utils.Y.one('#'+itemId+'-large').setStyle('display','none');
				R8.Utils.Y.one('#'+itemId+'-medium').setStyle('display','block');
				itemNode.addClass('medium');
				itemNode.removeClass('large');
			},

			hide: function() {
				
			},
			show: function() {
				
			},
			focus: function() {
				
			},

			blur: function() {
				
			}
		}
	};
}
