if (!R8.Search) {

	(function(R8) {
		R8.Search = function() {
			return {
				searchObjList : {},

				getSearchInfo : function(searchContext) {
					var searchId = R8.Search.searchObjList[searchContext]['currentSearch'];
					var searchObj = R8.Search.searchObjList[searchContext]['searches'][searchId];
					var modelName = searchObj['search_pattern'][':relation'];
					return {
						'searchId':searchId,
						'searchObj':searchObj,
						'modelName':modelName
					}
				},

				newSearchContext  : function(searchContext) {
					this.searchObjList[searchContext] = {
						'currentSearch':'',
						'searches':{}
					};
				},

				addSearchObj : function(searchContext,searchObj) {
					if(searchObj['id'] == 'new') {
						searchObj['search_pattern'] = {
							':columns':[],
							':filter':[],
							':order_by':[],
							':paging': {},
							':relation':searchObj['search_pattern'][':relation']
						};
					} else {
						searchObj['search_pattern'] = {
							':columns':searchObj['search_pattern'][':columns'],
							':filter':searchObj['search_pattern'][':filter'],
							':order_by':searchObj['search_pattern'][':order_by'],
							':paging':searchObj['search_pattern'][':paging'],
							':relation':searchObj['search_pattern'][':relation']
						};
					}
					this.searchObjList[searchContext]['searches'][searchObj['id']] = searchObj;
				},

				runSavedSearch : function(searchContext,searchId) {
					YUI().use("json", function(Y) {
						var searchObjJsonStr = Y.JSON.stringify(R8.Search.searchObjList[searchContext]['searches'][searchId]);
						var ssObjElem = document.getElementById(searchContext+'-saved-search-obj');
						ssObjElem.value = searchObjJsonStr;
						document.getElementById(searchContext+'-search-form').submit();
					});
				},

				runSearch : function(searchContext) {
					var currentSearch = R8.Search.searchObjList[searchContext]['currentSearch'];
					if(currentSearch == 'new') {
						R8.Search.searchObjList[searchContext]['searches'][currentSearch]['id'] = '';
					}
					var sNameElem = document.getElementById(searchContext+'-search_name');
					if(sNameElem.value == '') {
						alert('Saved searches must have a name');
						return;
					}
					R8.Search.searchObjList[searchContext]['searches'][currentSearch]['name'] = sNameElem.value;

					R8.Search.searchObjList[searchContext]['searches'][currentSearch]['search_pattern'][':columns'] = [];
					var displayColumns = document.getElementById(searchContext+'-display-columns');
					var numColumns = displayColumns.options.length;

					for(var i=0; i < numColumns; i++) {
						R8.Search.searchObjList[searchContext]['searches'][currentSearch]['search_pattern'][':columns'].push(':'+displayColumns.options[i].value);
					}
				
					YUI().use("json", function (Y) {
						var searchObjJsonStr = Y.JSON.stringify(R8.Search.searchObjList[searchContext]['searches'][currentSearch]);
						var ssObjElem = document.getElementById(searchContext+'-saved-search-obj');
						ssObjElem.value = searchObjJsonStr;
						document.getElementById(searchContext+'-search-form').submit();
					});
				},

				toggleSearchAttr : function(e) {
					var clickedAttr = e.currentTarget;
					var clickedAttrId = clickedAttr.get('id');
					var clickedAttrName = clickedAttrId.replace('-search-attr','');

					var parentNode = clickedAttr.get('parentNode');
					var attrList = parentNode.get('children');
					attrList.each(function() {
						if(this.get('id') != clickedAttrId) {
							this.removeClass('selected');

							var attrId = this.get('id');
							R8.Utils.Y.one('#'+attrId+'-body').setStyle('display','none');
							var attrName = attrId.replace('-search-attr','');
						}
					});
					clickedAttr.addClass('selected');
					R8.Utils.Y.one('#'+clickedAttrId+'-body').setStyle('display','block');
				},

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

				toggleSearch : function(searchContext) {
					var spElem = R8.Utils.Y.one('#'+searchContext+'-search-panel');
					var expandContractElem = R8.Utils.Y.one('#'+searchContext+'-expand-contract');

					if (spElem.getStyle('display') == 'none') {
						spElem.setStyle('display', 'block');
						expandContractElem.addClass('expanded');
					} else {
						spElem.setStyle('display', 'none');
						expandContractElem.removeClass('expanded');
					}
				},

				initSearchContext : function(searchContext,searchId) {
					this.searchObjList[searchContext]['currentSearch'] = searchId;
					var searchObj = this.searchObjList[searchContext]['searches'][searchId];

					var searchAttrs = R8.Utils.Y.one('#'+searchContext+'-search-attrs');
					var scatClick = R8.Utils.Y.delegate('click',R8.Search.toggleSearchAttr,searchAttrs,'.saved-search-cat');

					var filterList = R8.Utils.Y.one('#'+searchContext+'-filter-list');
					var filterClick = R8.Utils.Y.delegate('click',R8.Search.loadFilter,filterList,'.search-filter');

				//TODO: change search-filter class to search-ordering
					var orderingList = R8.Utils.Y.one('#'+searchContext+'-ordering-list');
					var orderingClick = R8.Utils.Y.delegate('click',R8.Search.loadOrdering,orderingList,'.search-filter');

					this.setupColumnFields(searchContext);
					this.renderFilters(searchContext);
					this.renderOrderings(searchContext);

					var searchNameElem = document.getElementById(searchContext+'-search_name');
					searchNameElem.value = this.searchObjList[searchContext]['searches'][searchId]['display_name'];
				},

				//BEGIN FILTER RELATED CODE
				saveFilter : function(filterId) {
					var filterElem = R8.Utils.Y.one('#'+filterId);

					if(filterElem == null) {
						R8.Search.persistFilter(filterId);
					} else {
						R8.Search.persistFilter(filterId,true);
					}
				},

				persistFilter : function(filterId,updateFilter) {
					var idParts = filterId.split('-');
					var filterIndex = idParts[idParts.length-2];
					var searchContext = filterId.replace('-'+filterIndex+'-filter','');
					var currentSearch = this.searchObjList[searchContext]['currentSearch'];
					var searchObj = this.searchObjList[searchContext]['searches'][currentSearch];
					var modelName = searchObj['search_pattern'][':relation'];

					var fieldElem = R8.Utils.Y.one('#'+filterId+'-field');
//					var modelName = fieldElem.getAttribute('data-model');
					var fieldName = fieldElem.get('value');

					var fieldDef = R8.Model.getFieldDef(modelName,fieldName);
					var fieldLabel = fieldDef['i18n'];

					var fieldOpElem = R8.Utils.Y.one('#'+filterId+'-operator');
					var fieldOperator = R8.Search.availOperators[fieldDef['type']][fieldOpElem.get('value')];

					var fieldCondElem = R8.Utils.Y.one('#'+filterId+'-condition');

					switch(fieldDef['type']) {
						case "boolean":
							var fieldCondition = (fieldCondElem.get('checked') == true) ? fieldCondElem.get('value') : '0';
							break;
						default:
							var fieldCondition = fieldCondElem.get('value');
							break;
					}
				
					var filterDef = [":"+fieldOpElem.get('value'),":"+fieldName];
				
					switch(fieldOpElem.get('value')) {
						case "oneof":
							var valueList = [];
							fieldCondElem.get('options').each(function(){
								if(this.get('selected') == true) {
									valueList[valueList.length] = this.get('value');
								}
							});
							filterDef.push(valueList);
							break;
						case "eq":
						case "match-prefix":
						case "contains":
							filterDef.push(fieldCondition);
							break;
						default:
							filterDef.push(fieldCondition);
							break;
					}

					var filter = searchObj['search_pattern'][':filter'];
					var filterLength = filter.length;

					if(typeof(updateFilter) == 'undefined' || updateFilter == false) {
						R8.Search.pushFilters(searchContext,[filterDef]);
						var newIndex = (filterLength <=0) ? 0 : filterLength-1;
//						R8.Search.renderFilterDisplay(searchContext,filterDef,filterLength-1,false);
						R8.Search.renderFilterDisplay(searchContext,filterDef,newIndex,false);
					} else if(updateFilter == true) {
						R8.Search.updateExistingFilter(searchContext,filterDef,filterIndex);
						R8.Search.renderFilterDisplay(searchContext,filterDef,filterIndex,true);
					}
				},

				pushFilters : function(searchContext,filterDefs) {
					var currentSearch = this.searchObjList[searchContext]['currentSearch'];
				
					if(this.searchObjList[searchContext]['searches'][currentSearch]['search_pattern'][':filter'].length == 0) {
						this.searchObjList[searchContext]['searches'][currentSearch]['search_pattern'][':filter'].push(":and");
					}
					for(filter in filterDefs) {
						this.searchObjList[searchContext]['searches'][currentSearch]['search_pattern'][':filter'].push(filterDefs[filter]);
					}
				},

				updateExistingFilter : function(searchContext,filterDef,filterIndex) {
					var currentSearch = this.searchObjList[searchContext]['currentSearch'];
					filterIndex++;
					this.searchObjList[searchContext]['searches'][currentSearch]['search_pattern'][':filter'][filterIndex] = filterDef;
				},

				loadFilter : function(e) {
					var filterId = e.currentTarget.get('id');
					var idParts = filterId.split('-');
					var filterIndex = idParts[idParts.length-2];
					var searchContext = filterId.replace('-'+filterIndex+'-filter','');
					var currentSearch = R8.Search.searchObjList[searchContext]['currentSearch'];
					var searchObj = R8.Search.searchObjList[searchContext]['searches'][currentSearch];

					var filterEditWrapper = R8.Utils.Y.one('#'+searchContext+'-filter-edit-wrapper');
					filterEditWrapper.set('innerHTML','');

					var filterList = R8.Utils.Y.one('#'+searchContext+'-filter-list');
					var modelName = searchObj['search_pattern'][':relation'];
					filterIndex++;
					filterDef = searchObj['search_pattern'][':filter'][filterIndex];
					var fieldName = filterDef[1].replace(':','');

					R8.Search.renderFilterEdit(searchContext,filterDef,filterId);
				},

				renderFilters : function(searchContext) {
					var currentSearch = this.searchObjList[searchContext]['currentSearch'];
					var searchObj = this.searchObjList[searchContext]['searches'][currentSearch];
					var filter = searchObj['search_pattern'][':filter'];

					var filterLength = filter.length;
					for(var i=1; i < filterLength; i++) {
						this.renderFilterDisplay(searchContext,filter[i],i-1,false);
					}
				},

				renderFilterDisplay : function(searchContext,filterDef,filterIndex,updateFilter) {
					var filterId = searchContext+'-'+filterIndex+'-filter';
					var currentSearch = this.searchObjList[searchContext]['currentSearch'];
					var searchObj = this.searchObjList[searchContext]['searches'][currentSearch];
					var modelName = searchObj['search_pattern'][':relation'];
					var fieldName = filterDef[1].replace(':','');
					var fieldDef = R8.Model.getFieldDef(modelName,fieldName);
					var fieldLabel = fieldDef['i18n'];
					var fieldOperator = this.availOperators[fieldDef['type']][filterDef[0].replace(':','')];
					var fieldCondition = filterDef[2];

					switch(filterDef[0].replace(':','')) {
						case "oneof":
							var optionsList = R8.Model.getFieldOptions(modelName,fieldName);
							var newCondition = '';
							for(index in fieldCondition) {
								(newCondition !='') ? newCondition = newCondition+',' : null;
								newCondition = newCondition + optionsList[fieldCondition[index]];
							}
							fieldCondition = newCondition;
							break;
						case "eq":
						case "match-prefix":
						case "contains":
							var optionsList = R8.Model.getFieldOptions(modelName,fieldName);
							if(fieldDef['type'] == 'select') {
								fieldCondition = "'"+optionsList[fieldCondition]+"'";
							} else if(fieldDef['type'] == 'boolean') {
								fieldCondition = (filterDef[2] == '1') ? 'Checked' : 'Unchecked';
							} else {
								fieldCondition = "'"+fieldCondition+"'";
							}
							break;
						default:
							break;
					}
					var filterStr = fieldLabel+' '+fieldOperator+' '+fieldCondition;

					if(typeof(updateFilter) == 'undefined' || updateFilter == false) {
						var filterElem = document.createElement('div');
//						filterElem.setAttribute('id',searchContext+'-'+filterId);
						filterElem.setAttribute('id',filterId);
						filterElem.setAttribute('class','search-filter');
						filterElem.innerHTML = '\
							<div class="search-filter-value">'+filterStr+'</div>\
							<div class="search-remove-filter"></div>\
						';

						var filterListElem = R8.Utils.Y.one('#'+searchContext+'-filter-list');
						filterListElem.appendChild(filterElem);
					} else if(updateFilter == true) {
//						var filterElem = R8.Utils.Y.one('#'+searchContext+'-'+filterId);
						var filterElem = R8.Utils.Y.one('#'+filterId);
						filterElem.get('children').item(0).set('innerHTML',filterStr);
					}
				},

				renderFilterEdit : function(searchContext,filterDef,filterId) {
					var searchId = R8.Search.searchObjList[searchContext]['currentSearch'];
					var searchObj = R8.Search.searchObjList[searchContext]['searches'][searchId];
					var modelName = searchObj['search_pattern'][':relation'];

					if(typeof(filterId) == 'undefined') {
						var filterIndex = searchObj['search_pattern'][':filter'].length - 1;
						filterIndex = (filterIndex < 0) ? 0 : filterIndex;
						filterId = searchContext + '-' + filterIndex + '-filter';
					}

					var filterEditWrapper = R8.Utils.Y.one('#'+searchContext+'-filter-edit-wrapper');
					filterEditWrapper.set('innerHTML','');

					(typeof(filterDef) !='undefined' && filterDef != null) ? fieldName = filterDef[1].replace(':','') : fieldName = null;

					var fieldElem = R8.Search.getFilterFieldOptions({
						'model_name':modelName,
						'field_name':fieldName,
						'filter_id':filterId
					});
					var fieldDef = R8.Model.getFieldDef(modelName,fieldElem.value);
					var elemId = fieldElem.getAttribute('id');
					var filterId = elemId.replace('-field','');

					var filterWrapper = document.createElement('div');
					filterWrapper.setAttribute('id',filterId+'-filter-wrapper');
					filterWrapper.setAttribute('style','float:left; width: 100%; height: 80px;');
				
					//add field select list
					filterWrapper.appendChild(fieldElem);
				
				
					//add field operator select list
					(typeof(filterDef) !='undefined' && filterDef != null) ? operator = filterDef[0].replace(':','') : operator = null;

					var fieldOperatorsElem = R8.Search.getFilterOperatorOptions({
						'field_def':fieldDef,
						'operator':operator,
						'filter_id':filterId
					});
					filterWrapper.appendChild(fieldOperatorsElem);

					(typeof(filterDef) =='undefined' || filterDef == null) ? filterDef = null : null;

					//add field condition input
					var fieldConditionElem = R8.Search.getConditionInput({
						'field_name':fieldElem.value,
						'field_def':fieldDef,
						'operator':fieldOperatorsElem.value,
						'filter_def':filterDef,
						'filter_id':filterId,
						'model_name':modelName
					});
					filterWrapper.appendChild(fieldConditionElem);

					filterEditWrapper.appendChild(filterWrapper);

					//add save button
					var saveBtnElem = R8.Search.getFilterSaveBtn(searchContext,filterId);
					filterEditWrapper.appendChild(saveBtnElem);
				},

				getFilterFieldOptions : function(params) {
					var modelName = params['model_name'];
					var fieldName = params['field_name'];
					var filterId = params['filter_id'];

					filterId = (typeof(filterId) == 'undefined' || filterId == null) ? R8.Utils.Y.guid() : filterId;
					var availFieldsElem = document.createElement('select');
					availFieldsElem.setAttribute('id',filterId+'-field');
					availFieldsElem.setAttribute('name',filterId+'-field');
					availFieldsElem.setAttribute('data-model',modelName);
					availFieldsElem.setAttribute('style','vertical-align:top;');

					availFieldsElem.onchange = function(){
						R8.Search.updateFilterField(this.id,this.options[this.selectedIndex].value);
					};

					var fieldDefs = R8.Model.getFieldDefs(modelName);
					for(field in fieldDefs) {
						var selected = ((fieldName != null && typeof(fieldName) != 'undefined') && fieldName == field) ? true : false;
						var numOptions = availFieldsElem.options.length;
						availFieldsElem.options[numOptions] = new Option(fieldDefs[field]['i18n'],field,false,selected);
					}
					return availFieldsElem;
				},

				getFilterOperatorOptions : function(params) {
					var fieldDef = params['field_def'];
					var operator = params['operator'];
					var filterId = params['filter_id'];

					if (fieldDef['type'] != 'boolean') {
						var availOperators = this.availOperators[fieldDef['type']];
						var availOpsElem = document.createElement('select');
						availOpsElem.setAttribute('id', filterId + '-operator');
						availOpsElem.setAttribute('name', filterId + '-operator');
						availOpsElem.setAttribute('style', 'vertical-align:top;');
						
						availOpsElem.onchange = function(){
							R8.Search.updateFilterOperator(this.id);
						};
						
						for (op in availOperators) {
							var selected = ((operator != null && typeof(operator) != 'undefined') && operator == op) ? true : false;
							var numOptions = availOpsElem.options.length;
							availOpsElem.options[numOptions] = new Option(availOperators[op], op, false, selected);
						}
					} else {
						var availOpsElem = document.createElement('input');
						availOpsElem.setAttribute('id', filterId + '-operator');
						availOpsElem.setAttribute('name', filterId + '-operator');
						availOpsElem.setAttribute('type', 'hidden');
						availOpsElem.setAttribute('value', operator);
					}
					return availOpsElem;
				},

				updateFilterOperator : function(operatorId) {
					var operatorElem = R8.Utils.Y.one('#'+operatorId);
					var filterId = operatorElem.get('id').replace('-operator','');
					var filterField = R8.Utils.Y.one('#'+filterId+'-field');
					var modelName = filterField.getAttribute('data-model');
					var fieldName = filterField.get('value');
					var fieldDef = R8.Model.getFieldDef(modelName,fieldName);
				
					var operator = operatorElem.get('options').item(operatorElem.get('selectedIndex')).get('value');
				
					//reset and update the condition field
					R8.Search.updateFilterCondition({
						'model_name':modelName,
						'field_name':fieldName,
						'operator':operator,
						'filter_id':filterId
					});
				},
/*
				updateFilterCondition : function(params) {
					var filterId = params['filter_id'];
					var modelName = params['model_name'];
					var fieldName = params['field_name'];
					var operator = params['operator'];

					var filterWrapper = document.getElementById(filterId+'-filter-wrapper');
					var conditionElem = document.getElementById(filterId+'-condition');
					filterWrapper.removeChild(conditionElem);
				
					var fieldDef = R8.Model.getFieldDef(modelName,fieldName);

//					if(fieldDef['type'] == 'boolean') return;

					var inputElem = R8.Search.getConditionInput({
						'field_name':fieldName,
						'field_def':fieldDef,
						'operator':operator,
						'filter_id':filterId
					});
				
					filterWrapper.appendChild(inputElem);
				},
*/
				getConditionInput : function(params) {
					var fieldName = params['field_name'];
					var fieldDef = params['field_def'];
					var operator = params['operator'];
					var filterId = params['filter_id'];
					var filterDef = params['filter_def'];
					var modelName = params['model_name'];

					switch(fieldDef['type']) {
						case "text":
							var inputElem = document.createElement('input');
							inputElem.setAttribute('id',filterId+'-condition');
							inputElem.setAttribute('name',filterId+'-condition');
							inputElem.setAttribute('type','text');
							inputElem.setAttribute('size','25');

							(filterDef != null && typeof(filterDef) !='undefined') ? inputElem.value = filterDef[2] : null;
							break;
						case "multiselect":
						case "select":
							var multiselect = false;
							if(operator == 'oneof') {
								multiselect = true;
							}
							var inputElem = document.createElement('select');
							inputElem.setAttribute('id',filterId+'-condition');
							inputElem.setAttribute('name',filterId+'-condition');
							(multiselect == true) ? inputElem.setAttribute('multiple','1') : null;

							var availOptions = R8.Model.getFieldOptions(modelName,fieldName);
							for(option in availOptions) {
								var numOptions = inputElem.options.length;

								var selected = false;

								if(typeof(filterDef) !='undefined' && filterDef !=null) {
									if(filterDef[2] instanceof Array) {
										(R8.Utils.in_array(filterDef[2],option)) ? selected = true : selected = false;
									} else {
										(filterDef[2] == option) ? selected = true : selected = false;
									}
								}
								inputElem.options[numOptions] = new Option(availOptions[option],option,false,selected);
							}
							break;
						case "numeric":
						case "integer":
							var inputElem = document.createElement('input');
							inputElem.setAttribute('id',filterId+'-condition');
							inputElem.setAttribute('name',filterId+'-condition');
							inputElem.setAttribute('type','text');
							inputElem.setAttribute('size','25');

							(filterDef != null && typeof(filterDef) !='undefined') ? inputElem.value = filterDef[2] : null;
							break;
						case "boolean":
							var inputElem = document.createElement('input');
							inputElem.setAttribute('id',filterId+'-condition');
							inputElem.setAttribute('name',filterId+'-condition');
							inputElem.setAttribute('type','checkbox');
							inputElem.setAttribute('value','1');

							if(filterDef != null && typeof(filterDef) != 'undefined') {
								(filterDef[2] == 1) ? inputElem.checked=true: inputElem.checked=false;
							}
							break;
					}
					return inputElem;
				},

				getFilterSaveBtn : function(searchContext,filterId) {
					var btnWrapper = document.createElement('div');
					btnWrapper.setAttribute('style','bottom: 0px; margin-left: 5px;');
				
					var btnElem = document.createElement('input');
					btnElem.setAttribute('type','button');
				//TODO: i18n this garb
					btnElem.value = 'Save';
					btnElem.onclick = function() {
						R8.Search.saveFilter(filterId);
						var filterEditWrapper = R8.Utils.Y.one('#'+searchContext+'-filter-edit-wrapper');
						filterEditWrapper.set('innerHTML','');
					}

					var cancelBtnElem = document.createElement('input');
					cancelBtnElem.setAttribute('type','button');
				//TODO: i18n this garb
					cancelBtnElem.value = 'Cancel';
					cancelBtnElem.onclick = function() {
						var filterEditWrapper = R8.Utils.Y.one('#'+searchContext+'-filter-edit-wrapper');
						filterEditWrapper.set('innerHTML','');
					}

					btnWrapper.appendChild(btnElem);
					btnWrapper.appendChild(cancelBtnElem);
					return btnWrapper;
				},

				updateFilterField : function(fieldId,fieldName) {
					var filterId = fieldId.replace('-field','');
					var fieldElem = R8.Utils.Y.one('#'+filterId+'-field');
					var modelName = fieldElem.getAttribute('data-model');
					var fieldDef = R8.Model.getFieldDef(modelName,fieldName);
					var operatorElem = document.getElementById(filterId+'-operator');

					//reset and update the condition field
					if(fieldDef['type'] != 'boolean') {
						if (operatorElem.nodeName.toLowerCase() == 'input') {
							var filterConditionElem = document.getElementById(filterId + '-condition');
							var filterWrapper = document.getElementById(filterId + '-filter-wrapper');
							filterWrapper.removeChild(operatorElem);
							var operatorElem = document.createElement('select');
							operatorElem.setAttribute('id', filterId + '-operator');
							operatorElem.setAttribute('name', filterId + '-operator');
							filterWrapper.insertBefore(operatorElem, filterConditionElem);
						}
						var possibleOperators = this.availOperators[fieldDef['type']];
						var operatorSelect = document.getElementById(filterId+'-operator');
						operatorElem.options.length = 0;
//TODO: remove
//						operatorSelect.setAttribute('data-field',fieldName);
	
						for(operator in possibleOperators) {
							var numOptions = operatorElem.options.length;
							var defaultSelected = (numOptions == 0) ? true : false;
							operatorElem.options[numOptions] = new Option(possibleOperators[operator],operator,defaultSelected,false);
						}

						R8.Search.updateFilterCondition({
							'model_name': modelName,
							'field_name': fieldName,
							'operator': operatorElem.options[operatorSelect.selectedIndex].value,
							'filter_id': filterId
						});
					} else {
						var filterConditionElem = document.getElementById(filterId+'-condition');
						var filterWrapper = document.getElementById(filterId+'-filter-wrapper');
						filterWrapper.removeChild(operatorElem);
						var operatorElem = document.createElement('input');
						operatorElem.setAttribute('id',filterId+'-operator');
						operatorElem.setAttribute('name',filterId+'-operator');
						operatorElem.setAttribute('type','hidden');
						operatorElem.setAttribute('value','eq');
						filterWrapper.insertBefore(operatorElem,filterConditionElem);

						R8.Search.updateFilterCondition({
							'model_name': modelName,
							'field_name': fieldName,
							'operator': 'eq',
							'filter_id': filterId
						});
					}
				},

				updateFilterCondition : function(params) {
					var filterId = params['filter_id'];
					var modelName = params['model_name'];
					var fieldName = params['field_name'];
					var operator = params['operator'];

					var filterWrapper = document.getElementById(filterId+'-filter-wrapper');
					var conditionElem = document.getElementById(filterId+'-condition');
					filterWrapper.removeChild(conditionElem);

					var fieldDef = R8.Model.getFieldDef(modelName,fieldName);
					var inputElem = R8.Search.getConditionInput({
						'field_name':fieldName,
						'field_def':fieldDef,
						'operator':operator,
						'filter_id':filterId,
						'model_name':modelName
					});

					filterWrapper.appendChild(inputElem);
				},

				//END FILTER CODE

			//ORDERING RELATED
				renderOrderings : function(searchContext) {
					var currentSearch = this.searchObjList[searchContext]['currentSearch'];
					var searchObj = this.searchObjList[searchContext]['searches'][currentSearch];
					var orderings = searchObj['search_pattern'][':order_by'];

					var index = 0;
					for(order_by in orderings) {
						this.renderOrderingDisplay(searchContext,orderings[order_by],index,false);
						index++;
					}
				},

				renderOrderingDisplay : function(searchContext,orderDef,orderIndex,updateOrdering) {
					var searchInfo = R8.Search.getSearchInfo(searchContext);
					var fieldDef = R8.Model.getFieldDef(searchInfo['modelName'],orderDef['field']);
					var fieldLabel = fieldDef['i18n'];
					var ordering = orderDef['order'];
//TODO: i18n the strings
					var orderStr = 'Order By '+fieldLabel+' '+ordering;
					var orderId = searchContext+'-'+orderIndex+'-ordering';
					if(typeof(updateOrdering) == 'undefined' || updateOrdering == false) {
						var orderElem = document.createElement('div');
						orderElem.setAttribute('id',orderId);
						orderElem.setAttribute('class','search-filter');
						orderElem.innerHTML = '\
							<div class="search-filter-value">'+orderStr+'</div>\
							<div class="search-remove-filter"></div>\
						';
					
						var orderingListElem = R8.Utils.Y.one('#'+searchContext+'-ordering-list');
						orderingListElem.appendChild(orderElem);
					} else if(updateOrdering == true) {
						var orderElem = R8.Utils.Y.one('#'+orderId);
						orderElem.get('children').item(0).set('innerHTML',orderStr);
					}
				},

				renderOrderingEdit : function(searchContext,orderDef,orderId) {
					var searchInfo = R8.Search.getSearchInfo(searchContext);

					if(typeof(orderId) == 'undefined') {
						var orderIndex = (searchInfo['searchObj']['search_pattern'][':order_by'].length <=0) ? 
							0 : searchInfo['searchObj']['search_pattern'][':order_by'].length;
						orderId = searchContext + '-' + orderIndex + '-ordering';
					}

					var orderingEditWrapper = R8.Utils.Y.one('#'+searchContext+'-ordering-edit-wrapper');
					orderingEditWrapper.set('innerHTML','');

					(typeof(orderDef) !='undefined') ? fieldName = orderDef[':field'] : fieldName = null;

					var fieldElem = R8.Search.getOrderingFieldOptions({
						'model_name':searchInfo['modelName'],
						'field_name':fieldName,
						'order_id':orderId
					});
					var fieldDef = R8.Model.getFieldDef(searchInfo['modelName'],fieldElem.value);
					var elemId = fieldElem.getAttribute('id');
					var orderId = elemId.replace('-field','');
				
					var orderingWrapper = document.createElement('div');
					orderingWrapper.setAttribute('id',orderId+'-ordering-wrapper');
					orderingWrapper.setAttribute('style','float:left; width: 100%; height: 80px;');

					//add field select list
					orderingWrapper.appendChild(fieldElem);

					var orderingElem = document.createElement('select');
					orderingElem.setAttribute('id',orderId+'-order');
					orderingElem.setAttribute('name',orderId+'-order');
					orderingElem.setAttribute('data-model',searchInfo['modelName']);
					orderingElem.setAttribute('style','vertical-align:top;');

					var ascSelected = (typeof(orderDef) !='undefined' && orderDef[':order'] == 'ASC') ? true : false;
					var descSelected = (typeof(orderDef) !='undefined' && orderDef[':order'] == 'DESC') ? true : false;

					orderingElem.options[0] = new Option('ASC','ASC',false,ascSelected);
					orderingElem.options[1] = new Option('DESC','DESC',false,descSelected);

					//add ordering options
					orderingWrapper.appendChild(orderingElem);

					var orderingEditWrapper = R8.Utils.Y.one('#'+searchContext+'-ordering-edit-wrapper');
					orderingEditWrapper.appendChild(orderingWrapper);

					//add save button
					var saveBtnElem = R8.Search.getOrderingSaveBtn(searchContext,orderId);
					orderingEditWrapper.appendChild(saveBtnElem);
				},

				getOrderingFieldOptions: function(params) {
					var modelName = params['model_name'];
					var fieldName = params['field_name'];
					var orderId = params['order_id'];

					orderId = (typeof(orderId) == 'undefined' || orderId == null) ? R8.Utils.Y.guid() : orderId;
					var availFieldsElem = document.createElement('select');
					availFieldsElem.setAttribute('id',orderId+'-field');
					availFieldsElem.setAttribute('name',orderId+'-field');
					availFieldsElem.setAttribute('data-model',modelName);
					availFieldsElem.setAttribute('style','vertical-align:top;');

					availFieldsElem.onchange = function(){
						var orderId = this.getAttribute('id').replace('-field','');
						document.getElementById(orderId+'-order').selectedIndex = 0;
					};
				
					var fieldDefs = R8.Model.getFieldDefs(modelName);
					for(field in fieldDefs) {
						var selected = ((fieldName != null && typeof(fieldName) != 'undefined') && fieldName == field) ? true : false;
						var numOptions = availFieldsElem.options.length;
						availFieldsElem.options[numOptions] = new Option(fieldDefs[field]['i18n'],field,false,selected);
					}
					return availFieldsElem;
				},

				getOrderingSaveBtn : function(searchContext,orderId) {
					var btnWrapper = document.createElement('div');
					btnWrapper.setAttribute('style','bottom: 0px; margin-left: 5px;');
				
					var btnElem = document.createElement('input');
					btnElem.setAttribute('type','button');
				//TODO: i18n this garb
					btnElem.value = 'Save';
					btnElem.onclick = function() {
						R8.Search.saveOrdering(orderId);
						var orderingEditWrapper = R8.Utils.Y.one('#'+searchContext+'-ordering-edit-wrapper');
						orderingEditWrapper.set('innerHTML','');
					}

					var cancelBtnElem = document.createElement('input');
					cancelBtnElem.setAttribute('type','button');
				//TODO: i18n this garb
					cancelBtnElem.value = 'Cancel';
					cancelBtnElem.onclick = function() {
						var orderingEditWrapper = R8.Utils.Y.one('#'+searchContext+'-ordering-edit-wrapper');
						orderingEditWrapper.set('innerHTML','');
					}

					btnWrapper.appendChild(btnElem);
					btnWrapper.appendChild(cancelBtnElem);
					return btnWrapper;
				},

				saveOrdering: function(orderId) {
					var orderElem = R8.Utils.Y.one('#'+orderId);

					if(orderElem == null) {
						R8.Search.persistOrdering(orderId);
					} else {
						R8.Search.persistOrdering(orderId,true);
					}
				},

				persistOrdering: function(orderId,updateOrdering) {
					var idParts = orderId.split('-');
					var orderIndex = idParts[idParts.length-2];
					var searchContext = orderId.replace('-'+orderIndex+'-ordering','');
					var searchInfo = R8.Search.getSearchInfo(searchContext);

					var fieldElem = R8.Utils.Y.one('#'+orderId+'-field');
					var fieldName = fieldElem.get('value');

					var fieldDef = R8.Model.getFieldDef(searchInfo['modelName'],fieldName);
					var fieldLabel = fieldDef['i18n'];

					var orderingElem = R8.Utils.Y.one('#'+orderId+'-order');
					var ordering = orderingElem.get('value');

					var orderDef = {":field":fieldName,":order":ordering};
					var orderStr = 'Order By '+fieldLabel+' '+ordering;

					if(typeof(updateOrdering) == 'undefined' || updateOrdering == false) {
						var orderElem = document.createElement('div');
						orderElem.setAttribute('id',orderId);
						orderElem.setAttribute('class','search-filter');
						orderElem.innerHTML = '\
							<div class="search-filter-value">'+orderStr+'</div>\
							<div class="search-remove-filter"></div>\
						';
					
						var orderingListElem = R8.Utils.Y.one('#'+searchContext+'-ordering-list');
						orderingListElem.appendChild(orderElem);

						R8.Search.pushOrderings(searchContext,[orderDef]);
					} else if(updateOrdering == true) {
						var orderElem = R8.Utils.Y.one('#'+orderId);
						orderElem.get('children').item(0).set('innerHTML',orderStr);

						this.updateExistingOrdering(searchContext,orderIndex,orderDef);
					}
				},

				updateExistingOrdering: function(searchContext,orderIndex,orderDef) {
					var currentSearch = R8.Search.searchObjList[searchContext]['currentSearch'];
					R8.Search.searchObjList[searchContext]['searches'][currentSearch]['search_pattern'][':order_by'][orderIndex] = orderDef;
				},

				//TODO: remove devTestSearchObj stub
				pushOrderings: function(searchContext,orderingDefs) {
					var currentSearch = R8.Search.searchObjList[searchContext]['currentSearch'];
					for(order in orderingDefs) {
						R8.Search.searchObjList[searchContext]['searches'][currentSearch]['search_pattern'][':order_by'].push(orderingDefs[order]);
					}
				},

				loadOrdering: function(e) {
					var orderId = e.currentTarget.get('id');
					var idParts = orderId.split('-');
					var orderIndex = idParts[idParts.length-2];
					var searchContext = orderId.replace('-'+orderIndex+'-ordering','');
					var currentSearch = R8.Search.searchObjList[searchContext]['currentSearch'];
					var searchObj = R8.Search.searchObjList[searchContext]['searches'][currentSearch];
					var orderingEditWrapper = R8.Utils.Y.one('#'+searchContext+'-ordering-edit-wrapper');
					orderingEditWrapper.set('innerHTML','');

					orderDef = searchObj['search_pattern'][':order_by'][orderIndex];
					R8.Search.renderOrderingEdit(searchContext,orderDef,orderId);
				},
			//COLUMN RELATED

				setupColumnFields : function(searchContext) {
					var searchId = this.searchObjList[searchContext]['currentSearch'];
					if(searchId =='new') {
						var columns = this.searchObjList[searchContext]['searches'][searchId]['search_pattern'][':columns'] = [];						
					} else {
						var columns = this.searchObjList[searchContext]['searches'][searchId]['search_pattern'][':columns'];
					}
					var searchObj = this.searchObjList[searchContext]['searches'][searchId];
					var modelName = searchObj['search_pattern'][':relation'].replace(':','');
//TODO: why are new search objects passed with no : while existing ones have it?
//					var modelName = searchObj['search_pattern'][':relation'];
					var fieldDefs = R8.Model.getFieldDefs(modelName);
					var availFieldsElem = document.getElementById(searchContext+'-avail-columns');
					var displayFieldsElem = document.getElementById(searchContext+'-display-columns');
					var displayColumns = [];

					for(field in fieldDefs) {
						if (columns != null && R8.Utils.in_array(columns, field)) {
							displayColumns.push(field);
							displayFieldsElem.options[displayFieldsElem.options.length] = new Option(fieldDefs[field]['i18n'], field, false, false);
						} else {
							availFieldsElem.options[availFieldsElem.options.length] = new Option(fieldDefs[field]['i18n'], field, false, false);
						}
					}

					var mvLeftElem = R8.Utils.Y.one('#'+searchContext+'-columns-mv-left');
					var mvLeftEvnt = mvLeftElem.on('click',function(e,searchContext){
						var selectedOptions = [];
						var remainingOptions = [];
						var availFieldsElem = document.getElementById(searchContext+'-avail-columns');
						var numOptions = availFieldsElem.options.length;
						for(var i=0; i < numOptions; i++) {
							if(availFieldsElem.options[i].selected == true) {
								selectedOptions[selectedOptions.length] = {'display':availFieldsElem.options[i].innerHTML,'value':availFieldsElem.options[i].value};
							} else {
								remainingOptions[remainingOptions.length] = {'display':availFieldsElem.options[i].innerHTML,'value':availFieldsElem.options[i].value};
							}
						}
						availFieldsElem.options.length = 0;
						for(option in remainingOptions) {
							availFieldsElem.options[availFieldsElem.options.length] = new Option(remainingOptions[option]['display'],remainingOptions[option]['value'],false,false);
						}

						var displayFieldsElem = document.getElementById(searchContext+'-display-columns');
						for(option in selectedOptions) {
							displayFieldsElem.options[displayFieldsElem.options.length] = new Option(selectedOptions[option]['display'],selectedOptions[option]['value'],false,false);
						}
					},this,searchContext);

					var mvRightElem = R8.Utils.Y.one('#'+searchContext+'-columns-mv-right');
					var mvRightEvnt = mvRightElem.on('click',function(e,searchContext){
						var selectedOptions = [];
						var remainingOptions = [];
						var displayFieldsElem = document.getElementById(searchContext+'-display-columns');
						var numOptions = displayFieldsElem.options.length;
						for(var i=0; i < numOptions; i++) {
							if(displayFieldsElem.options[i].selected == true) {
								selectedOptions[selectedOptions.length] = {'display':displayFieldsElem.options[i].innerHTML,'value':displayFieldsElem.options[i].value};
							} else {
								remainingOptions[remainingOptions.length] = {'display':displayFieldsElem.options[i].innerHTML,'value':displayFieldsElem.options[i].value};
							}
						}
						displayFieldsElem.options.length = 0;
						for(option in remainingOptions) {
							displayFieldsElem.options[displayFieldsElem.options.length] = new Option(remainingOptions[option]['display'],remainingOptions[option]['value'],false,false);
						}

						var availFieldsElem = document.getElementById(searchContext+'-avail-columns');
						for(option in selectedOptions) {
							availFieldsElem.options[availFieldsElem.options.length] = new Option(selectedOptions[option]['display'],selectedOptions[option]['value'],false,false);
						}
					},this,searchContext);

					var mvUpElem = R8.Utils.Y.one('#'+searchContext+'-columns-mv-up');
					var mvUpEvnt = mvUpElem.on('click',function(e,searchContext){
						var selectedOptions = [];
						var remainingOptions = [];
						var firstSelectedIndex = null;
						var displayFieldsElem = document.getElementById(searchContext+'-display-columns');
						var numOptions = displayFieldsElem.options.length;
						for(var i=0; i < numOptions; i++) {
							if(displayFieldsElem.options[i].selected == true) {
								if(firstSelectedIndex == null) firstSelectedIndex = i;
								selectedOptions[selectedOptions.length] = {'display':displayFieldsElem.options[i].innerHTML,'value':displayFieldsElem.options[i].value,'index':i};
							} else {
								remainingOptions[remainingOptions.length] = {'display':displayFieldsElem.options[i].innerHTML,'value':displayFieldsElem.options[i].value,'index':i};
							}
						}

						displayFieldsElem.options.length = 0;
						var placedNewOrder = false;
						for(option in remainingOptions) {
							if(remainingOptions[option]['index'] >= (firstSelectedIndex-1) && placedNewOrder == false) {
								for(sOption in selectedOptions) {
									displayFieldsElem.options[displayFieldsElem.options.length] = new Option(selectedOptions[sOption]['display'], selectedOptions[sOption]['value'], false, false);
								}
								placedNewOrder = true;
								selectedOptions = null;
							}
							displayFieldsElem.options[displayFieldsElem.options.length] = new Option(remainingOptions[option]['display'], remainingOptions[option]['value'], false, false);
						}
						if(selectedOptions != null) {
							for(sOption in selectedOptions) {
								displayFieldsElem.options[displayFieldsElem.options.length] = new Option(selectedOptions[sOption]['display'], selectedOptions[sOption]['value'], false, false);
							}
						}
					},this,searchContext);

					var mvDownElem = R8.Utils.Y.one('#'+searchContext+'-columns-mv-down');
					var mvDownEvnt = mvDownElem.on('click',function(e,searchContext){
						var selectedOptions = [];
						var remainingOptions = [];
						var lastSelectedIndex = null;
						var displayFieldsElem = document.getElementById(searchContext+'-display-columns');
						var numOptions = displayFieldsElem.options.length;
						for(var i=0; i < numOptions; i++) {
							if(displayFieldsElem.options[i].selected == true) {
								lastSelectedIndex = i;
								selectedOptions[selectedOptions.length] = {'display':displayFieldsElem.options[i].innerHTML,'value':displayFieldsElem.options[i].value,'index':i};
							} else {
								remainingOptions[remainingOptions.length] = {'display':displayFieldsElem.options[i].innerHTML,'value':displayFieldsElem.options[i].value,'index':i};
							}
						}

						displayFieldsElem.options.length = 0;
						var placedNewOrder = false;
						for(option in remainingOptions) {
							if(remainingOptions[option]['index'] > (lastSelectedIndex+1) && placedNewOrder == false) {
								for(sOption in selectedOptions) {
									displayFieldsElem.options[displayFieldsElem.options.length] = new Option(selectedOptions[sOption]['display'], selectedOptions[sOption]['value'], false, false);
								}
								placedNewOrder = true;
								selectedOptions = null;
							}
							displayFieldsElem.options[displayFieldsElem.options.length] = new Option(remainingOptions[option]['display'], remainingOptions[option]['value'], false, false);
						}
						if(selectedOptions != null) {
							for(sOption in selectedOptions) {
								displayFieldsElem.options[displayFieldsElem.options.length] = new Option(selectedOptions[sOption]['display'], selectedOptions[sOption]['value'], false, false);
							}
						}
					},this,searchContext);
				},

				availOperators : {
					'text' : {
						'match-prefix' : 'Starts With',
						'eq':'Equals',
						'contains':'Contains',
						'regex':'Matches Regex'
					},
					'integer' : {
						'eq':'==',
						'lt':'<',
						'gt':'>',
						'lte':'<=',
						'gte':'>=',
						'ne':'!='
					},
					'numeric' : {
						'eq':'==',
						'lt':'<',
						'gt':'>',
						'lte':'<=',
						'gte':'>=',
						'ne':'!='
					},
					'select' : {
						'eq':'Equals',
						'oneof':'Is One Of'
					},
					'multiselect' : {
						'eq':'Equals',
						'oneof':'Is One Of'
					},
					'boolean' : {
						'eq':'Equals',
					},
				}

			}
		}();
	})(R8);
}
