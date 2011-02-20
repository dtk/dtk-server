
if (!R8.Component) {

	R8.Component = function() {
		var _pageContainerNode = null,
			_topbarNode = null,
			_mainBodyNode = null,
			_mblPaneNode = null,
			_mbrPaneNode = null,
			_detailsHeader = null,
			_contentWrapperNode = null,

			_viewportRegion = null;

		return {
			init: function() {
			},
			displayInit: function() {
				_pageContainerNode = R8.Utils.Y.one('#page-container');
				_mainBodyNode = R8.Utils.Y.one('#main-body');
				_topbarNode = R8.Utils.Y.one('#page-topbar');

				_mblPaneNode = R8.Utils.Y.one('#mb-l-pane');
				_mbrPaneNode = R8.Utils.Y.one('#mb-r-pane');

				_detailsHeaderNode = R8.Utils.Y.one('#details-header');
				_contentWrapperNode = R8.Utils.Y.one('#content-wrapper');

				var that = this;
				R8.Utils.Y.one(window).on('resize',function(e){
					that.resizePage();
				});
				this.resizePage();
			},
			resizePage: function() {
				_viewportRegion = _pageContainerNode.get('viewportRegion');

				var vportHeight = _viewportRegion['height'];
				var vportWidth = _viewportRegion['width'];

				var topbarRegion = _topbarNode.get('region');
				var mainBodyHeight = vportHeight - (topbarRegion['height']);
				_mainBodyNode.setStyles({'height':mainBodyHeight});

				var mblPaneWidth = _mblPaneNode.get('region').width;
				var mbrPaneWidth = (vportWidth - mblPaneWidth);
				_mbrPaneNode.setStyles({'width': mbrPaneWidth,'height':mainBodyHeight,'left': mblPaneWidth});

				var contentBorder = 10;
				var contentHeight = (mainBodyHeight - _detailsHeaderNode.get('region').height - contentBorder);
				_contentWrapperNode.setStyles({'height': contentHeight, 'width': (mbrPaneWidth-contentBorder)});
			}
		}
	}();
}
