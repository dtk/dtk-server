if (!R8.Search) {

	(function(R8) {
		R8.Search = function() {
			return {

				page : function(model_name,start) {
					var searchForm = document.getElementById(model_name+'-search-form');
					var queryParamsElem = R8.Utils.Y.one('#query_params');
					var query_params = {'start':start};

					YUI().use("json", function(Y) {
						queryParamsElem.set('value',Y.JSON.stringify(query_params));
						searchForm.submit();
					});
				},

				sort : function() {
					
				}
			}
		}();
	})(R8);
}
