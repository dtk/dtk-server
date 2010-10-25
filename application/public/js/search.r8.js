if (!R8.Search) {

	(function(R8) {
		R8.Search = function() {
			return {

				page : function(modelName,start) {
					var searchForm = document.getElementById(modelName+'-search-form');
					var savedSearchElem = R8.Utils.Y.one('#saved_search');
					var saved_search = {'start':start};

					YUI().use("json", function(Y) {
						savedSearchElem.set('value',Y.JSON.stringify(saved_search));
						searchForm.submit();
					});
				},

				sort : function(modelName,field,order) {
					var searchForm = document.getElementById(modelName+'-search-form');
					var savedSearchElem = R8.Utils.Y.one('#saved_search');
					var currentStartElem = R8.Utils.Y.one('#'+modelName+'_current_start');

					var saved_search = {
							'start':currentStartElem.get('value'),
							'order_by':[{'field':field,'order':order}]
						};

					YUI().use("json", function(Y) {
						savedSearchElem.set('value',Y.JSON.stringify(saved_search));
						searchForm.submit();
					});
				},
				
				toggleSearch : function(modelName) {
					var spElem = R8.Utils.Y.one('#'+modelName+'-search-panel');

					(spElem.getStyle('display') == 'none') ? spElem.setStyle('display','block') : spElem.setStyle('display','none');
				}
			}
		}();
	})(R8);
}
