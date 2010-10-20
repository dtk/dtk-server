if (!R8.Search) {

	(function(R8) {
		R8.Search = function() {
			return {

				page : function(modelName,start) {
					var searchForm = document.getElementById(modelName+'-search-form');
					var queryParamsElem = R8.Utils.Y.one('#query_params');
					var query_params = {'start':start};

					YUI().use("json", function(Y) {
						queryParamsElem.set('value',Y.JSON.stringify(query_params));
						searchForm.submit();
					});
				},

				sort : function(modelName,field,order) {
					var searchForm = document.getElementById(modelName+'-search-form');
					var queryParamsElem = R8.Utils.Y.one('#query_params');
					var currentStartElem = R8.Utils.Y.one('#'+modelName+'_current_start');

					var query_params = {
							'start':currentStartElem.get('value'),
							'order_by':{}
						};
					query_params['order_by'][field] = order;

					YUI().use("json", function(Y) {
						queryParamsElem.set('value',Y.JSON.stringify(query_params));
						searchForm.submit();
					});
				}
			}
		}();
	})(R8);
}
