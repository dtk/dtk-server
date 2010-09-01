
if (!R8.Fields) {

	/*
	 * This is the field handling r8 js class, more to be added
	 */
	R8.Fields = function() {
		return {
			registerCal: function(fieldId, btnId, calId) {
				var dialog,calendar;
				var calBtn = document.getElementById(btnId);

				YAHOO.util.Event.on(calBtn, "click", function() {
					if (!dialog) {
						// Hide Calendar if we click anywhere in the document other than the calendar
						YAHOO.util.Event.on(document, "click", function(e) {
							var el = YAHOO.util.Event.getTarget(e);
							var dialogEl = dialog.element;
							if (el != dialogEl && !YAHOO.util.Dom.isAncestor(dialogEl, el) && el != calBtn && !YAHOO.util.Dom.isAncestor(calBtn, el)) {
								dialog.hide();
							}
						});

						function resetHandler() {
							// Reset the current calendar page to the select date, or 
							// to today if nothing is selected.
							var selDates = calendar.getSelectedDates();
							var resetDate;

							if (selDates.length > 0) {
								resetDate = selDates[0];
							} else {
								resetDate = calendar.today;
							}
							calendar.cfg.setProperty("pagedate", resetDate);
							calendar.render();
						}

						function closeHandler() {
							dialog.hide();
						}

						dialog = new YAHOO.widget.Dialog("container", {
							visible:false,
							context:[btnId, "tl", "bl"],
							draggable:false,
							close:false
						});

						dialog.setBody('<div id="'+calId+'"></div>');
						dialog.render(document.body);

						dialog.showEvent.subscribe(function() {
							if (YAHOO.env.ua.ie) {
								// Since we're hiding the table using yui-overlay-hidden, we 
								// want to let the dialog know that the content size has changed, when
								// shown
								dialog.fireEvent("changeContent");
							}
						});
					}

		            // Lazy Calendar Creation - Wait to create the Calendar until the first time the button is clicked.
		            if (!calendar) {
		                calendar = new YAHOO.widget.Calendar(calId, {
		                    iframe:false,          // Turn iframe off, since container has iframe support.
		                    hide_blank_weeks:true  // Enable, to demonstrate how we handle changing height, using changeContent
		                });
		                calendar.render();

		                calendar.selectEvent.subscribe(function() {
		                    if (calendar.getSelectedDates().length > 0) {
		                        var selDate = calendar.getSelectedDates()[0];
//TODO: work on date formatting
//should pull from config.dateFormat
/*		                        // Pretty Date Output, using Calendar's Locale values: Friday, 8 February 2008
		                        var wStr = calendar.cfg.getProperty("WEEKDAYS_LONG")[selDate.getDay()];
		                        var dStr = selDate.getDate();
		                        var mStr = calendar.cfg.getProperty("MONTHS_LONG")[selDate.getMonth()];
		                        var yStr = selDate.getFullYear();
		                        YAHOO.util.Dom.get(fieldId).value = wStr + ", " + dStr + " " + mStr + " " + yStr;
*/
//TODO: revisit when moving calendar into own field class or implementing new date formats
								switch(R8.config['dateDisplayFormat']) {
									case "MM/dd/yy":
										var day = selDate.getDay();
										if(day < 10) day = '0' + day;
										var month = selDate.getMonth();
										if(month < 10) month = '0' + month;
										var yr = selDate.getFullYear();
										if(yr > 2000) yr = yr - 2000;
										if(yr < 10) yr = '0' + yr;
										var displayStr = month + "/" + day + "/" + yr;
										break;
								}
		                        document.getElementById(fieldId).value = displayStr;
		                    } else {
		                        YAHOO.util.Dom.get(fieldId).value = "";
		                    }
		                    dialog.hide();
		                });

		                calendar.renderEvent.subscribe(function() {
		                    // Tell Dialog it's contents have changed, which allows 
		                    // container to redraw the underlay (for IE6/Safari2)
		                    dialog.fireEvent("changeContent");
		                });
		            }
					var seldate = calendar.getSelectedDates();
		            if (seldate.length > 0) {
		                // Set the pagedate to show the selected date if it exists
		                calendar.cfg.setProperty("pagedate", seldate[0]);
		                calendar.render();
		            }
		            dialog.show();
				});
			},

			regCalClear: function() {
				// Hide Calendar if we click anywhere in the document other than the calendar
				YAHOO.util.Event.on(document, "click", function(e) {
					var el = YAHOO.util.Event.getTarget(e);
					var dialogEl = dialog.element;
					if (el != dialogEl && !YAHOO.util.Dom.isAncestor(dialogEl, el) && el != showBtn && !YAHOO.util.Dom.isAncestor(showBtn, el)) {
						dialog.hide();
					}
				});
			},

			/*
			 * getEditForm is called when the system needs to fetch the edit action for an amp
			 *
			 * 	@param amp			The amp that getForm is being called on
			 * 	@param isNew		Wether or not the user is creating a new record or not, used to limit round trips to server
			 * 	@param jsonParms	Arbitrary Name/Value params to be passed during amp/edit call
			 * 	@param panel		Which panel to append the edit form to
			 */
			getEditForm: function(amp,isNew,panel,jsonParams) {

				//TODO: check amp and isNew in form cache, if there return

				//if form cache not there retrieve it from server
				var updateParams = {
					"amp":amp,
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
			 * This is used to track a list of active calendar fields on the screen
			 * Will be used to free up objects after page changes and clearing
			 */
//TODO: rework this to be an object instead of array,
//also *** make sure to clean up activeCals after a forms submission, delete them
			activeCals : new Array(),

			/*
			 * BEGIN FIELD VALIDATORS
			 * Should move these out probably, make them "pluggable"/overridable
			 */
			validateText : function(validator) {
				var fieldValid = true;

				fieldValid = R8.Fields.validateBase(validator);
				if(fieldValid) {
					if(R8.Utils.isDefined(validator["maxLength"])) {
						//nothing here yet
					}
				}
				return fieldValid;
			},
			validateInteger : function(validator) {
				var fieldValid = true;

				fieldValid = R8.Fields.validateBase(validator);
				if(fieldValid) {
					if(!R8.Utils.isInteger(document.getElementById(validator["id"]).value)) {
						fieldValid = false;
						//TODO: i18N
						validator["errorMsg"] = "Must be a whole number";
					}
					if(fieldValid) R8.Fields.clearFieldErrors(validator);
					else R8.Fields.addFieldErrors(validator);

					return fieldValid;
				}
				return fieldValid;
			},
			validateFloat : function(validator) {
				var fieldValid = true;

				fieldValid = R8.Fields.validateBase(validator);
				if(fieldValid) {
					if(!R8.Utils.isFloat(document.getElementById(validator["id"]).value)) {
						fieldValid = false;
						//TODO: i18N
						validator["errorMsg"] = "Must be a whole or decimal number";
					}
					if(fieldValid) R8.Fields.clearFieldErrors(validator);
					else R8.Fields.addFieldErrors(validator);

					return fieldValid;
				}
				return fieldValid;
			},
			validateSelect : function(validator) {
				var fieldValid = true;

				if(validator["required"]) {
					var elem = document.getElementById(validator["id"]);

					if(elem.options[elem.selectedIndex].value === '') {
						fieldValid = false;
						//TODO: i18N
						validator["errorMsg"] = "Must have a value";
					}
				}
				if(fieldValid) R8.Fields.clearFieldErrors(validator);
				else R8.Fields.addFieldErrors(validator);

				return fieldValid;
			},
			validateMultiSelect : function(validator) {
				var fieldValid = true;

				if(validator["required"]) {
					var elem = document.getElementById(validator["id"]),
						hasNoValue = true,
						numOptions = elem.options.length;

					for(var i=numOptions; i--;) {
						if(elem.options[i].selected == true && elem.options[i].value != '')
							hasNoValue = false;
					}
					if(hasNoValue) {
						fieldValid = false;
						//TODO: i18N
						validator["errorMsg"] = "Must have a value";
					}
				}
				if(fieldValid) R8.Fields.clearFieldErrors(validator);
				else R8.Fields.addFieldErrors(validator);

				return fieldValid;
			},
			validateCalendar : function(validator) {
				var fieldValid = true;

				fieldValid = R8.Fields.validateBase(validator);

				return fieldValid;
			},
			validateRadio : function(validator) {
				var fieldValid = true;

				if(validator["required"]) {
					var elemList = document.getElementsByName(validator["id"]),
						valSelected = false,
						numOptions = elemList.length;

					for(var i=numOptions; i--;) {
						if (elemList[i].checked == true) {
							valSelected = true;
							i = 0;
						}
					}
					if(!valSelected) {
						fieldValid = false;
						//TODO: i18N
						validator["errorMsg"] = "Must have a value";
					}
				}
				if(fieldValid) R8.Fields.clearFieldErrors(validator);
				else R8.Fields.addFieldErrors(validator);

				return fieldValid;
			},
			validateCheckbox : function(validator) {
				var fieldValid = true;

				//nothing to do here yet
				return fieldValid;
			},
			validateBase : function(validator) {
				var fieldValid = true;
				if(validator["required"]) {
					var elem = document.getElementById(validator["id"]);
					if(elem.value === '') fieldValid = false;
					//TODO: i18N
					validator["errorMsg"] = "Must have a value";
				}
				if(fieldValid) R8.Fields.clearFieldErrors(validator);
				else R8.Fields.addFieldErrors(validator);

				return fieldValid;
			},

			clearFieldErrors : function(validator) {
				if(R8.Utils.isDefined(validator["classRefId"]))
					var inputElem = document.getElementById(validator["classRefId"]);
				else
					var inputElem = document.getElementById(validator["id"]);

				var parentElem = inputElem.parentNode;
//TODO: revisit after a while, can generalize parent type, could be td or div depending on form TPL on server
				var errDivId = validator["id"]+"-vErr-div", errDiv = document.getElementById(errDivId);
				if (parentElem.tagName.toLowerCase() === 'td') {
					if(errDiv != null) {
						parentElem.removeChild(errDiv);
//TODO: abstract out YAHOO usage to wrapper func/class
						YAHOO.util.Dom.removeClass(inputElem, "validation-error");
					}
				} else {
					alert("TEMP ERROR: Parent shouldnt be something other then td");
				}
			},
//TODO: LOOK up about using displey none/block and reflow from velocity

			addFieldErrors : function(validator) {
				if(R8.Utils.isDefined(validator["classRefId"]))
					var inputElem = document.getElementById(validator["classRefId"]);
				else
					var inputElem = document.getElementById(validator["id"]);

//TODO: abstract out YAHOO usage to wrapper func/class
				YAHOO.util.Dom.addClass(inputElem, "validation-error");

				var errDivId = validator["id"]+"-vErr-div", errDiv = document.getElementById(errDivId);
				//find container parent element for input and addValidationError to screen
				var parentElem = inputElem.parentNode;

				if(errDiv != null) parentElem.removeChild(errDiv);

//TODO: revisit after a while, can generalize parent type, could be td or div depending on form TPL on server
				if (parentElem.tagName.toLowerCase() === 'td') {
					var errDiv = document.createElement("div");
					errDiv.id = validator["id"] + "-vErr-div";
//TODO: abstract out YAHOO usage to wrapper func/class
					YAHOO.util.Dom.addClass(errDiv, "vErrDiv");
//TODO: revisit to implement string handling
					errDiv.innerHTML = validator['id'] + " : " + validator['errorMsg'];
					parentElem.appendChild(errDiv);
				}
				else {
					alert("TEMP ERROR: Parent shouldnt be something other then td");
				}
			},

			addValidationError : function(node, validator) {
			}
		}
	}();
}