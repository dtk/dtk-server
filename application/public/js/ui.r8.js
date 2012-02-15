
if(!R8.UI) {

		R8.UI = function() {
			var _cfg = null,
				_pageContainerNode = null,
				_pageContainerNodeId = 'page-container',

				_topBarExists = true,
				_topBarNode = null,
				_topBarHeight = 0,

				_modalNode = null,
				_modalNodeId = 'wspace-modal',
				_shimNodeId = null,
				_shimNode = null,
	
				_alertNode = null,
				_alertNodeId = null,
		
				_events = {};

			return {
				init: function() {
//DEBUG
console.log('inside of ui.r8....');
console.log(R8.Utils.Y);
					_pageContainerNode = R8.Utils.Y.one('#'+_pageContainerNodeId);
					_topBarNode = R8.Utils.Y.one('#page-topbar');
					if(_topBarNode != null) {
						_topBarExists = true;
						_topBarHeight = _topBarNode.get('region').height;
					} else {
						_topBarExists = false;
						_topBarHeight = 0;
					}
					
				},
				shimify: function() {
					var _shimNodeId = R8.Utils.Y.guid(),
						nodeRegion = _pageContainerNode.get('region'),
						shimTop = _topBarHeight,
						height = nodeRegion.height - shimTop,
						width = nodeRegion.width;
	
					_pageContainerNode.append('<div id="'+_shimNodeId+'" class="ui-shim" style="top:'+shimTop+'px; height:'+height+'px; width:'+width+'px;"></div>');
					_shimNode = R8.Utils.Y.one('#'+_shimNodeId);
					_shimNode.setStyle('opacity','0.7');
					_shimNode.on('click',function(e){
						this.closeModal();
					},this);
				},
				destroyShim: function() {
					_shimNode.purge(true);
					_shimNode.remove();
					_shimId = null;
					_shimNode = null;
				},
	
				renderModal: function() {
					this.shimify();

					var modalTpl = '<div id="'+_modalNodeId+'" class="ui-modal" style="display:none;">\
										<div id="'+_modalNodeId+'-content" class="content"></div>\
									</div>',

						nodeRegion = _shimNode.get('region'),
						height = nodeRegion.bottom - nodeRegion.top,
						width = nodeRegion.right - nodeRegion.left,
						mTop = Math.floor((height - 350)/2)+_topBarHeight,
						mLeft = Math.floor((width-700)/2);

					_pageContainerNode.append(modalTpl);
					_modalNode = R8.Utils.Y.one('#'+_modalNodeId);
					_modalNode.setStyles({'top':mTop,'left':mLeft,'display':'block'});
	
					var contentNode = R8.Utils.Y.one('#'+_modalNodeId+'-content');
	
					return contentNode;
				},
				closeModal: function() {
					_modalNode.purge(true);
					_modalNode.remove();
					_modalNode = null;

					this.destroyShim();
				}
			}
		}();
}
