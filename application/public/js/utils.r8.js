
if(typeof R8=="undefined" || !R8) {
	var R8={};
}

if (!R8.utils) {

	/*
	 * This is the utility r8 js class, more to be added
	 */
	R8.utils = function(){
		return {

			//this is a temp place holder until figuring things out to build routing string
			coreActions : {'as':1,'list':1,'display':1,'edit':1,'import':1,'export':1},

			/*
			 * This function takes a name/value pair json object and return a name=value&name2=value2 string
			 * 
			 * @param jsonVar	A one dimensional json Object currently expected
			 */
			json2Str: function(jsonVar) {
				var returnStr = '';
				var firstPass = false;

				for(name in jsonVar) {
					if(typeof(R8.utils.coreActions[name]) != 'undefined') continue;

					if(firstPass == true) returnStr += "&";
					returnStr += name+"="+jsonVar[name];
					firstPass = true;
				}
				return returnStr;
			},

			/*
			 * Wrapper function to YUI YAHOO.lang.trim function
			 */
			trim: function(inputVar) {
				return YAHOO.lang.trim(inputVar);
			},

			/*
			 * Wrapper function to YUI YAHOO.lang.isUndefined
			 */
			isUndefined: function(inputVar) {
				return YAHOO.lang.isUndefined(inputVar);
			},

			/*
			 * Wrapper function to invers YUI YAHOO.lang.isUndefined
			 */
			isDefined: function(inputVar) {
				return !YAHOO.lang.isUndefined(inputVar);
			},

			/*
			 * Wrapper function to YUI YAHOO.lang.isValue
			 */
			isValue: function(inputVar) {
				return YAHOO.lang.isValue(inputVar);
			},

			/*
			 */
			isInteger: function(inputVal) {
				if(inputVal == '') inputVal = 0;
				for (var i = 0; i < inputVal.length; i++) {
					var digit = inputVal.charAt(i);
//TODO: revisit to check for number seperator from config instead of hardcoding
					if(digit == ",") continue;
					if (!R8.utils.isDigit(digit)) return false;
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
					if (!R8.utils.isDigit(digit)) return false;
				}
				return true;
			},

			/*
			 */
			isDigit : function(digit) {
				return ((digit >= "0") && (digit <= "9"));
			},

			/*
			 * Wrapper function to YUI YAHOO.lang.isString
			 */
			isString: function(inputVar) {
				return YAHOO.lang.isString(inputVar);
			},

			/*
			 * Wrapper function to YUI YAHOO.lang.later
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
				return YAHOO.lang.later(time, obj, func, inputData, repeatExec);
			},
		}
	}();

}