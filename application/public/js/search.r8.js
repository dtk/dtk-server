if (!R8.Search) {

	(function(R8) {
		R8.Search = function() {
			return {
				searchObjList : {},

				setSearchObj : function(searchObj) {
					this.searchObjList[searchObj['id']] = searchObj;
				},

				runSavedSearch : function(searchId) {
					YUI().use("json", function (Y) {
						var searchObjJsonStr = Y.JSON.stringify(R8.Search.searchObjList[searchId]);
						var ssObjElem = document.getElementById('saved-search-obj');
						ssObjElem.value = searchObjJsonStr;
						document.getElementById('saved-search-form').submit();
					});
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
				
				toggleSearch : function(modelName) {
					var spElem = R8.Utils.Y.one('#'+modelName+'-search-panel');

					(spElem.getStyle('display') == 'none') ? spElem.setStyle('display','block') : spElem.setStyle('display','none');
				},

			//ORDERING RELATED
				renderOrderingEdit : function(modelName,orderId,orderDef) {
					var orderingEditWrapper = R8.Utils.Y.one('#tempId-ordering-edit-wrapper');
					orderingEditWrapper.set('innerHTML','');
				
					(typeof(orderDef) !='undefined') ? fieldName = orderDef[':field'] : fieldName = null;
				
					var fieldElem = this.getOrderingFieldOptions({
						'model_name':modelName,
						'field_name':fieldName,
						'order_id':orderId
					});
					var fieldDef = getFieldDef(modelName,fieldElem.value);
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
					orderingElem.setAttribute('data-model',modelName);
					orderingElem.setAttribute('style','vertical-align:top;');

					var ascSelected = (typeof(orderDef) !='undefined' && orderDef[':order'] == 'ASC') ? true : false;
					var descSelected = (typeof(orderDef) !='undefined' && orderDef[':order'] == 'DESC') ? true : false;

					orderingElem.options[0] = new Option('ASC','ASC',false,ascSelected);
					orderingElem.options[1] = new Option('DESC','DESC',false,descSelected);

					//add ordering options
					orderingWrapper.appendChild(orderingElem);

					var orderingEditWrapper = R8.Utils.Y.one('#tempId-ordering-edit-wrapper');
					orderingEditWrapper.appendChild(orderingWrapper);

					//add save button
					var saveBtnElem = this.getOrderingSaveBtn(orderId);
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
				
					var fieldDefs = getModelFieldDefs(modelName);
					for(field in fieldDefs) {
						var selected = ((fieldName != null && typeof(fieldName) != 'undefined') && fieldName == field) ? true : false;
						var numOptions = availFieldsElem.options.length;
						availFieldsElem.options[numOptions] = new Option(fieldDefs[field]['i18n'],field,false,selected);
					}
					return availFieldsElem;
				},

				getOrderingSaveBtn: function(orderId) {
					var tempId = 'tempId-ordering-edit-wrapper';

					var btnWrapper = document.createElement('div');
					btnWrapper.setAttribute('style','bottom: 0px; margin-left: 5px;');

					var btnElem = document.createElement('input');
					btnElem.setAttribute('type','button');
					btnElem.setAttribute('data-order-id',orderId);

				//TODO: i18n this garb
					btnElem.value = 'Save';
					btnElem.onclick = function() {
						R8.Search.saveOrdering(this.getAttribute('data-order-id'));
						var orderingEditWrapper = R8.Utils.Y.one('#tempId-ordering-edit-wrapper');
						orderingEditWrapper.set('innerHTML','');
					}

					var cancelBtnElem = document.createElement('input');
					cancelBtnElem.setAttribute('type','button');
				//TODO: i18n this garb
					cancelBtnElem.value = 'Cancel';
					cancelBtnElem.onclick = function() {
						var orderingEditWrapper = R8.Utils.Y.one('#tempId-ordering-edit-wrapper');
						orderingEditWrapper.set('innerHTML','');
					}

					btnWrapper.appendChild(btnElem);
					btnWrapper.appendChild(cancelBtnElem);
					return btnWrapper;
				},

				saveOrdering: function(orderId) {
					var orderElem = R8.Utils.Y.one('#'+orderId);

					if(orderElem == null) {
						this.persistOrdering(orderId);
					} else {
						this.persistOrdering(orderId,true);
					}
				},

				persistOrdering: function(orderId,updateOrdering) {
					var fieldElem = R8.Utils.Y.one('#'+orderId+'-field');
					var modelName = fieldElem.getAttribute('data-model');
					var fieldName = fieldElem.get('value');

					var fieldDef = getFieldDef(modelName,fieldName);
					var fieldLabel = fieldDef['i18n'];

					var orderingElem = R8.Utils.Y.one('#'+orderId+'-order');
					var ordering = orderingElem.get('value');

					var orderDef = {":field":fieldName,":order":ordering};
					var orderStr = 'Order By '+fieldLabel+' '+ordering;
				/*
				<div id="filter0X" class="search-filter">
					<div class="search-filter-value">Display Name Equals 'foo'</div>
					<div class="search-remove-filter"></div>
				</div>
				*/
				
				//TODO: figure out best way to handle id's
				var searchId = 'foo';
				
					if(typeof(updateOrdering) == 'undefined' || updateOrdering == false) {
						var orderElem = document.createElement('div');
						orderElem.setAttribute('id',orderId);
						orderElem.setAttribute('class','search-filter');
						orderElem.innerHTML = '\
							<div class="search-filter-value">'+orderStr+'</div>\
							<div class="search-remove-filter"></div>\
						';
					
						var orderingListElem = R8.Utils.Y.one('#'+modelName+'-ordering-list');
						orderingListElem.appendChild(orderElem);

						this.pushOrderings(searchId,[orderDef]);
					} else if(updateOrdering == true) {
						var orderElem = R8.Utils.Y.one('#'+orderId);
						orderElem.get('children').item(0).set('innerHTML',orderStr);

//TODO: centralize this as a reusable function,change id on ordering list to be search Id driven
						var orderingList = R8.Utils.Y.one('#node-ordering-list');
						var orderingIndex = 0;
						var foundIndex = false;
						orderingList.get('children').each(function(){
							if(foundIndex != true) {
								if(this.get('id') == orderId) {
									foundIndex = true;
								} else {
									foundIndex = false;
									orderingIndex++;
								}
							}
						});
						this.updateExistingOrdering(searchId,orderingIndex,orderDef);
					}
				},

				updateExistingOrdering: function(searchId,orderingIndex,orderDef) {
					var searchDef = getSearchObj(searchId);
				//	searchDef['search_pattern'][':filter'][filterIndex+1] = filterDef;
					devTestSearchObj['search_pattern'][':order_by'][orderingIndex] = orderDef;
console.log(devTestSearchObj['search_pattern'][':order_by']);
				},

				//TODO: remove devTestSearchObj stub
				pushOrderings: function(searchId,orderingDefs) {
					var searchDef = getSearchObj(searchId);
				
					for(order in orderingDefs) {
						devTestSearchObj['search_pattern'][':order_by'].push(orderingDefs[order]);
					}
				},

				loadOrdering: function(e) {
					var orderId = e.currentTarget.get('id');
				//TODO: remove stub
				var searchId = 'foo';
					var searchObj = getSearchObj(searchId);
					var orderingEditWrapper = R8.Utils.Y.one('#tempId-ordering-edit-wrapper');
					orderingEditWrapper.set('innerHTML','');

//TODO: use search id instead of model name
					var orderingList = R8.Utils.Y.one('#node-ordering-list');
					var orderingIndex = 0;
					var foundIndex = false;
					orderingList.get('children').each(function(){
						if(foundIndex != true) {
							if(this.get('id') == orderId) {
								foundIndex = true;
							} else {
								foundIndex = false;
								orderingIndex++;
							}
						}
					});
					var modelName = searchObj['search_pattern'][':relation'];
					orderDef = searchObj['search_pattern'][':order_by'][orderingIndex];
					R8.Search.renderOrderingEdit(modelName,orderId,orderDef);
				},
			//COLUMN RELATED

				setupColumnFields : function(modelName,searchId) {
					var fieldDefs = getModelFieldDefs(modelName);
					var availFieldsElem = document.getElementById(modelName+'-avail-columns');

					for(field in fieldDefs) {
						availFieldsElem.options[availFieldsElem.options.length] = new Option(fieldDefs[field]['i18n'],field,false,false);
					}

					var mvLeftElem = R8.Utils.Y.one('#'+modelName+'-columns-mv-left');
					var mvLeftEvnt = mvLeftElem.on('click',function(e){
						var selectedOptions = [];
						var remainingOptions = [];
						var availFieldsElem = document.getElementById(modelName+'-avail-columns');
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

						var displayFieldsElem = document.getElementById(modelName+'-display-columns');
						for(option in selectedOptions) {
							displayFieldsElem.options[displayFieldsElem.options.length] = new Option(selectedOptions[option]['display'],selectedOptions[option]['value'],false,false);
						}
					});

					var mvRightElem = R8.Utils.Y.one('#'+modelName+'-columns-mv-right');
					var mvRightEvnt = mvRightElem.on('click',function(e){
						var selectedOptions = [];
						var remainingOptions = [];
						var displayFieldsElem = document.getElementById(modelName+'-display-columns');
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

						var availFieldsElem = document.getElementById(modelName+'-avail-columns');
						for(option in selectedOptions) {
							availFieldsElem.options[availFieldsElem.options.length] = new Option(selectedOptions[option]['display'],selectedOptions[option]['value'],false,false);
						}
					});

					var mvUpElem = R8.Utils.Y.one('#'+modelName+'-columns-mv-up');
					var mvUpEvnt = mvUpElem.on('click',function(e){
						var selectedOptions = [];
						var remainingOptions = [];
						var firstSelectedIndex = null;
						var displayFieldsElem = document.getElementById(modelName+'-display-columns');
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
					});

					var mvDownElem = R8.Utils.Y.one('#'+modelName+'-columns-mv-down');
					var mvDownEvnt = mvDownElem.on('click',function(e){
						var selectedOptions = [];
						var remainingOptions = [];
						var lastSelectedIndex = null;
						var displayFieldsElem = document.getElementById(modelName+'-display-columns');
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
					});

				},
			}
		}();
	})(R8);
}
