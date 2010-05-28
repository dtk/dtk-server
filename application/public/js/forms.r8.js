
if (!R8.forms) {

	/*
	 * This is the form handling r8 js class, more to be added
	 */
	R8.forms = function() {
		return {
			/*
			 * render produces the output of the form,
			 * rendering happens from LTR, Top To Bottom
			 */
			render: function(jsonArgs) {
			},

			cacheCheck: function() {
				return true;
				return false;
			},

			/*
			 * getEditForm is called when the system needs to fetch the edit action for an amp
			 *
			 * 	@param objName		The objName that getForm is being called on
			 * 	@param isNew		Wether or not the user is creating a new record or not, used to limit round trips to server
			 * 	@param jsonParms	Arbitrary Name/Value params to be passed during amp/edit call
			 * 	@param panel		Which panel to append the edit form to
			 */
			getEditForm: function(objName,isNew,panel,jsonParams) {

				//TODO: check amp and isNew in form cache, if there return

				//if form cache not there retrieve it from server
				var updateParams = {
					"amp":objName,
					"action":"edit",
					"retrieveForm":1
				};

				if (typeof(jsonParams) != 'undefined') {
					for (param in jsonParams) {
						updateParams[param] = jsonParams[param];
					}
				}

				R8.ctrl.request(updateParams, R8.forms.processForms);
			},

			/*
			 * This handles the return for the retrieval of a getForm request if retrieved from Server
			 */
			processForms: function(responseObj) {
				eval("var getFormResponse=" + responseObj.responseText);
				console.log(getFormResponse['forms']);
			},

			/*
			 * This will add a validation check for the given form/field/type
			 */
			addValidator: function(formId,validatorObj) {
				if(R8.forms.validatorExists(formId) == false) {
					R8.forms.validators[formId] = new Array(validatorObj);
				} else {
					var size = R8.forms.validators[formId].length;
					R8.forms.validators[formId][size] = validatorObj;
				}
			},

			/*
			 * Checks to see if the forms validator list has been created yet
			 */
			validatorExists: function(formId) {
				if(R8.utils.isDefined(R8.forms.validators[formId]))
					return true;
				else
					return false;
/*
				var numValidators = R8.forms.validators.length;
				for(var i=0; i < numValidators; i++) {
					if(R8.forms.validators[i]['form'] === formId)
						return true;
				}
				return false;
*/
			},

			/*
			 * This is used to track which js scripts have been added to the page so redundant adds dont happen
			 */
			validators : {},

			/*
			 * Check for validated form and if successful submit to server for processing
			 */
			submit: function(formId) {
				var formValid = R8.forms.formValidated(formId);

				if(formValid)
					R8.ctrl.submitForm(formId, false);
			},

			/*
			 * This will iterate over all the validators for a form and return true/false
			 */
			formValidated : function(formId) {
				if(R8.utils.isDefined(R8.forms.validators[formId])) {
					var numValidators = R8.forms.validators[formId].length, validForm = true;
				} else
					return true;

				//more efficient method forlooping with potentially longer lists,
				//let the loop countdown to 0, work your way down the list from last to first
				for(var i=numValidators; i--;) {
					var validator = R8.forms.validators[formId][i];

					switch(validator["type"]) {
						case "text":
							if(!R8.fields.validateText(validator))
								validForm = false;
							break;
						case "integer":
							if(!R8.fields.validateInteger(validator))
								validForm = false;
							break;
						case "percentage":
						case "float":
							if(!R8.fields.validateFloat(validator))
								validForm = false;
							break;
						case "select":
							if(!R8.fields.validateSelect(validator))
								validForm = false;
							break;
						case "multiselect":
							if(!R8.fields.validateMultiSelect(validator))
								validForm = false;
							break;
						case "calendar":
							if(!R8.fields.validateCalendar(validator))
								validForm = false;
							break;
						case "radio":
							if(!R8.fields.validateRadio(validator))
								validForm = false;
							break;
						case "checkbox":
							if(!R8.fields.validateCheckbox(validator))
								validForm = false;
							break;
					}

				}
				return validForm;
			}
		}
	}();
}
