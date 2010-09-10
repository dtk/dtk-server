
if (!R8.Utils) {

	/*
	 * This is the utility r8 js class, more to be added
	 */
	R8.Utils = function(){
		return {

			/*
			 * This is the global YUI variable to be used
			 */
//			Y : new YUI({base:'js/yui3x/build/'}).use('dd', 'node'),
			Y : new YUI().use('dd', 'node'),

			/*
			 * This is the global jQuery variable to be used
			 */
			$ : jQuery,

			/*
			 * This function takes a name/value pair json object and return a name=value&name2=value2 string
			 * 
			 * @param jsonVar	A one dimensional json Object currently expected
			 */
			json2Str: function(jsonVar) {
				var returnStr = '';
				var firstPass = false;

				for(name in jsonVar) {
					if(firstPass == true) returnStr += "&";
					returnStr += name+"="+jsonVar[name];
					firstPass = true;
				}
				return returnStr;
			},

			/*
			 * Wrapper function to YUI().Lang.trim function
			 */
			trim: function(inputVar) {
				return YUI().Lang.trim(inputVar);
			},

			/*
			 * Wrapper function to YUI().Lang.isUndefined
			 */
			isUndefined: function(inputVar) {
				return YUI().Lang.isUndefined(inputVar);
			},

			/*
			 * Wrapper function to invers YUI().Lang.isUndefined
			 */
			isDefined: function(inputVar) {
				return !YUI().Lang.isUndefined(inputVar);
			},

			/*
			 * Wrapper function to YUI().Lang.isValue
			 */
			isValue: function(inputVar) {
				return YUI().Lang.isValue(inputVar);
			},

			/*
			 */
			isInteger: function(inputVal) {
				if(inputVal == '') inputVal = 0;
				for (var i = 0; i < inputVal.length; i++) {
					var digit = inputVal.charAt(i);
//TODO: revisit to check for number seperator from config instead of hardcoding
					if(digit == ",") continue;
					if (!R8.Utils.isDigit(digit)) return false;
				}
				return true;
			},

			/*
			 */
			isFloat: function(inputVal) {
				if(inputVal == '') inputVal = 0;
				for (var i = 0; i < inputVal.length; i++) {
					var digit = inputVal.charAt(i);
//TODO: revisit to check for number seperator from config instead of hardcoding
					if(digit == "," || digit == ".") continue;
					if (!R8.Utils.isDigit(digit)) return false;
				}
				return true;
			},

			/*
			 */
			isDigit : function(digit) {
				return ((digit >= "0") && (digit <= "9"));
			},

			/*
			 * Wrapper function to YUI().Lang.isString
			 */
			isString: function(inputVar) {
				return YUI().Lang.isString(inputVar);
			},

			/*
			 * Wrapper function to YUI().Lang.later
			 * 
			 * @param time			Execution time in milliseconds
			 * @param obj			Object context to call func from
			 * @param func			Function to call
			 * @param inputData		Single Var or array, 
			 * @param repeatExec	Repeat execution at time interval continuously
			 * 
			 * @return Returns Variable that can be used to .cancel() execution
			 */
			schedule: function(time, obj, func, inputData, repeatExec) {
				return YUI().Lang.later(time, obj, func, inputData, repeatExec);
			},
		}
	}();

}