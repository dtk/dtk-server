
if(!R8.Import) {

	R8.Import = function() {
		var _importDef=null,

			_pageContainerNode = null,
			_topbarNode = null,
			_mainBodyWrapperNode = null,
			_viewportRegion = null,
			_stepListNode = null,

			_currentWizardStep = 0,

			_panels = {},
			_events = {};

		return {
			init: function(import_def,step) {
				R8.UI.init();
				_importDef = import_def;

				this.setupImportDef();

				_pageContainerNode = R8.Utils.Y.one('#page-container');
				_mainBodyWrapperNode = R8.Utils.Y.one('#main-body-wrapper');
				_topbarNode = R8.Utils.Y.one('#page-topbar');


				var panelDef = {
					'id': 'main-panel',
					'tplName': 'workspace_panel',
					'type': 'default',
					'pClass': '',
					'minHeight': 100,
					'minWidth': 300,
					'heightMargin': 10,
					'widthMargin': 10
				};

				_panels['main'] = new R8.Workspace.panel(panelDef);
				_mainBodyWrapperNode.append(_panels['main'].render());
				_panels['main'].init();

				this.resizePage();

				R8.Utils.Y.one(window).on('resize',function(e) {
					this.resizePage();
				},this);

				var _wizardTabsHeader = '\
					<div id=""></div>\
				';
				_wizardContentTpl = '\
				<div id="wizard-frame">\
 					<ul id="wizard-step-list" class="step-list">\
						<li id="wizard-step-1" class="step-item active">Upload Module</li>\
						<li id="wizard-step-2" class="step-item">Integrity Check</li>\
						<li id="wizard-step-3" class="step-item">Select Components</li>\
						<li id="wizard-step-4" class="step-item">Setup Meta</li>\
						<li id="wizard-step-5" class="step-item">Import</li>\
					</ul>\
					<div id="wizard-content" class="wizard-content">\
					</div>\
				</div>\
				';

				_panels['main'].get('contentNode').append(_wizardContentTpl);

				_stepListNode = R8.Utils.Y.one('#wizard-step-list');

				switch(step) {
					case 1:
						break;
					case 2:
						this.loadStepTwo();
						break;
				}
			},
			loadWizard: function(step) {
				R8.UI.init();
//				_importDef = import_def;

//				this.setupImportDef();

				_pageContainerNode = R8.Utils.Y.one('#page-container');
				_mainBodyWrapperNode = R8.Utils.Y.one('#main-body-wrapper');
				_topbarNode = R8.Utils.Y.one('#page-topbar');


				var panelDef = {
					'id': 'main-panel',
					'tplName': 'workspace_panel',
					'type': 'default',
					'pClass': '',
					'minHeight': 100,
					'minWidth': 300,
					'heightMargin': 10,
					'widthMargin': 10
				};

				_panels['main'] = new R8.Workspace.panel(panelDef);
				_mainBodyWrapperNode.append(_panels['main'].render());
				_panels['main'].init();

				this.resizePage();

				R8.Utils.Y.one(window).on('resize',function(e) {
					this.resizePage();
				},this);

				var _wizardTabsHeader = '\
					<div id=""></div>\
				';
				_wizardContentTpl = '\
				<div id="wizard-frame">\
 					<ul id="wizard-step-list" class="step-list">\
						<li id="wizard-step-1" class="step-item active">Upload Module</li>\
						<li id="wizard-step-2" class="step-item">Select Components</li>\
						<li id="wizard-step-3" class="step-item">Setup Meta</li>\
						<li id="wizard-step-4" class="step-item">Import</li>\
					</ul>\
					<div id="wizard-content" class="wizard-content">\
					</div>\
				</div>\
				';

				_panels['main'].get('contentNode').append(_wizardContentTpl);

				_stepListNode = R8.Utils.Y.one('#wizard-step-list');

				switch(step) {
					case 1:
						this.loadStepOne();
						break;
					case 2:
						this.loadStepTwo();
						break;
					case 3:
						this.loadStepThree();
						break;
					case 4:
						this.loadStepFour();
						break;
					default:
						this.loadStepOne();
						break;
				}
			},
			setupImportDef: function() {
				if(typeof(_importDef.initialized) != 'undefined') return;

				for(var c in _importDef.components) {
					_importDef.components[c].selected = true;
				}
				_importDef.selectedComponents = [];
				this.updateSelectedComponents();
				_importDef.initialized = true;
			},
			resizePage: function() {
				_viewportRegion = _pageContainerNode.get('viewportRegion');

				var vportHeight = _viewportRegion['height'];
				var vportWidth = _viewportRegion['width'];

				var topbarRegion = _topbarNode.get('region');
				var mainBodyWrapperHeight = vportHeight - (topbarRegion['height']);
				_mainBodyWrapperNode.setStyles({'height':mainBodyWrapperHeight});

				var _mainRegionHeightMargin = 15;
				var _mainRegionWidthMargin = 15;
				var resizeWidth = _mainBodyWrapperNode.get('region').width;
				var mainRegion = _mainBodyWrapperNode.get('region');

				var mainPanelContentNode = R8.Utils.Y.one('#main-panel-content');
				var mainPanelContentRegion = mainPanelContentNode.get('region')

				_panels['main'].resize();
			},
			advanceWizard: function() {
				switch(_currentWizardStep) {
					case 1:
						this.teardownStepOneEvents();
//TODO: need meta/semantics in import wizard for clearContentsBeforeLoad = true/false
//						R8.Utils.Y.one('#wizard-content').set('innerHTML','');
						this.loadStepTwo();
						break;
						break;
					case 2:
						this.teardownStepTwoEvents();
						R8.Utils.Y.one('#wizard-content').set('innerHTML','');
						this.loadStepThree();
						break;
					case 3:
						this.teardownStepThreeEvents();
						R8.Utils.Y.one('#wizard-content').set('innerHTML','');
						this.loadStepFour();
						break;
					case 4:
						this.teardownStepFourEvents();
						R8.Utils.Y.one('#wizard-content').set('innerHTML','');
						this.loadStepFive();
						break;
					case 5:
						this.teardownStepFiveEvents();
						this.commitImport();
						break;
				}
			},
			retreatWizard: function() {
				switch(_currentWizardStep) {
					case 1:
						break;
					case 2:
						this.teardownStepTwoEvents();
						R8.Utils.Y.one('#wizard-content').set('innerHTML','');
						this.loadStepOne();
						break;
					case 3:
						this.teardownStepThreeEvents();
						R8.Utils.Y.one('#wizard-content').set('innerHTML','');
						this.loadStepTwo();
						break;
					case 4:
						this.teardownStepFourEvents();
						R8.Utils.Y.one('#wizard-content').set('innerHTML','');
						this.loadStepThree();
						break;
					case 5:
						this.teardownStepFiveEvents();
						this.loadStepFour();
						break;
				}
			},

			setupStepOneEvents: function() {
			},
			setupStepTwoEvents: function() {
			},
			setupStepThreeEvents: function() {
			},
			setupStepFourEvents: function() {
			},
			teardownStepOneEvents: function() {
			},
			teardownStepTwoEvents: function() {
			},
			teardownStepThreeEvents: function() {
			},
			teardownStepFourEvents: function() {
			},
			loadStepOne: function() {
				var wizardContentNode = R8.Utils.Y.one('#wizard-content');
				//render the contents for Step Two
				wizardContentNode.append(R8.Rtpl['import_step_one']());

				_currentWizardStep = 1;
			},
			loadStepTwo: function() {
				R8.Utils.Y.one('#wizard-step-2').addClass('active');
				var wizardContentNode = R8.Utils.Y.one('#wizard-content');

				var _this=this;
				var callback = function(ioId,responseObj) {
					eval("var response =" + responseObj.responseText);
//TODO: change to take import object as input
//					var import_id = response.application_import_step_one.content[0].data.import_id;
					var test = response.application_import_step_one.content[0].data;
console.log(test);
return;
/*
					var tpl = R8.Rtpl.component_cfg_file_list({
						'config_file_list':cfg_file_list
					});
					R8.Utils.Y.one('#cfg-file-container').set('innerHTML',tpl);
*/
				}
				var params = {
					'cfg' : {
						method: 'POST',
						data: 'iframe_upload=1',
						form: {
							id : 'package_upload',
							upload : true
						}
					},
					'callbacks': {
						'io:complete':callback
					}
				};
				R8.Ctrl.call('import/step_one',params);

				//render the contents for Step Two
				R8.Utils.Y.one('#upload_wrapper').setStyle('display','none');
				wizardContentNode.append(R8.Rtpl['import_step_two']());

				_currentWizardStep = 2;
			},
			loadStepThree: function() {
				_stepListNode.get('children').each(function(stepNode){
					stepNode.removeClass('active');
				});
				R8.Utils.Y.one('#wizard-step-3').addClass('active');

				var wizardContentNode = R8.Utils.Y.one('#wizard-content');
				//render the contents for Step Two
				wizardContentNode.append(R8.Rtpl['import_step_three']({'component_list': _importDef.components}));

				for(var c in _importDef.components) {
					if(_importDef.components[c].selected == true) {
						document.getElementById(_importDef.components[c].def.id+'_selected').checked = true;
					}
				}

				_currentWizardStep = 3;
			},
			loadStepFour: function(compIndex) {
				R8.Utils.Y.one('#wizard-content').set('innerHTML','');

				_stepListNode.get('children').each(function(stepNode){
					stepNode.removeClass('active');
				});
				R8.Utils.Y.one('#wizard-step-4').addClass('active');

				if(typeof(_events['attr_selected']) != 'undefined') {
					_events['attr_selected'].detach();
					delete(_events['attr_selected']);
				}

				var numSelectedComponents = _importDef.selectedComponents.length;
				_sThreeCompIndex = 0;

				if(typeof(compIndex) == 'undefined') {
					compIndex = 0;
				}

				for(var sc in _importDef.selectedComponents) {
					var selectedIndex = _importDef.selectedComponents[sc];
					if (sc == compIndex) {
						var component = _importDef.components[selectedIndex];
					}
				}

				if(compIndex == 0) {
					var prevStepAction = 'R8.Import.retreatWizard();';
				} else {
					var prevStepAction = 'R8.Import.loadStepFour('+(compIndex-1)+');';
				}

				if(compIndex == (numSelectedComponents-1)) {
					var nextStepAction = 'R8.Import.advanceWizard();';
				} else {
					var nextStepAction = 'R8.Import.loadStepFour('+(compIndex+1)+');';
				}

				var wizardContentNode = R8.Utils.Y.one('#wizard-content');
				//render the contents for Step Two
				wizardContentNode.append(R8.Rtpl['import_step_four']({
					'component': component,
					'num': (compIndex+1),
					'total': numSelectedComponents,
					'num_attributes': component.def.attributes.length,
					'prev_step_action': prevStepAction,
					'next_step_action': nextStepAction
				}));

				for(var a in component.def.attributes) {
					var attr = component.def.attributes[a];
					if(typeof(attr.selected) != 'undefined' && attr.selected == true) {
						document.getElementById(attr.def.id+'_selected').checked = true;
					}
				}

				var attrListNode = R8.Utils.Y.one('#'+component.def.id+'_attr_list');
				_events['attr_selected'] = R8.Utils.Y.delegate('click',function(e) {
					var nodeId = e.currentTarget.get('id'),
						attrId = nodeId.replace('_selected','');

					R8.Import.toggleAttribute(component.def.id,attrId);
					e.stopImmediatePropagation();
				},attrListNode,'.attribute_check',this);

				if (typeof(_events['attr_click']) != 'undefined') {
					_events['attr_click'].detach();
					delete (_events['attr_click']);
				}
				var attrListNode = R8.Utils.Y.one('#'+component.def.id+'_attr_list');
				_events['attr_click'] = R8.Utils.Y.delegate('click',function(e) {
					var nodeId = e.currentTarget.get('id'),
						attrId = nodeId.replace('_item',''),
						compId = e.currentTarget.getAttribute('data-component-id');
					R8.Import.displayAttribute(compId,attrId);
				},attrListNode,'.attr_item');

				_currentWizardStep = 4;
			},
			loadStepFive: function() {
				_stepListNode.get('children').each(function(stepNode){
					stepNode.removeClass('active');
				});
				R8.Utils.Y.one('#wizard-step-5').addClass('active');

				var wizardContentNode = R8.Utils.Y.one('#wizard-content');
				var compList = [];
				for(var i in _importDef.selectedComponents) {
					compList.push(_importDef.components[_importDef.selectedComponents[i]]);
				}
				wizardContentNode.append(R8.Rtpl['import_step_five']({'component_list': compList}));

				_currentWizardStep = 5;
			},
			commitImport: function() {
				YUI().use('json', function(Y){
					var reqParam = 'import_def=' + Y.JSON.stringify(_importDef);

					var params = {
						'cfg': {
							'data': reqParam
						},
						'callbacks': {
//							'io:success':
						}
					};
					R8.Ctrl.call('import/finish/', params);
				});
			},
			displayAttribute: function(compId,attrId) {
				for(var c in _importDef.components) {
					if(compId == _importDef.components[c].def.id) {
						var compIndex = c;
					}
				}
				for(var a in _importDef.components[compIndex].def.attributes) {
					var attr = _importDef.components[compIndex].def.attributes[a];
					if(attr.def.id==attrId) {
						var attrDetailsNode = R8.Utils.Y.one('#attr_details');
						var attribute = _importDef.components[compIndex].def.attributes[a].def;
						attrDetailsNode.set('innerHTML',R8.Rtpl['import_display_attribute']({
							'attribute': attribute,
							'componentId': compId
						}));
					}
				}
			},
			updateAttribute: function(compId,attrId) {
				var form = document.getElementById(attrId+'-edit-form');

				for(var c in _importDef.components) {
					if(compId == _importDef.components[c].def.id) {
						var compIndex = c;
					}
				}
				for(var a in _importDef.components[compIndex].def.attributes) {
					var attr = _importDef.components[compIndex].def.attributes[a];
					if(attr.def.id==attrId) {
						_importDef.components[compIndex].def.attributes[a].def.label = form.label.value;
						_importDef.components[compIndex].def.attributes[a].def.description = form.description.value;
						_importDef.components[compIndex].def.attributes[a].def.default_val = form.default_val.value;
					}
				}
			},
			toggleComponent: function(componentId) {
				for(var c in _importDef.components) {
					if(_importDef.components[c].def.id == componentId) {
						if(_importDef.components[c].selected == true)
							_importDef.components[c].selected = false;
						else
							_importDef.components[c].selected = true;

						this.updateSelectedComponents();
						return;
					}
				}
			},
			updateSelectedComponents: function() {
				_importDef.selectedComponents = [];
				for(var c in _importDef.components) {
					if(_importDef.components[c].selected == true) {
						_importDef.selectedComponents.push(c);
					}
				}
			},
			toggleAttribute: function(componentId,attrId) {
				for(var c in _importDef.components) {
					if(_importDef.components[c].def.id == componentId) {
						var compIndex = c;
					}
				}

				for(var a in _importDef.components[compIndex].def.attributes) {
					var attr = _importDef.components[compIndex].def.attributes[a];
					if(attr.def.id==attrId) {
						if (typeof(attr.selected) == 'undefined' || attr.selected == false) {
							_importDef.components[compIndex].def.attributes[a].selected = true;
						} else {
							_importDef.components[compIndex].def.attributes[a].selected = false;
						}
					}
				}
				this.updateSelectedAttributes(componentId,attrId);
			},
			updateSelectedAttributes: function(componentId,attrId) {
				for(var c in _importDef.components) {
					if(_importDef.components[c].def.id == componentId) {
						var compIndex = c;
					}
				}
				_importDef.components[compIndex].selectedAttrs=[];

				for(var a in _importDef.components[compIndex].def.attributes) {
					var attr = _importDef.components[compIndex].def.attributes[a];
					if(attr.def.id==attrId) {
						if (typeof(attr.selected) == 'undefined' || attr.selected == false) {
							_importDef.components[compIndex].selectedAttrs.push(a);
						}
					}
				}
			},
			editAttribute: function(compId,attrId) {
				for(var c in _importDef.components) {
					if(compId == _importDef.components[c].def.id) {
						var compIndex = c;
					}
				}
				for(var a in _importDef.components[compIndex].def.attributes) {
					var attr = _importDef.components[compIndex].def.attributes[a];
					if(attr.def.id==attrId) {
						var attrDetailsNode = R8.Utils.Y.one('#attr_details');
						var attribute = _importDef.components[compIndex].def.attributes[a].def;

						attrDetailsNode.set('innerHTML',R8.Rtpl['import_edit_attribute']({
							'attribute': attribute,
							'componentId': compId
						}));
					}
				}
			}
		}
	}();

}